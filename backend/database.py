import logging
import asyncio
import uuid
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

# Basic SQLAlchemy pool settings
engine_args = {
    "echo": False,
    "pool_size": 10,       # Reduced to prevent overwhelming the pooler
    "max_overflow": 5,     # Reduced max burst
    "pool_pre_ping": True, # Keep connection health checks
    "connect_args": {
        # Supavisor/PgBouncer Transaction mode doesn't support session-level prepared statements
        "prepared_statement_cache_size": 0,
        "statement_cache_size": 0,
        "prepared_statement_name_func": lambda *args: f"__asyncpg_{uuid.uuid4().hex}__",
    }
}

if "localhost" not in database_url:
    # Use 'require' mode for asyncpg to work with Supabase poolers
    engine_args["connect_args"]["ssl"] = "require"

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
            
            # Auto-seed if empty
            try:
                from sqlalchemy import select, func
                from models import Poll
                from seed_data import SEED_POLLS
                
                async with async_session() as db:
                    print("🔍 Checking if database needs seeding...")
                    count_result = await db.execute(select(func.count()).select_from(Poll))
                    count = count_result.scalar() or 0
                    
                    if count == 0:
                        print(f"🌱 Database is empty. Seeding {len(SEED_POLLS)} IPL polls...")
                        for poll_data in SEED_POLLS:
                            db.add(Poll(**poll_data))
                        await db.commit()
                        print(f"✅ Seeding complete! Total polls: {len(SEED_POLLS)}")
                    else:
                        print(f"ℹ️  Database already has {count} polls. Seeding skipped.")
            except Exception as seed_err:
                print(f"⚠️  Auto-seed error: {seed_err}")
                import traceback
                traceback.print_exc()

            print("✅ Database connected and schema verified.")
            return
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            
            # Specific hint for Railway + Supabase IPv6 issue
            if "101" in str(e) or "Network is unreachable" in str(e):
                print("💡 HINT: 'Network is unreachable' often means the database is IPv6-only.")
                print("💡 ACTION: Go to Supabase -> Settings -> Database -> Connection Pooling.")
                print("💡 FIX: Use the 'Transaction' mode connection string (usually port 6543).")
            
            # Specific hint for Supabase Pooler authentication issue
            if "password authentication failed" in str(e).lower():
                print("💡 HINT: 'password authentication failed' with Port 6543 usually means the username is wrong.")
                print("💡 ACTION: When using the Pooler, the username MUST be 'postgres.[YOUR-PROJECT-REF]'.")
                print("💡 FIX: Copy the exact 'Connection string' from Supabase Pooling settings.")
            
            if attempt < max_retries:
                print(f"🔄 Retrying in {retry_delay}s...")
                await asyncio.sleep(retry_delay)
                retry_delay *= 2  # Exponential backoff
            else:
                print("💥 Max retries reached. Database is unavailable.")
                raise e
