from __future__ import annotations

import time
from dataclasses import dataclass
from typing import Generic, TypeVar

T = TypeVar("T")


@dataclass
class _CacheEntry(Generic[T]):
    value: T
    expires_at: float


class TtlCache(Generic[T]):
    def __init__(self, ttl_seconds: int, max_entries: int = 256) -> None:
        self._ttl_seconds = ttl_seconds
        self._max_entries = max_entries
        self._entries: dict[str, _CacheEntry[T]] = {}

    def get(self, key: str) -> T | None:
        entry = self._entries.get(key)
        if entry is None:
            return None

        if entry.expires_at <= time.monotonic():
            self._entries.pop(key, None)
            return None

        return entry.value

    def set(self, key: str, value: T) -> None:
        self._prune_expired()
        if len(self._entries) >= self._max_entries:
            oldest_key = next(iter(self._entries), None)
            if oldest_key is not None:
                self._entries.pop(oldest_key, None)

        self._entries[key] = _CacheEntry(
            value=value,
            expires_at=time.monotonic() + self._ttl_seconds,
        )

    def _prune_expired(self) -> None:
        now = time.monotonic()
        expired_keys = [
            key for key, entry in self._entries.items() if entry.expires_at <= now
        ]
        for key in expired_keys:
            self._entries.pop(key, None)
