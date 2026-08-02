import asyncio
from typing import Dict, Optional, Any

try:
    from gateway.utils.http_client import get_client
    from gateway.utils.logger import get_logger
    from gateway.config import LMSTUDIO_RETRY_INTERVAL, LMSTUDIO_BASE_URL
except ImportError:
    from utils.http_client import get_client
    from utils.logger import get_logger
    from config import LMSTUDIO_RETRY_INTERVAL, LMSTUDIO_BASE_URL

logger = get_logger(__name__)

class GatewayCore:
    """Manages the connection to LM Studio and gateway lifecycle."""
    
    def __init__(self) -> None:
        self.is_connected: bool = False
        self._retry_task: Optional[asyncio.Task[Any]] = None
        self._shutdown: bool = False

    async def detect_lmstudio(self) -> bool:
        """Tries GET to LM Studio /v1/models endpoint to detect if it's running."""
        try:
            client = get_client()
            response = await client.get("/v1/models")
            return True
        except Exception:
            return False

    async def _retry_loop(self) -> None:
        """Background task that retries connection every LMSTUDIO_RETRY_INTERVAL seconds."""
        while not self._shutdown:
            connected = await self.detect_lmstudio()
            
            if connected and not self.is_connected:
                logger.info("Connection to LM Studio established.")
                self.is_connected = True
            elif not connected and self.is_connected:
                logger.warning("Connection to LM Studio lost.")
                self.is_connected = False
            
            try:
                # Sleep in small chunks to allow quick shutdown
                for _ in range(int(float(LMSTUDIO_RETRY_INTERVAL) * 10)):
                    if self._shutdown:
                        break
                    await asyncio.sleep(0.1)
            except asyncio.CancelledError:
                break

    async def startup(self) -> None:
        """Initialize and start the background retry loop."""
        logger.info("Starting GatewayCore lifecycle.")
        self._shutdown = False
        
        self.is_connected = await self.detect_lmstudio()
        if self.is_connected:
            logger.info("Connection to LM Studio established on startup.")
        else:
            logger.warning("LM Studio not reachable on startup. Will retry in background.")

        self._retry_task = asyncio.create_task(self._retry_loop())

    async def shutdown(self) -> None:
        """Signal background task to stop and wait for it."""
        logger.info("Shutting down GatewayCore lifecycle.")
        self._shutdown = True
        
        if self._retry_task:
            try:
                await self._retry_task
            except asyncio.CancelledError:
                pass
            except Exception as e:
                logger.error(f"Error during shutdown of retry loop: {e}")
            finally:
                self._retry_task = None

    def get_status(self) -> Dict[str, Any]:
        """Returns the current status of the gateway and LM Studio connection."""
        return {
            "gateway": True,
            "lmstudio": self.is_connected,
            "lmstudio_url": LMSTUDIO_BASE_URL
        }

gateway_core = GatewayCore()
