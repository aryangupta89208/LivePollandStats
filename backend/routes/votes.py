from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from database import get_db
from models import User, Poll, Vote
from schemas import VoteRequest, VoteResponse
from redis_client import increment_vote, get_vote_counts, sync_poll_to_redis
from ws import manager
from sqlalchemy import func

router = APIRouter(tags=["votes"])


@router.post("/vote", response_model=VoteResponse)
async def cast_vote(req: VoteRequest, db: AsyncSession = Depends(get_db)):
    """Cast a vote on a poll. One vote per user per poll."""

    # 1. Validate user
    user_result = await db.execute(select(User).where(User.id == req.user_id))
    user = user_result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # 2. Validate poll
    poll_result = await db.execute(select(Poll).where(Poll.id == req.poll_id))
    poll = poll_result.scalar_one_or_none()
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")
    if not poll.active:
        raise HTTPException(status_code=400, detail="Poll is closed")

    # 3. Check duplicate
    existing = await db.execute(
        select(Vote).where(Vote.user_id == req.user_id, Vote.poll_id == req.poll_id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Already voted on this poll")

    # 4. Create vote
    vote = Vote(
        user_id=req.user_id,
        poll_id=req.poll_id,
        vote=req.vote,
        team=user.favorite_team,
    )
    db.add(vote)

    # 5. Update user stats
    user.total_votes += 1
    user.fan_iq += 10  # Base IQ points per vote

    await db.commit()
    await db.refresh(vote)

    # 6. Update Redis
    poll_id_str = str(req.poll_id)
    await increment_vote(poll_id_str, req.vote)

    # 7. Get updated counts for response & broadcast
    cached = await get_vote_counts(poll_id_str)
    if cached:
        votes_a = cached["votes_a"]
        votes_b = cached["votes_b"]
        total = cached["total"]
    else:
        count_a = await db.execute(
            select(func.count()).where(Vote.poll_id == req.poll_id, Vote.vote == "a")
        )
        count_b = await db.execute(
            select(func.count()).where(Vote.poll_id == req.poll_id, Vote.vote == "b")
        )
        votes_a = count_a.scalar() or 0
        votes_b = count_b.scalar() or 0
        total = votes_a + votes_b
        await sync_poll_to_redis(poll_id_str, votes_a, votes_b)

    pct_a = round((votes_a / total) * 100, 1) if total > 0 else 0.0
    pct_b = round((votes_b / total) * 100, 1) if total > 0 else 0.0

    # 8. WebSocket broadcast via Redis Pub/Sub
    from redis_client import publish_vote_update
    await publish_vote_update(poll_id_str, {
        "votes_a": votes_a,
        "votes_b": votes_b,
        "total_votes": total,
        "percentage_a": pct_a,
        "percentage_b": pct_b,
    })

    from schemas import PollResponse
    poll_resp = PollResponse(
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
        user_vote=req.vote,
    )

    return VoteResponse(success=True, message="Vote recorded!", poll=poll_resp)
