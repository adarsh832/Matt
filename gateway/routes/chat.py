import json
from typing import Optional, AsyncGenerator
from fastapi import APIRouter, HTTPException, Depends, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

try:
    from gateway.services.pairing_manager import pairing_manager
    from gateway.services.chat_manager import chat_manager
except ImportError:
    from services.pairing_manager import pairing_manager
    from services.chat_manager import chat_manager

router = APIRouter(prefix="")

async def verify_device_token(request: Request) -> str:
    """
    Extracts X-Device-Token from headers, validates it, and updates last seen.
    Raises 401 if invalid or missing.
    """
    token = request.headers.get("X-Device-Token")
    if not token:
        raise HTTPException(status_code=401, detail="X-Device-Token header is missing")
    
    if not await pairing_manager.validate_device_token(token):
        raise HTTPException(status_code=401, detail="Invalid device token")
        
    await pairing_manager.update_last_seen(token)
    return token

class ChatRequest(BaseModel):
    conversation_id: Optional[str] = None
    model: str
    message: str
    personality: str = "coding_partner"

class RetryRequest(BaseModel):
    conversation_id: str

class StopRequest(BaseModel):
    conversation_id: str

class RenameRequest(BaseModel):
    title: str

@router.post("/chat")
async def chat(request: ChatRequest, token: str = Depends(verify_device_token)) -> StreamingResponse:
    """Stream a chat completion."""
    pairing_manager.claim_active(token)
    
    async def event_generator() -> AsyncGenerator[str, None]:
        async for event in chat_manager.stream_completion(
            request.conversation_id, request.message, request.model, request.personality
        ):
            yield f"data: {json.dumps(event)}\n\n"
            
    return StreamingResponse(event_generator(), media_type="text/event-stream")

@router.post("/chat/retry")
async def chat_retry(request: RetryRequest, token: str = Depends(verify_device_token)) -> StreamingResponse:
    """Retry the last message in a conversation."""
    pairing_manager.claim_active(token)
    
    async def event_generator() -> AsyncGenerator[str, None]:
        async for event in chat_manager.retry_last(request.conversation_id):
            yield f"data: {json.dumps(event)}\n\n"
            
    return StreamingResponse(event_generator(), media_type="text/event-stream")

@router.post("/chat/stop")
async def chat_stop(request: StopRequest, token: str = Depends(verify_device_token)) -> dict:
    """Stop generation for a conversation."""
    await chat_manager.stop_generation(request.conversation_id)
    return {"stopped": True}

@router.get("/conversations")
async def get_conversations(token: str = Depends(verify_device_token)) -> list:
    """Get all conversations."""
    return await chat_manager.get_conversations()

@router.get("/conversations/{conversation_id}")
async def get_conversation(conversation_id: str, token: str = Depends(verify_device_token)) -> dict:
    """Get a specific conversation by ID."""
    conversation = await chat_manager.get_conversation(conversation_id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return conversation

@router.put("/conversations/{conversation_id}")
async def rename_conversation(conversation_id: str, request: RenameRequest, token: str = Depends(verify_device_token)) -> dict:
    """Rename a conversation."""
    await chat_manager.rename_conversation(conversation_id, request.title)
    return {"success": True}

@router.delete("/conversations/{conversation_id}")
async def delete_conversation(conversation_id: str, token: str = Depends(verify_device_token)) -> dict:
    """Delete a conversation."""
    await chat_manager.delete_conversation(conversation_id)
    return {"success": True}
