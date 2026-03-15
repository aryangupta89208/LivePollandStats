from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import List, Optional
from uuid import UUID
from database import get_db
from models import Poll, Vote
from schemas import CreatePollRequest, UpdatePollRequest, PollResponse
from config import get_settings
from redis_client import invalidate_poll_cache, publish_poll_deletion

router = APIRouter(prefix="/admin", tags=["admin"])
settings = get_settings()


def verify_admin(x_admin_key: str = Header(...)):
    if x_admin_key != settings.ADMIN_KEY:
        raise HTTPException(status_code=403, detail="Invalid admin key")
    return True


@router.post("/polls", response_model=dict)
async def create_poll(
    req: CreatePollRequest,
    db: AsyncSession = Depends(get_db),
    _: bool = Depends(verify_admin),
):
    """Create a new poll."""
    poll = Poll(
        question=req.question,
        option_a=req.option_a,
        option_b=req.option_b,
        category=req.category,
    )
    db.add(poll)
    await db.commit()
    await db.refresh(poll)
    return {"id": str(poll.id), "question": poll.question, "created": True}


@router.put("/polls/{poll_id}", response_model=dict)
async def update_poll(
    poll_id: UUID,
    req: UpdatePollRequest,
    db: AsyncSession = Depends(get_db),
    _: bool = Depends(verify_admin),
):
    """Update a poll (edit, activate, close)."""
    result = await db.execute(select(Poll).where(Poll.id == poll_id))
    poll = result.scalar_one_or_none()
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")

    if req.question is not None:
        poll.question = req.question
    if req.option_a is not None:
        poll.option_a = req.option_a
    if req.option_b is not None:
        poll.option_b = req.option_b
    if req.active is not None:
        poll.active = req.active
    if req.category is not None:
        poll.category = req.category

    await db.commit()
    await invalidate_poll_cache(str(poll_id))
    return {"id": str(poll.id), "updated": True}


@router.delete("/polls/{poll_id}", response_model=dict)
async def delete_poll(
    poll_id: UUID,
    db: AsyncSession = Depends(get_db),
    _: bool = Depends(verify_admin),
):
    """Delete a poll."""
    result = await db.execute(select(Poll).where(Poll.id == poll_id))
    poll = result.scalar_one_or_none()
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")

    await db.delete(poll)
    await db.commit()
    await invalidate_poll_cache(str(poll_id))
    await publish_poll_deletion(str(poll_id))
    return {"id": str(poll_id), "deleted": True}


@router.get("/polls", response_model=List[dict])
async def list_all_polls(
    db: AsyncSession = Depends(get_db),
    _: bool = Depends(verify_admin),
):
    """List all polls with vote stats."""
    result = await db.execute(select(Poll).order_by(Poll.created_at.desc()))
    polls = result.scalars().all()

    response = []
    for poll in polls:
        count_a = await db.execute(
            select(func.count()).where(Vote.poll_id == poll.id, Vote.vote == "a")
        )
        count_b = await db.execute(
            select(func.count()).where(Vote.poll_id == poll.id, Vote.vote == "b")
        )
        va = count_a.scalar() or 0
        vb = count_b.scalar() or 0
        response.append({
            "id": str(poll.id),
            "question": poll.question,
            "option_a": poll.option_a,
            "option_b": poll.option_b,
            "category": poll.category,
            "active": poll.active,
            "votes_a": va,
            "votes_b": vb,
            "total_votes": va + vb,
            "created_at": poll.created_at.isoformat(),
        })

    return response


@router.get("/stats", response_model=dict)
async def get_stats(
    db: AsyncSession = Depends(get_db),
    _: bool = Depends(verify_admin),
):
    """Get overall statistics."""
    from models import User
    total_users = (await db.execute(select(func.count()).select_from(User))).scalar() or 0
    total_polls = (await db.execute(select(func.count()).select_from(Poll))).scalar() or 0
    total_votes = (await db.execute(select(func.count()).select_from(Vote))).scalar() or 0
    active_polls = (await db.execute(
        select(func.count()).where(Poll.active == True)
    )).scalar() or 0

    return {
        "total_users": total_users,
        "total_polls": total_polls,
        "total_votes": total_votes,
        "active_polls": active_polls,
    }
