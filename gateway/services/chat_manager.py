"""Chat manager service."""

import json
import uuid
from datetime import datetime, timezone
from typing import AsyncGenerator, Dict, Any, List, Optional

try:
    from gateway.database.db import fetch_one, fetch_all, execute
    from gateway.utils.http_client import get_client
    from gateway.utils.logger import get_logger
    from gateway.config import MAX_CONTEXT_MESSAGES
except ImportError:
    from database.db import fetch_one, fetch_all, execute
    from utils.http_client import get_client
    from utils.logger import get_logger
    from config import MAX_CONTEXT_MESSAGES

logger = get_logger("chat_manager")

PERSONALITY_PROMPTS = {
    "coding_partner": "You are Maat, an expert coding partner. You write clean, efficient code, debug issues methodically, and explain technical concepts clearly. You provide code examples with proper syntax highlighting and follow best practices for the language being discussed.",
    "creative_writer": "You are Maat, a creative writing assistant. You craft engaging stories, vivid poetry, and compelling creative content. You have a rich vocabulary, understand narrative structure, and can adapt your style to match the user's creative vision.",
    "study_buddy": "You are Maat, a patient and encouraging study buddy. You explain complex concepts in simple terms, use analogies to aid understanding, and help break down problems into manageable steps. You quiz the user and celebrate their progress."
}

