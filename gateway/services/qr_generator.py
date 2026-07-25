import io
import json
from typing import Dict, Any

import qrcode
import qrcode.constants
from qrcode.image.pil import PilImage

try:
    from gateway.utils.logger import get_logger
except ImportError:
    from utils.logger import get_logger

logger = get_logger("qr_generator")


def generate_qr_png(data: Dict[str, Any]) -> bytes:
    """
    Creates a QR code as PNG bytes in memory containing the JSON string of the given data.
    """
    try:
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_M,
            box_size=10,
            border=4,
        )
        json_data = json.dumps(data)
        qr.add_data(json_data)
        qr.make(fit=True)

        img = qr.make_image(fill_color="black", back_color="white", image_factory=PilImage)
        buf = io.BytesIO()
        img.save(buf, format="PNG")
        return buf.getvalue()
    except Exception as e:
        logger.error(f"Failed to generate QR PNG: {e}")
        raise


def generate_qr_ascii(data: Dict[str, Any]) -> str:
    """Creates an ASCII art QR code for terminal display containing the JSON string of the given data."""
    try:
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_M,
            box_size=1,
            border=2,
        )
        json_data = json.dumps(data)
        qr.add_data(json_data)
        qr.make(fit=True)
        
        matrix = qr.get_matrix()
        lines = []
        for row in matrix:
            line = ""
            for cell in row:
                line += "##" if cell else "  "
            lines.append(line)
        return "\n".join(lines)
    except Exception as e:
        logger.error(f"Failed to generate ASCII QR: {e}")
        raise
