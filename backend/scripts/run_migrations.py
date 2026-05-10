from __future__ import annotations

import asyncio
from pathlib import Path
import sys

import aiomysql

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from app.config import settings
from app.migrations import run_migrations


async def main() -> None:
    pool = await aiomysql.create_pool(
        host=settings.mysql_host,
        port=settings.mysql_port,
        user=settings.mysql_user,
        password=settings.mysql_password,
        db=settings.mysql_database,
        minsize=1,
        maxsize=2,
        autocommit=False,
    )

    try:
        migrations_dir = PROJECT_ROOT / "migrations"
        await run_migrations(pool, migrations_dir)
    finally:
        pool.close()
        await pool.wait_closed()


if __name__ == "__main__":
    asyncio.run(main())
