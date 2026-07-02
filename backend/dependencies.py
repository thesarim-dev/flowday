import asyncpg
from fastapi import Depends
from database import get_pool


async def get_connection(
    pool: asyncpg.Pool = Depends(get_pool),
) -> asyncpg.Connection:
    async with pool.acquire() as connection:
        yield connection
