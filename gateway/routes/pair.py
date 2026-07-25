from fastapi import APIRouter, HTTPException, Response
from pydantic import BaseModel

try:
    from gateway.services.pairing_manager import pairing_manager
    from gateway.services.qr_generator import generate_qr_png
except ImportError:
    from services.pairing_manager import pairing_manager
    from services.qr_generator import generate_qr_png

router = APIRouter(prefix="/pair")

class PairRequest(BaseModel):
    device_name: str
    pairing_token: str

@router.get("/qr")
async def get_qr_code() -> Response:
    """Returns a PNG image of the QR code for pairing."""
    payload = pairing_manager.get_pairing_payload()
    png_data = generate_qr_png(payload)
    return Response(content=png_data, media_type="image/png")

@router.get("/info")
async def get_pairing_info() -> dict:
    """Returns the JSON pairing payload."""
    return pairing_manager.get_pairing_payload()

@router.post("")
async def pair_device(request: PairRequest) -> dict:
    """Registers a new device using the pairing token."""
    result = await pairing_manager.register_device(request.device_name, request.pairing_token)
    if not result.get("success"):
        raise HTTPException(status_code=401, detail=result.get("error", "Invalid pairing token"))
        
    return result
