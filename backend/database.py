import logging
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)

# Fix possible 'postgres://' or 'postgresql://' to 'postgresql+asyncpg://'
database_url = settings.DATABASE_URL
if database_url.startswith("postgres://"):
    database_url = database_url.replace("postgres://", "postgresql+asyncpg://", 1)
elif database_url.startswith("postgresql://") and "+asyncpg" not in database_url:
    database_url = database_url.replace("postgresql://", "postgresql+asyncpg://", 1)

# Mask sensitive info for logging
db_host = database_url.split("@")[-1].split("/")[0] if "@" in database_url else "localhost"

# Use SSL for Supabase (production)
engine_args = {
    "echo": False,
    "pool_size": 20,
    "max_overflow": 10,
    "pool_pre_ping": True,
}

if "localhost" not in database_url:
    # Use 'require' mode for asyncpg to work with Supabase poolers without strictly verifying the CA chain
    engine_args["connect_args"] = {"ssl": "require"}

print(f"🛠️  Engine initialized for host: {db_host}")
engine = create_async_engine(database_url, **engine_args)

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
            print(f"📡 Connecting to database ({db_host})... (Attempt {attempt}/{max_retries})")
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            print("✅ Database connected and schema verified.")
            return
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            
            # Specific hint for Railway + Supabase IPv6 issue
            if "101" in str(e) or "Network is unreachable" in str(e):
                print("💡 HINT: 'Network is unreachable' often means the database is IPv6-only.")
                print("💡 ACTION: Go to Supabase -> Settings -> Database -> Connection Pooling.")
                print("💡 FIX: Use the 'Transaction' mode connection string (usually port 6543).")
            
            if attempt < max_retries:
                print(f"🔄 Retrying in {retry_delay}s...")
                await asyncio.sleep(retry_delay)
                retry_delay *= 2  # Exponential backoff
            else:
                print("💥 Max retries reached. Database is unavailable.")
                raise e
