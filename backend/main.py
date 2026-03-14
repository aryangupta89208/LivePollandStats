from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
import json

from database import init_db
from redis_client import init_redis, close_redis
from ws import manager

from routes.auth import router as auth_router
from routes.polls import router as polls_router
from routes.votes import router as votes_router
from routes.leaderboard import router as leaderboard_router
from routes.admin import router as admin_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    try:
        await init_db()
    except Exception as e:
        print(f"❌ Database initialization failed: {e}")

    try:
        await init_redis()
        from redis_client import listen_for_votes
        import asyncio
        asyncio.create_task(listen_for_votes())
        print("✅ Redis Pub/Sub listener started")
    except Exception as e:
        print(f"❌ Redis initialization failed: {e}")

    print("🏏 IPL Fan Battle API is live!")
    yield
    # Shutdown
    await close_redis()
    print("👋 Shutting down...")


app = FastAPI(
    title="IPL Fan Battle API",
    description="🏏 Vote on hot IPL takes & see real-time fanbase battles",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routes
app.include_router(auth_router)
app.include_router(polls_router)
app.include_router(votes_router)
app.include_router(leaderboard_router)
app.include_router(admin_router)

# Mount admin static files
app.mount("/admin", StaticFiles(directory="admin", html=True), name="admin")


# ── WebSocket endpoint ──
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            try:
                msg = json.loads(data)
                if msg.get("type") == "subscribe" and msg.get("poll_id"):
                    manager.subscribe_to_poll(websocket, msg["poll_id"])
            except json.JSONDecodeError:
                pass
    except WebSocketDisconnect:
        manager.disconnect(websocket)


# ── Health check ──
@app.get("/health")
async def health():
    return {"status": "ok", "app": "IPL Fan Battle"}


if __name__ == "__main__":
    import uvicorn
    from config import get_settings
    settings = get_settings()
    uvicorn.run(
        "main:app",
        host=settings.APP_HOST,
        port=settings.APP_PORT,
        reload=True,
    )