class ChatManager:
    """Manages conversations, messages, and streaming completions."""
    
    def __init__(self):
        self.active_streams: Dict[str, bool] = {}

    async def create_conversation(self, model: str, personality: str, title: Optional[str] = None) -> Dict[str, Any]:
        """Creates a new conversation in the database."""
        conv_id = str(uuid.uuid4())
        if not title:
            title = "New Conversation"
        now = datetime.now(timezone.utc).isoformat()
        
        await execute(
            """
            INSERT INTO conversations (id, title, model, personality, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (conv_id, title, model, personality, now, now)
        )
        return {
            "id": conv_id,
            "title": title,
            "model": model,
            "personality": personality,
            "created_at": now,
            "updated_at": now
        }

    async def get_conversations(self) -> List[Dict[str, Any]]:
        """Returns all conversations ordered by updated_at DESC."""
        rows = await fetch_all("SELECT * FROM conversations ORDER BY updated_at DESC")
        return [dict(row) for row in rows]

    async def get_conversation(self, conversation_id: str) -> Optional[Dict[str, Any]]:
        """Returns a conversation with all messages."""
        conv = await fetch_one("SELECT * FROM conversations WHERE id = ?", (conversation_id,))
        if not conv:
            return None
        
        messages = await self.get_messages(conversation_id, limit=1000)
        conv_dict = dict(conv)
        conv_dict["messages"] = messages
        return conv_dict

    async def rename_conversation(self, conversation_id: str, title: str) -> bool:
        """Renames a conversation."""
        now = datetime.now(timezone.utc).isoformat()
        try:
            await execute(
                "UPDATE conversations SET title = ?, updated_at = ? WHERE id = ?",
                (title, now, conversation_id)
            )
            return True
        except Exception as e:
            logger.error(f"Error renaming conversation: {e}")
            return False

    async def delete_conversation(self, conversation_id: str) -> bool:
        """Deletes a conversation and its messages."""
        try:
            await execute("DELETE FROM messages WHERE conversation_id = ?", (conversation_id,))
            await execute("DELETE FROM conversations WHERE id = ?", (conversation_id,))
            return True
        except Exception as e:
            logger.error(f"Error deleting conversation: {e}")
            return False

    async def add_message(self, conversation_id: str, role: str, content: str, model: Optional[str] = None) -> str:
        """Inserts a message and updates the conversation's updated_at timestamp."""
        msg_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        
        await execute(
            """
            INSERT INTO messages (id, conversation_id, role, content, model, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (msg_id, conversation_id, role, content, model, now)
        )
        
        await execute(
            "UPDATE conversations SET updated_at = ? WHERE id = ?",
            (now, conversation_id)
        )
        
        return msg_id

    async def get_messages(self, conversation_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Returns the last N messages ordered by created_at ASC."""
        rows = await fetch_all(
            """
            SELECT * FROM messages 
            WHERE conversation_id = ? 
            ORDER BY created_at DESC 
            LIMIT ?
            """,
            (conversation_id, limit)
        )
        return [dict(row) for row in reversed(rows)]

    async def delete_last_assistant_message(self, conversation_id: str) -> bool:
        """Removes the last assistant message from a conversation."""
        try:
            last_msg = await fetch_one(
                """
                SELECT id FROM messages 
                WHERE conversation_id = ? AND role = 'assistant' 
                ORDER BY created_at DESC 
                LIMIT 1
                """,
                (conversation_id,)
            )
            if last_msg:
                await execute("DELETE FROM messages WHERE id = ?", (last_msg["id"],))
                return True
            return False
        except Exception as e:
            logger.error(f"Error deleting last assistant message: {e}")
            return False

    async def stream_completion(
        self, 
        conversation_id: Optional[str], 
        message: str, 
        model: str, 
        personality: str = "coding_partner",
        is_retry: bool = False
    ) -> AsyncGenerator[Dict[str, Any], None]:
        """Streams completion from LM Studio. Yields dict events (not pre-formatted SSE strings)."""
        if not conversation_id:
            title = message[:50] + ("..." if len(message) > 50 else "")
            conv = await self.create_conversation(model=model, personality=personality, title=title)
            conversation_id = conv["id"]
        else:
            conv = await fetch_one("SELECT * FROM conversations WHERE id = ?", (conversation_id,))
            if not conv:
                yield {"type": "error", "message": "Conversation not found"}
                return
            
            # Update the conversation with the newly requested model and personality
            await execute(
                "UPDATE conversations SET model = ?, personality = ? WHERE id = ?",
                (model, personality, conversation_id)
            )

        self.active_streams[conversation_id] = False

        yield {"type": "start", "conversation_id": conversation_id}

        if not is_retry:
            await self.add_message(conversation_id, "user", message)

        lm_messages = []
        if personality.startswith("custom:"):
            custom_data = personality[7:]
            if "|" in custom_data:
                system_prompt = custom_data.split("|", 1)[1]
            else:
                system_prompt = custom_data
        else:
            system_prompt = PERSONALITY_PROMPTS.get(personality, PERSONALITY_PROMPTS["coding_partner"])
            
        lm_messages.append({"role": "system", "content": system_prompt})
        
        history = await self.get_messages(conversation_id, limit=MAX_CONTEXT_MESSAGES)
        for msg in history:
            lm_messages.append({"role": msg["role"], "content": msg["content"]})
            
        payload = {
            "model": model,
            "messages": lm_messages,
            "stream": True,
        }

        full_content = ""
        is_cloud = model.startswith(("gpt-", "claude-", "gemini/"))

        try:
            if is_cloud:
                import litellm
                try:
                    from gateway import config
                except ImportError:
                    import config
                
                response = await litellm.acompletion(
                    model=model,
                    messages=lm_messages,
                    stream=True
                )
                
                async for chunk in response:
                    if self.active_streams.get(conversation_id, False):
                        logger.info(f"Stream cancelled for conversation {conversation_id}")
                        yield {"type": "error", "message": "Generation stopped"}
                        break
                        
                    content = chunk.choices[0].delta.content or ""
                    if content:
                        full_content += content
                        yield {"type": "chunk", "content": content}
                        
            else:
                client = get_client()
                async for line in client.stream_post("/v1/chat/completions", json=payload):
                    if self.active_streams.get(conversation_id, False):
                        logger.info(f"Stream cancelled for conversation {conversation_id}")
                        yield {"type": "error", "message": "Generation stopped"}
                        break
    
                    line = line.strip()
                    if not line:
                        continue
                        
                    if line.startswith("data: "):
                        data_str = line[6:]
                        if data_str.strip() == "[DONE]":
                            break
                        try:
                            data_json = json.loads(data_str)
                            choices = data_json.get("choices", [])
                            if choices:
                                delta = choices[0].get("delta", {})
                                content = delta.get("content", "")
                                if content:
                                    full_content += content
                                    yield {"type": "chunk", "content": content}
                        except json.JSONDecodeError:
                            logger.warning(f"Failed to parse SSE data: {data_str}")
                            continue
                            
            if full_content:
                await self.add_message(conversation_id, "assistant", full_content, model=model)
                yield {"type": "done", "full_content": full_content}
                
        except Exception as e:
            logger.error(f"Error during stream completion: {e}")
            yield {"type": "error", "message": str(e)}
        finally:
            if conversation_id in self.active_streams:
                del self.active_streams[conversation_id]

    async def stop_generation(self, conversation_id: str) -> bool:
        """Cancels active stream for a conversation."""
        if conversation_id in self.active_streams:
            self.active_streams[conversation_id] = True
            return True
        return False

    async def retry_last(self, conversation_id: str) -> AsyncGenerator[Dict[str, Any], None]:
        """Retries the last user message."""
        conv = await fetch_one("SELECT * FROM conversations WHERE id = ?", (conversation_id,))
        if not conv:
            yield {"type": "error", "message": "Conversation not found"}
            return
            
        await self.delete_last_assistant_message(conversation_id)
        
        last_msg = await fetch_one(
            """
            SELECT content FROM messages 
            WHERE conversation_id = ? AND role = 'user' 
            ORDER BY created_at DESC 
            LIMIT 1
            """,
            (conversation_id,)
        )
        
        if not last_msg:
            yield {"type": "error", "message": "No user message found to retry"}
            return
            
        message = dict(last_msg)["content"]
        model = dict(conv)["model"]
        personality = dict(conv)["personality"]
        
        async for chunk in self.stream_completion(
            conversation_id=conversation_id,
            message=message,
            model=model,
            personality=personality,
            is_retry=True
        ):
            yield chunk

chat_manager = ChatManager()
