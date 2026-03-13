import logging
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)

# Use SSL for Supabase (production)
engine_args = {
    "echo": False,
    "pool_size": 20,
    "max_overflow": 10,
    "pool_pre_ping": True,
}

if "localhost" not in settings.DATABASE_URL:
    # asyncpg uses 'ssl' parameter for SSL
    engine_args["connect_args"] = {"ssl": True}

engine = create_async_engine(settings.DATABASE_URL, **engine_args)

async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncSession:
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    max_retries = 5
    retry_delay = 2
    
    for attempt in range(1, max_retries + 1):
        try:
            print(f"📡 Connecting to database... (Attempt {attempt}/{max_retries})")
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            print("✅ Database connected and schema verified.")
            return
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            if attempt < max_retries:
                print(f"🔄 Retrying in {retry_delay}s...")
                await asyncio.sleep(retry_delay)
                retry_delay *= 2  # Exponential backoff
            else:
                print("💥 Max retries reached. Database is unavailable.")
                raise e
