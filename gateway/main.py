"""Maat Gateway — Main entry point."""

import sys
import argparse
import asyncio
from pathlib import Path
from contextlib import asynccontextmanager

# Add gateway directory to path for imports
sys.path.insert(0, str(Path(__file__).resolve().parent))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from config import GATEWAY_HOST, GATEWAY_PORT, LMSTUDIO_BASE_URL, APP_VERSION, DEVICE_NAME
from utils.logger import get_logger
from utils.http_client import get_client, close_client
from database.db import init_db
from services.gateway_core import gateway_core
from services.model_manager import model_manager
from services.pairing_manager import pairing_manager
from services.qr_generator import generate_qr_ascii
from routes.health import router as health_router
from routes.models import router as models_router
from routes.pair import router as pair_router
from routes.chat import router as chat_router

logger = get_logger("main")


def print_banner(host: str, port: int, lm_connected: bool, model_count: int) -> None:
    """Print the startup banner to the console."""
    lm_status = "Connected" if lm_connected else "Not Reachable (retrying...)"
    lm_icon = "[OK]" if lm_connected else "[..]"
    
    banner = f"""
======================================
       Maat Gateway v{APP_VERSION}
======================================

  [OK] Gateway Running on {host}:{port}
  {lm_icon} LM Studio: {lm_status}
  [>>] Models Found: {model_count}
  [PC] Device Name: {DEVICE_NAME}

======================================"""
    print(banner)


def print_qr_section() -> None:
    """Print the QR code section for pairing."""
    payload = pairing_manager.get_pairing_payload()
    qr_ascii = generate_qr_ascii(payload)
    
    print("\n[QR] Scan QR Code to pair your mobile device:\n")
    print(qr_ascii)
    print(f"   Server: {payload['server']}")
    print(f"   Or visit: {payload['server']}/pair/qr")
    print(f"\n[..] Waiting for mobile device...\n")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """FastAPI lifespan handler for startup and shutdown."""
    # Startup
    logger.info("Initializing Maat Gateway...")
    
    # Initialize database
    await init_db()
    logger.info("Database initialized.")
    
    # Initialize HTTP client
    client = get_client()
    await client.init()
    logger.info("HTTP client initialized.")
    
    # Start gateway core (LM Studio detection + retry loop)
    await gateway_core.startup()
    
    # Fetch models if connected
    model_count = 0
    if gateway_core.is_connected:
        models = await model_manager.get_models()
        model_count = len(models)
    
    # Print startup banner
    print_banner(GATEWAY_HOST, GATEWAY_PORT, gateway_core.is_connected, model_count)
    
    # Print QR code for pairing
    print_qr_section()
    
    yield
    
    # Shutdown
    logger.info("Shutting down Maat Gateway...")
    await gateway_core.shutdown()
    await close_client()
    logger.info("Maat Gateway shut down.")


# Create FastAPI app
app = FastAPI(
    title="Maat Gateway",
    version=APP_VERSION,
    description="Local LLM Mobile Companion Gateway",
    lifespan=lifespan
)

# CORS middleware — allow all origins (LAN-only, security via pairing token)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(health_router)
app.include_router(models_router)
app.include_router(pair_router)
app.include_router(chat_router)


def main() -> None:
    """CLI entry point with argument parsing."""
    parser = argparse.ArgumentParser(description="Maat Gateway — Local LLM Mobile Companion")
    parser.add_argument(
        "--port", 
        type=int, 
        default=GATEWAY_PORT,
        help=f"Port to run the gateway on (default: {GATEWAY_PORT})"
    )
    parser.add_argument(
        "--host",
        type=str,
        default=GATEWAY_HOST,
        help=f"Host to bind to (default: {GATEWAY_HOST})"
    )
    parser.add_argument(
        "--lmstudio-url",
        type=str,
        default=LMSTUDIO_BASE_URL,
        help=f"LM Studio API URL (default: {LMSTUDIO_BASE_URL})"
    )
    
    args = parser.parse_args()
    
    # Override config with CLI args
    import config
    config.GATEWAY_PORT = args.port
    config.GATEWAY_HOST = args.host
    config.LMSTUDIO_BASE_URL = args.lmstudio_url
    
    uvicorn.run(
        "main:app",
        host=args.host,
        port=args.port,
        reload=False,
        log_level="info"
    )


if __name__ == "__main__":
    main()
