"""
Run all migrations in order.
Usage: python scripts/migrate.py
"""
import asyncio
import os
import asyncpg
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

MIGRATIONS_DIR = Path(__file__).parent.parent / "migrations"


async def run_migrations():
    dsn = os.getenv("DATABASE_URL")
    if not dsn:
        raise ValueError("DATABASE_URL not set in .env")

    conn = await asyncpg.connect(dsn=dsn)

    try:
        # Create tracking table if it does not exist
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS _migrations (
                filename   TEXT PRIMARY KEY,
                applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            )
        """)

        applied = {
            row["filename"]
            for row in await conn.fetch("SELECT filename FROM _migrations")
        }

        migration_files = sorted(MIGRATIONS_DIR.glob("*.sql"))

        for migration_file in migration_files:
            if migration_file.name in applied:
                print(f"  skipped  {migration_file.name}")
                continue

            sql = migration_file.read_text()
            await conn.execute(sql)
            await conn.execute(
                "INSERT INTO _migrations (filename) VALUES ($1)",
                migration_file.name,
            )
            print(f"  applied  {migration_file.name}")

        print("\nAll migrations complete.")

    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(run_migrations())
