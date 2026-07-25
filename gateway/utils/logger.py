import logging
import sys
from datetime import datetime

# ANSI escape codes for colors
COLORS = {
    "DEBUG": "\033[36m",    # Cyan
    "INFO": "\033[32m",     # Green
    "WARNING": "\033[33m",  # Yellow
    "ERROR": "\033[31m",    # Red
    "CRITICAL": "\033[1;31m", # Bold Red
    "RESET": "\033[0m"
}

class ColoredFormatter(logging.Formatter):
    """Custom formatter with colors and structured output."""

    def format(self, record: logging.LogRecord) -> str:
        color = COLORS.get(record.levelname, COLORS["RESET"])
        reset = COLORS["RESET"]
        
        time_str = datetime.fromtimestamp(record.created).strftime("%H:%M:%S")
        level_name = f"{color}{record.levelname}{reset}"
        
        return f"[{time_str}] {level_name} {record.module}: {record.getMessage()}"

def get_logger(name: str) -> logging.Logger:
    """
    Returns a configured logger with the specified name.
    
    Args:
        name (str): The name of the logger, typically __name__
        
    Returns:
        logging.Logger: Configured logger instance
    """
    logger = logging.getLogger(name)
    
    # Avoid adding handlers multiple times
    if not logger.handlers:
        logger.setLevel(logging.INFO)
        
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(ColoredFormatter())
        
        logger.addHandler(console_handler)
        
    return logger
