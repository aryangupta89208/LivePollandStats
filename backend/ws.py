from fastapi import WebSocket
from typing import Dict, Set
import json
import asyncio


class ConnectionManager:
    """Manages WebSocket connections for real-time poll updates."""

    def __init__(self):
        # All active connections
        self.active_connections: Set[WebSocket] = set()
        # Connections subscribed to specific polls
        self.poll_subscribers: Dict[str, Set[WebSocket]] = {}

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.add(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.discard(websocket)
        # Remove from all poll subscriptions
        for poll_id in list(self.poll_subscribers.keys()):
            self.poll_subscribers[poll_id].discard(websocket)
            if not self.poll_subscribers[poll_id]:
                del self.poll_subscribers[poll_id]

    def subscribe_to_poll(self, websocket: WebSocket, poll_id: str):
        if poll_id not in self.poll_subscribers:
            self.poll_subscribers[poll_id] = set()
        self.poll_subscribers[poll_id].add(websocket)

    async def broadcast_vote_update(self, poll_id: str, data: dict):
        """Broadcast vote update to all connected clients."""
        message = json.dumps({
            "type": "vote_update",
            "poll_id": poll_id,
            "data": data
        })

        # Broadcast to all connected clients (feed updates)
        dead_connections = set()
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception:
                dead_connections.add(connection)

        # Clean up dead connections
        for conn in dead_connections:
            self.disconnect(conn)

    async def send_personal_message(self, message: dict, websocket: WebSocket):
        try:
            await websocket.send_text(json.dumps(message))
        except Exception:
            self.disconnect(websocket)


manager = ConnectionManager()
