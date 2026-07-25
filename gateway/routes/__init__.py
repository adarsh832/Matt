try:
    from gateway.routes.health import router as health_router
    from gateway.routes.models import router as models_router
    from gateway.routes.pair import router as pair_router
    from gateway.routes.chat import router as chat_router
except ImportError:
    from routes.health import router as health_router
    from routes.models import router as models_router
    from routes.pair import router as pair_router
    from routes.chat import router as chat_router

__all__ = ["health_router", "models_router", "pair_router", "chat_router"]
