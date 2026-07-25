import socket
import secrets
import uuid
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional

try:
    from gateway.database.db import fetch_one, fetch_all, execute
    from gateway.utils.logger import get_logger
    from gateway.config import GATEWAY_PORT, DEVICE_NAME
except ImportError:
    from database.db import fetch_one, fetch_all, execute
    from utils.logger import get_logger
    from config import GATEWAY_PORT, DEVICE_NAME

logger = get_logger("pairing_manager")

def _get_lan_ip() -> str:
    """Auto-detect LAN IP using a UDP socket connection."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return '127.0.0.1'

class PairingManager:
    """Manages device pairing and active chatter state."""
    def __init__(self) -> None:
        self.current_token: str = self.generate_pairing_token()
        self.active_chatter_token: Optional[str] = None
        
    def generate_pairing_token(self) -> str:
        """Generate a new URL-safe pairing token."""
        return secrets.token_urlsafe(32)

    def get_pairing_payload(self) -> Dict[str, str]:
        """Get the payload for QR code generation and pairing."""
        lan_ip = _get_lan_ip()
        return {
            "server": f"http://{lan_ip}:{GATEWAY_PORT}",
            "device_name": DEVICE_NAME,
            "pairing_token": self.current_token
        }

    def validate_token(self, token: str) -> bool:
        """Check if the provided token matches the current active token."""
        return secrets.compare_digest(self.current_token, token)

    async def register_device(self, device_name: str, token: str) -> Dict[str, Any]:
        """
        Validate pairing token, register device in database, and return status.
        Regenerates the pairing token after successful registration.
        """
        if not self.validate_token(token):
            return {"success": False, "error": "Invalid pairing token"}
        
        device_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        
        try:
            await execute(
                "INSERT INTO devices (id, device_name, pairing_token, paired_at, last_seen, is_active) VALUES (?, ?, ?, ?, ?, ?)",
                (device_id, device_name, token, now, now, 1)
            )
            # Cycle token immediately so next device gets a new one (to avoid UNIQUE constraint error)
            self.current_token = self.generate_pairing_token()
            return {"success": True, "device_id": device_id}
        except Exception as e:
            logger.error(f"Failed to register device: {e}")
            return {"success": False, "error": str(e)}

    async def validate_device_token(self, token: str) -> bool:
        """Check if the token belongs to a registered and active device."""
        row = await fetch_one("SELECT id FROM devices WHERE id = ? AND is_active = 1", (token,))
        return bool(row)

    async def get_paired_devices(self) -> List[Dict[str, Any]]:
        """List all paired devices from the database."""
        return await fetch_all("SELECT * FROM devices")

    async def update_last_seen(self, token: str) -> None:
        """Update the last_seen timestamp for a given device token."""
        now = datetime.now(timezone.utc).isoformat()
        await execute("UPDATE devices SET last_seen = ? WHERE id = ?", (now, token))

    def is_active_chatter(self, token: str) -> bool:
        """Check if this device is the current active chatter."""
        return self.active_chatter_token == token

    def claim_active(self, token: str) -> None:
        """Set this device as the active chatter."""
        self.active_chatter_token = token

pairing_manager = PairingManager()
