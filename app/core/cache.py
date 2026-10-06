from __future__ import annotations

import json
import logging
import uuid
from contextlib import contextmanager
from functools import lru_cache
from typing import Any, Iterator

from app.core.config import get_settings

logger = logging.getLogger(__name__)


@lru_cache()
def get_redis_client():
    """Return a Redis client when enabled; otherwise return None.

    Redis is intentionally optional so the app keeps the same behavior on local
    machines or servers where Redis is not installed/running.
    """

    settings = get_settings()
    if not settings.redis_enabled:
        return None
    try:
        import redis

        client = redis.Redis.from_url(
            settings.redis_url,
            decode_responses=True,
            socket_connect_timeout=0.4,
            socket_timeout=0.8,
        )
        client.ping()
        return client
    except Exception as exc:  # noqa: BLE001
        logger.warning("Redis unavailable; continuing without cache: %s", exc)
        return None


def cache_get_json(key: str) -> Any | None:
    client = get_redis_client()
    if not client:
        return None
    try:
        value = client.get(key)
        if value is None:
            return None
        return json.loads(value)
    except Exception as exc:  # noqa: BLE001
        logger.debug("Redis cache read failed for %s: %s", key, exc)
        return None


def cache_set_json(key: str, value: Any, ttl_seconds: int | None = None) -> None:
    client = get_redis_client()
    if not client:
        return
    ttl = ttl_seconds or get_settings().cache_default_ttl_seconds
    try:
        client.setex(key, ttl, json.dumps(value, default=str))
    except Exception as exc:  # noqa: BLE001
        logger.debug("Redis cache write failed for %s: %s", key, exc)


def cache_delete_pattern(pattern: str) -> None:
    client = get_redis_client()
    if not client:
        return
    try:
        for key in client.scan_iter(match=pattern, count=100):
            client.delete(key)
    except Exception as exc:  # noqa: BLE001
        logger.debug("Redis cache delete failed for %s: %s", pattern, exc)


@contextmanager
def redis_lock(name: str, ttl_seconds: int | None = None) -> Iterator[bool]:
    """Best-effort distributed lock.

    Yields True when the caller owns the lock. If Redis is disabled/unavailable,
    yields True so existing single-process behavior is preserved.
    """

    client = get_redis_client()
    if not client:
        yield True
        return

    settings = get_settings()
    key = f"lock:{name}"
    token = str(uuid.uuid4())
    ttl = ttl_seconds or settings.scheduler_lock_ttl_seconds
    acquired = False
    try:
        acquired = bool(client.set(key, token, nx=True, ex=ttl))
        yield acquired
    except Exception as exc:  # noqa: BLE001
        logger.debug("Redis lock failed for %s; running without lock: %s", name, exc)
        yield True
    finally:
        if acquired:
            try:
                release_script = """
                if redis.call("get", KEYS[1]) == ARGV[1] then
                    return redis.call("del", KEYS[1])
                end
                return 0
                """
                client.eval(release_script, 1, key, token)
            except Exception as exc:  # noqa: BLE001
                logger.debug("Redis lock release failed for %s: %s", name, exc)
