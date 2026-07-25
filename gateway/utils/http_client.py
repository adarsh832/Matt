import httpx
from typing import Optional, AsyncGenerator, Any, Dict
try:
    from gateway.config import LMSTUDIO_BASE_URL
    from gateway.utils.logger import get_logger
except ImportError:
    from config import LMSTUDIO_BASE_URL
    from utils.logger import get_logger

logger = get_logger(__name__)

class HttpClient:
    """Singleton HTTP client for communicating with LM Studio."""
    
    _instance: Optional["HttpClient"] = None
    _client: Optional[httpx.AsyncClient] = None
    
    def __new__(cls) -> "HttpClient":
        if cls._instance is None:
            cls._instance = super(HttpClient, cls).__new__(cls)
        return cls._instance
    
    def __init__(self) -> None:
        pass
        
    async def init(self) -> None:
        """Initialize the async HTTP client."""
        if self._client is None:
            timeout = httpx.Timeout(connect=5.0, read=120.0, write=5.0, pool=5.0)
            self._client = httpx.AsyncClient(
                base_url=LMSTUDIO_BASE_URL,
                timeout=timeout,
                limits=httpx.Limits(max_keepalive_connections=20, max_connections=100)
            )
            logger.info("Initialized HttpClient for LM Studio")

    async def close(self) -> None:
        """Close the async HTTP client."""
        if self._client is not None:
            await self._client.aclose()
            self._client = None
            logger.info("Closed HttpClient")
            
    def _get_client(self) -> httpx.AsyncClient:
        """Helper to get client or raise error if not initialized."""
        if self._client is None:
            raise RuntimeError("HttpClient is not initialized. Call init() first.")
        return self._client
            
    async def get(self, path: str) -> httpx.Response:
        """
        Send a GET request.
        
        Args:
            path (str): The endpoint path relative to the base URL
            
        Returns:
            httpx.Response: The HTTP response
        """
        client = self._get_client()
        try:
            response = await client.get(path)
            response.raise_for_status()
            return response
        except httpx.HTTPError as e:
            logger.error(f"HTTP GET error to {path}: {str(e)}")
            raise
            
    async def post(self, path: str, json: Dict[str, Any]) -> httpx.Response:
        """
        Send a POST request with JSON payload.
        
        Args:
            path (str): The endpoint path relative to the base URL
            json (Dict[str, Any]): The JSON payload
            
        Returns:
            httpx.Response: The HTTP response
        """
        client = self._get_client()
        try:
            response = await client.post(path, json=json)
            response.raise_for_status()
            return response
        except httpx.HTTPError as e:
            logger.error(f"HTTP POST error to {path}: {str(e)}")
            raise
            
    async def stream_post(self, path: str, json: Dict[str, Any]) -> AsyncGenerator[str, None]:
        """
        Send a POST request and stream the response.
        
        Args:
            path (str): The endpoint path relative to the base URL
            json (Dict[str, Any]): The JSON payload
            
        Yields:
            str: Chunks of the response stream
        """
        client = self._get_client()
        try:
            async with client.stream("POST", path, json=json) as response:
                response.raise_for_status()
                async for chunk in response.aiter_lines():
                    if chunk:
                        yield chunk
        except httpx.HTTPError as e:
            logger.error(f"HTTP stream POST error to {path}: {str(e)}")
            raise

# Module level functions for the singleton
_http_client: Optional[HttpClient] = None

def get_client() -> HttpClient:
    """Get the singleton HttpClient instance."""
    global _http_client
    if _http_client is None:
        _http_client = HttpClient()
    return _http_client

async def close_client() -> None:
    """Close the singleton HttpClient instance."""
    global _http_client
    if _http_client is not None:
        await _http_client.close()
