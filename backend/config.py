from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


import os

class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/ipl_fan_battle"
    REDIS_URL: str = "redis://localhost:6379"
    ADMIN_KEY: str = "admin-secret-key-change-me"
    APP_HOST: str = "0.0.0.0"
    APP_PORT: int = int(os.getenv("PORT", 8000))

    model_config = SettingsConfigDict(
        env_file=".env", 
        extra="ignore",
        env_prefix="",
        case_sensitive=False
    )


@lru_cache()
def get_settings() -> Settings:
    settings = Settings()
    
    # Diagnostics for Railway deployment
    print("🛠️  Settings Diagnostic:")
    if "localhost" in settings.DATABASE_URL:
        print("  ⚠️ DATABASE_URL is using the default (localhost).")
    else:
        print(f"  ✅ DATABASE_URL loaded from environment (host: {settings.DATABASE_URL.split('@')[-1].split('/')[0] if '@' in settings.DATABASE_URL else 'unknown'})")
        
    if "localhost" in settings.REDIS_URL:
        print("  ⚠️ REDIS_URL is using the default (localhost).")
    else:
        print(f"  ✅ REDIS_URL loaded from environment (host: {settings.REDIS_URL.split('@')[-1] if '@' in settings.REDIS_URL else 'unknown'})")
        
    return settings
