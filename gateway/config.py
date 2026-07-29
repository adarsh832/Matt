import os
import socket
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Base paths
BASE_DIR = Path(__file__).resolve().parent
DATABASE_DIR = BASE_DIR / "database"
ENV_PATH = BASE_DIR / ".env"

def save_env_var(key: str, value: str) -> None:
    """Save an environment variable to the .env file and update the current process."""
    os.environ[key] = value
    
    env_vars = {}
    if ENV_PATH.exists():
        with open(ENV_PATH, "r") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    env_vars[k.strip()] = v.strip()
                    
    env_vars[key] = value
    
    with open(ENV_PATH, "w") as f:
        for k, v in env_vars.items():
            f.write(f"{k}={v}\n")

# Gateway Configuration
GATEWAY_HOST = os.getenv("GATEWAY_HOST", "0.0.0.0")
GATEWAY_PORT = int(os.getenv("GATEWAY_PORT", "8080"))

# LM Studio Configuration
LMSTUDIO_BASE_URL = os.getenv("LMSTUDIO_BASE_URL", "http://localhost:1234")
LMSTUDIO_RETRY_INTERVAL = int(os.getenv("LMSTUDIO_RETRY_INTERVAL", "10"))

# Database Configuration
DB_PATH = Path(os.getenv("DB_PATH", DATABASE_DIR / "maat.db"))

# Cloud LLM Configuration
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_MODELS = os.getenv("OPENAI_MODELS", "gpt-4o,gpt-3.5-turbo")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_MODELS = os.getenv("GEMINI_MODELS", "gemini/gemini-1.5-pro,gemini/gemini-1.5-flash")

ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY", "")
ANTHROPIC_MODELS = os.getenv("ANTHROPIC_MODELS", "claude-3-5-sonnet-20240620,claude-3-haiku-20240307")

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
