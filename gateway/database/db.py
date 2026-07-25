import os
from pathlib import Path
from typing import Optional, List, Dict, Any, Tuple, Union
import aiosqlite
from contextlib import asynccontextmanager

try:
    from gateway.config import DB_PATH
except ImportError:
    from config import DB_PATH

SCHEMA_PATH = Path(__file__).parent / "schema.sql"

async def init_db() -> None:
    """
    Initialize the database by creating the file if it does not exist,
    running the schema script, and enabling necessary pragmas like WAL mode
    and foreign key constraints.
    """
    # Ensure database directory exists
    db_path_obj = Path(DB_PATH)
    db_path_obj.parent.mkdir(parents=True, exist_ok=True)
    
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("PRAGMA journal_mode = WAL;")
        await db.execute("PRAGMA foreign_keys = ON;")
        
        with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
            schema_content = f.read()
            
        await db.executescript(schema_content)
        await db.commit()

@asynccontextmanager
async def get_db():
    """
    Async context manager for yielding an aiosqlite database connection.
    Enables foreign keys and sets row_factory to aiosqlite.Row.
    """
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        await db.execute("PRAGMA foreign_keys = ON;")
        yield db

async def execute(query: str, params: Union[Tuple, Dict[str, Any]] = ()) -> Optional[int]:
    """
    Execute a modification query (INSERT, UPDATE, DELETE) and return the last inserted row id.
    """
    async with get_db() as db:
        cursor = await db.execute(query, params)
        await db.commit()
        return cursor.lastrowid

async def fetch_one(query: str, params: Union[Tuple, Dict[str, Any]] = ()) -> Optional[Dict[str, Any]]:
    """
    Execute a SELECT query and fetch a single row as a dictionary.
    """
    async with get_db() as db:
        cursor = await db.execute(query, params)
        row = await cursor.fetchone()
        if row:
            return dict(row)
        return None

async def fetch_all(query: str, params: Union[Tuple, Dict[str, Any]] = ()) -> List[Dict[str, Any]]:
    """
    Execute a SELECT query and fetch all matching rows as a list of dictionaries.
    """
    async with get_db() as db:
        cursor = await db.execute(query, params)
        rows = await cursor.fetchall()
        return [dict(row) for row in rows]
