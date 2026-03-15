from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List
from datetime import datetime, timezone, timedelta
from database import get_db
from models import User
from schemas import LeaderboardEntry, LeaderboardResponse

router = APIRouter(tags=["leaderboard"])


@router.get("/leaderboard", response_model=LeaderboardResponse)
async def get_leaderboard(
    period: str = Query("overall", regex="^(today|week|overall)$"),
    limit: int = Query(50, le=100),
    db: AsyncSession = Depends(get_db),
):
    """Get leaderboard sorted by Fan IQ."""
    query = select(User).order_by(desc(User.fan_iq)).limit(limit)

    now = datetime.now(timezone.utc)
    if period == "today":
        start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        query = query.where(User.created_at >= start)
    elif period == "week":
        start = now - timedelta(days=7)
        query = query.where(User.created_at >= start)

    result = await db.execute(query)
    users = result.scalars().all()

    entries = []
    for i, user in enumerate(users, 1):
        accuracy = 0.0
        if user.total_votes > 0:
            accuracy = round((user.correct_predictions / user.total_votes) * 100, 1)
        entries.append(LeaderboardEntry(
            rank=i,
            id=user.id,
            display_name=user.display_name,
            favorite_team=user.favorite_team,
            fan_iq=user.fan_iq,
            total_votes=user.total_votes,
            accuracy=accuracy,
        ))

    return LeaderboardResponse(period=period, entries=entries)
