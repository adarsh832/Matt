import time
from typing import List, Dict, Optional

try:
    from gateway.utils.http_client import get_client
    from gateway.utils.logger import get_logger
    from gateway.services.gateway_core import gateway_core
    from gateway.config import MODEL_CACHE_TTL
except ImportError:
    from utils.http_client import get_client
    from utils.logger import get_logger
    from services.gateway_core import gateway_core
    from config import MODEL_CACHE_TTL

logger = get_logger(__name__)

class ModelManager:
    """Manages model fetching and caching from LM Studio."""
    
    def __init__(self) -> None:
        self._cache: List[Dict[str, str]] = []
        self._cache_time: float = 0.0

    async def fetch_models(self) -> List[Dict[str, str]]:
        """Calls LM Studio /v1/models, parses OpenAI-format response, and extracts model info."""
        if not gateway_core.is_connected:
            logger.warning("Gateway is not connected to LM Studio. Returning empty model list.")
            return []

        try:
            client = get_client()
            response = await client.get("/v1/models")
            data = response.json()
            
            models = data.get("data", [])
            mapped_models: List[Dict[str, str]] = []
            
            for model in models:
                model_id = model.get("id")
                if not model_id:
                    continue
                    
                model_name = str(model_id).replace('-', ' ').replace('_', ' ').title()
                
                mapped_models.append({
                    "id": str(model_id),
                    "name": model_name
                })
            
            return mapped_models
        except Exception as e:
            logger.error(f"Failed to fetch models from LM Studio: {e}")
            return []

    async def get_models(self) -> List[Dict[str, str]]:
        """Returns cached list of models, refreshes if stale."""
        current_time = time.time()
        
        if not self._cache or (current_time - self._cache_time) > float(MODEL_CACHE_TTL):
            logger.info("Model cache is stale or empty. Refreshing models.")
            fetched = await self.fetch_models()
            
            if fetched or gateway_core.is_connected:
                self._cache = fetched
                self._cache_time = current_time
                
        return self._cache

    async def get_model_by_id(self, model_id: str) -> Optional[Dict[str, str]]:
        """Looks up a single model by its ID."""
        models = await self.get_models()
        for model in models:
            if model["id"] == model_id:
                return model
                
        return None

model_manager = ModelManager()
