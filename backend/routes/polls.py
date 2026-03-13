from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Optional, List
from uuid import UUID
from database import get_db
from models import Poll, Vote
from schemas import PollResponse, PollResultResponse, TeamBreakdown
from redis_client import get_vote_counts, sync_poll_to_redis

router = APIRouter(tags=["polls"])

IPL_TEAMS = [
    "Chennai Super Kings", "Mumbai Indians", "Royal Challengers Bengaluru",
    "Kolkata Knight Riders", "Rajasthan Royals", "Sunrisers Hyderabad",
    "Delhi Capitals", "Punjab Kings", "Gujarat Titans", "Lucknow Super Giants",
]


@router.get("/polls", response_model=List[PollResponse])
async def get_polls(
    user_id: Optional[UUID] = Query(None),
    skip: int = 0,
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
):
    """Get active polls with vote counts."""
    result = await db.execute(
        select(Poll)
        .where(Poll.active == True)
        .order_by(Poll.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    polls = result.scalars().all()

    # Get user votes if user_id provided
    user_votes = {}
    if user_id:
        vote_result = await db.execute(
            select(Vote.poll_id, Vote.vote).where(Vote.user_id == user_id)
        )
        user_votes = {str(row[0]): row[1] for row in vote_result.all()}

    responses = []
    for poll in polls:
        poll_resp = await _build_poll_response(poll, db, user_votes.get(str(poll.id)))
        responses.append(poll_resp)

    return responses


@router.get("/poll/{poll_id}", response_model=PollResponse)
async def get_poll(
    poll_id: UUID,
    user_id: Optional[UUID] = Query(None),
    db: AsyncSession = Depends(get_db),
):
    """Get a single poll."""
    result = await db.execute(select(Poll).where(Poll.id == poll_id))
    poll = result.scalar_one_or_none()
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")

    user_vote = None
    if user_id:
        vote_result = await db.execute(
            select(Vote.vote).where(Vote.user_id == user_id, Vote.poll_id == poll_id)
        )
        row = vote_result.scalar_one_or_none()
        user_vote = row if row else None

    return await _build_poll_response(poll, db, user_vote)


@router.get("/poll/{poll_id}/results", response_model=PollResultResponse)
async def get_poll_results(
    poll_id: UUID,
    user_id: Optional[UUID] = Query(None),
    db: AsyncSession = Depends(get_db),
):
    """Get detailed poll results with team breakdown."""
    result = await db.execute(select(Poll).where(Poll.id == poll_id))
    poll = result.scalar_one_or_none()
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")

    user_vote = None
    if user_id:
        vote_result = await db.execute(
            select(Vote.vote).where(Vote.user_id == user_id, Vote.poll_id == poll_id)
        )
        row = vote_result.scalar_one_or_none()
        user_vote = row if row else None

    poll_resp = await _build_poll_response(poll, db, user_vote)

    # Team breakdown
    team_stats = await db.execute(
        select(
            Vote.team,
            func.count().filter(Vote.vote == "a").label("votes_a"),
            func.count().filter(Vote.vote == "b").label("votes_b"),
            func.count().label("total"),
        )
        .where(Vote.poll_id == poll_id)
        .group_by(Vote.team)
        .order_by(func.count().desc())
    )

    breakdown = []
    for row in team_stats.all():
        team, va, vb, total = row
        pct_a = round((va / total) * 100, 1) if total > 0 else 0.0
        breakdown.append(TeamBreakdown(
            team=team, votes_a=va, votes_b=vb, total=total, percentage_a=pct_a
        ))

    return PollResultResponse(poll=poll_resp, team_breakdown=breakdown)


async def _build_poll_response(
    poll: Poll, db: AsyncSession, user_vote: Optional[str] = None
) -> PollResponse:
    """Build poll response with cached or DB vote counts."""
    poll_id_str = str(poll.id)

    # Try Redis cache first
    cached = await get_vote_counts(poll_id_str)
    if cached:
        votes_a = cached["votes_a"]
        votes_b = cached["votes_b"]
        total = cached["total"]
    else:
        # Fallback to DB count
        count_a = await db.execute(
            select(func.count()).where(Vote.poll_id == poll.id, Vote.vote == "a")
        )
        count_b = await db.execute(
            select(func.count()).where(Vote.poll_id == poll.id, Vote.vote == "b")
        )
        votes_a = count_a.scalar() or 0
        votes_b = count_b.scalar() or 0
        total = votes_a + votes_b

        # Warm cache
        await sync_poll_to_redis(poll_id_str, votes_a, votes_b)

    pct_a = round((votes_a / total) * 100, 1) if total > 0 else 0.0
    pct_b = round((votes_b / total) * 100, 1) if total > 0 else 0.0

    return PollResponse(
        id=poll.id,
        question=poll.question,
        option_a=poll.option_a,
        option_b=poll.option_b,
        category=poll.category,
        active=poll.active,
        created_at=poll.created_at,
        votes_a=votes_a,
        votes_b=votes_b,
        total_votes=total,
        percentage_a=pct_a,
        percentage_b=pct_b,
        user_vote=user_vote,
    )
