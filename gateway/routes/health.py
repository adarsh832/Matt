from fastapi import APIRouter

try:
    from gateway.services.gateway_core import gateway_core
    from gateway.config import APP_VERSION
except ImportError:
    from services.gateway_core import gateway_core
    from config import APP_VERSION

router = APIRouter(prefix="")

@router.get("/health")
async def get_health() -> dict:
    """Health check endpoint. Returns gateway and LM Studio connection status."""
    return {
        "status": "ok",
        "lmstudio": gateway_core.is_connected,
        "version": APP_VERSION,
        "gateway": True
    }
