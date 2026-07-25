import os
import socket
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Base paths
BASE_DIR = Path(__file__).resolve().parent
DATABASE_DIR = BASE_DIR / "database"

# Gateway Configuration
GATEWAY_HOST = os.getenv("GATEWAY_HOST", "0.0.0.0")
GATEWAY_PORT = int(os.getenv("GATEWAY_PORT", "8080"))

# LM Studio Configuration
LMSTUDIO_BASE_URL = os.getenv("LMSTUDIO_BASE_URL", "http://localhost:1234")
LMSTUDIO_RETRY_INTERVAL = int(os.getenv("LMSTUDIO_RETRY_INTERVAL", "10"))

# Database Configuration
DB_PATH = Path(os.getenv("DB_PATH", DATABASE_DIR / "maat.db"))

# Application Configuration
MAX_CONTEXT_MESSAGES = int(os.getenv("MAX_CONTEXT_MESSAGES", "50"))
MODEL_CACHE_TTL = int(os.getenv("MODEL_CACHE_TTL", "30"))
APP_VERSION = os.getenv("APP_VERSION", "0.1.0")

# Device Information
try:
    default_device = socket.gethostname()
except Exception:
    default_device = "unknown-device"

DEVICE_NAME = os.getenv("DEVICE_NAME", default_device)
