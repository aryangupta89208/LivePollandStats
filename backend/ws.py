from fastapi import WebSocket
from typing import Dict, Set
import json
import asyncio


class ConnectionManager:
    """Manages WebSocket connections for real-time poll updates."""

    def __init__(self):
        # All active connections on THIS instance
        self.active_connections: Set[WebSocket] = set()

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.add(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.discard(websocket)

    def subscribe_to_poll(self, websocket: WebSocket, poll_id: str):
        # Deprecated: feed handles all updates
        pass

    async def _local_broadcast(self, poll_id: str, data: dict):
        """Broadcast vote update to all clients connected to THIS instance."""
        message = json.dumps({
            "type": "vote_update",
            "poll_id": poll_id,
            "data": data
        })

        dead_connections = set()
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception:
                dead_connections.add(connection)

        # Clean up dead connections
        for conn in dead_connections:
            self.disconnect(conn)

manager = ConnectionManager()
