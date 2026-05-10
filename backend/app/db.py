from __future__ import annotations

from pathlib import Path

import aiomysql

from app.config import Settings
from app.migrations import run_migrations


class Database:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._pool: aiomysql.Pool | None = None

    async def connect(self) -> None:
        if self._pool is not None:
            return

        await self._ensure_database_exists()
        self._pool = await aiomysql.create_pool(
            host=self._settings.mysql_host,
            port=self._settings.mysql_port,
            user=self._settings.mysql_user,
            password=self._settings.mysql_password,
            db=self._settings.mysql_database,
            minsize=1,
            maxsize=10,
            autocommit=True,
        )
        migrations_dir = Path(__file__).resolve().parents[1] / "migrations"
        await run_migrations(self._pool, migrations_dir)

    async def disconnect(self) -> None:
        if self._pool is None:
            return

        self._pool.close()
        await self._pool.wait_closed()
        self._pool = None

    @property
    def pool(self) -> aiomysql.Pool:
        if self._pool is None:
            raise RuntimeError("Database pool has not been initialized.")
        return self._pool

    async def _ensure_database_exists(self) -> None:
        connection = await aiomysql.connect(
            host=self._settings.mysql_host,
            port=self._settings.mysql_port,
            user=self._settings.mysql_user,
            password=self._settings.mysql_password,
            autocommit=True,
        )

        try:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    f"""
                    CREATE DATABASE IF NOT EXISTS `{self._settings.mysql_database}`
                    CHARACTER SET utf8mb4
                    COLLATE utf8mb4_unicode_ci
                    """
                )
        finally:
            connection.close()
