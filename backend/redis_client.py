import redis.asyncio as redis
from config import get_settings

settings = get_settings()

redis_client: redis.Redis = None


async def init_redis():
    global redis_client
    redis_client = redis.from_url(
        settings.REDIS_URL,
        encoding="utf-8",
        decode_responses=True,
        socket_connect_timeout=5,
        retry_on_timeout=True,
    )
    try:
        await redis_client.ping()
        print("✅ Redis connected")
    except Exception as e:
        print(f"⚠️ Redis connection failed: {e}. Running without cache.")
        redis_client = None


async def close_redis():
    global redis_client
    if redis_client:
        await redis_client.close()


def get_redis() -> redis.Redis:
    return redis_client


# ── Vote Counter Helpers ──

async def increment_vote(poll_id: str, vote: str) -> None:
    """Increment vote counter in Redis."""
    if not redis_client:
        return
    key = f"poll:{poll_id}:{vote}"
    await redis_client.incr(key)
    # Also update total
    await redis_client.incr(f"poll:{poll_id}:total")


async def get_vote_counts(poll_id: str) -> dict:
    """Get cached vote counts for a poll."""
    if not redis_client:
        return None
    pipe = redis_client.pipeline()
    pipe.get(f"poll:{poll_id}:a")
    pipe.get(f"poll:{poll_id}:b")
    pipe.get(f"poll:{poll_id}:total")
    results = await pipe.execute()
    
    votes_a = int(results[0] or 0)
    votes_b = int(results[1] or 0)
    total = int(results[2] or 0)
    
    if total == 0:
        return None  # Cache miss, need to load from DB
    
    return {"votes_a": votes_a, "votes_b": votes_b, "total": total}


async def sync_poll_to_redis(poll_id: str, votes_a: int, votes_b: int) -> None:
    """Sync DB vote counts to Redis."""
    if not redis_client:
        return
    pipe = redis_client.pipeline()
    pipe.set(f"poll:{poll_id}:a", votes_a)
    pipe.set(f"poll:{poll_id}:b", votes_b)
    pipe.set(f"poll:{poll_id}:total", votes_a + votes_b)
    await pipe.execute()


async def invalidate_poll_cache(poll_id: str) -> None:
    """Remove poll from cache."""
    if not redis_client:
        return
    pipe = redis_client.pipeline()
    pipe.delete(f"poll:{poll_id}:a")
    pipe.delete(f"poll:{poll_id}:b")
    pipe.delete(f"poll:{poll_id}:total")
    await pipe.execute()
