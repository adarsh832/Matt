from typing import List, Dict
from fastapi import APIRouter, HTTPException, Depends

try:
    from gateway.services.model_manager import model_manager
    from gateway.services.gateway_core import gateway_core
    from gateway.routes.chat import verify_device_token
    from gateway.utils.http_client import get_client
except ImportError:
    from services.model_manager import model_manager
    from services.gateway_core import gateway_core
    from routes.chat import verify_device_token
    from utils.http_client import get_client

router = APIRouter(prefix="")

@router.get("/models")
async def get_models() -> List[Dict[str, str]]:
    """
    Get available models from LM Studio and Cloud Providers.
    """
    if not gateway_core.is_connected:
        raise HTTPException(status_code=503, detail="LM Studio is disconnected")
        
    models = await model_manager.get_models()
    return models

@router.post("/models/{model_id:path}/load")
async def load_model(model_id: str, token: str = Depends(verify_device_token)) -> dict:
    """
    Force LM Studio to load a model by sending a dummy request.
    This will block until the model is fully loaded into VRAM.
    """
    # Cloud models don't need loading
    if model_id.startswith(("gpt-", "claude-", "gemini/")):
        return {"success": True, "model": model_id, "note": "Cloud model requires no loading"}
        
    if not gateway_core.is_connected:
        raise HTTPException(status_code=503, detail="LM Studio is disconnected")
        
    client = get_client()
    
    payload = {
        "model": model_id,
        "messages": [{"role": "user", "content": "ping"}],
        "max_tokens": 1
    }
    
    try:
        await client.post("/v1/chat/completions", json=payload)
        return {"success": True, "model": model_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
