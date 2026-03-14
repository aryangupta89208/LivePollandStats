from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from database import get_db
from models import User
from schemas import SignupRequest, UserResponse

router = APIRouter(tags=["auth"])


@router.post("/signup", response_model=UserResponse)
async def signup(req: SignupRequest, db: AsyncSession = Depends(get_db)):
    """Register or login via device_id. Returns existing user if already registered."""
    result = await db.execute(select(User).where(User.device_id == req.device_id))
    user = result.scalar_one_or_none()

    if user:
        if user.favorite_team != req.favorite_team:
            user.favorite_team = req.favorite_team
            await db.commit()
            await db.refresh(user)
        return _build_user_response(user)

    user = User(device_id=req.device_id, favorite_team=req.favorite_team)
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return _build_user_response(user)


@router.get("/user/{device_id}", response_model=UserResponse)
async def get_user(device_id: str, db: AsyncSession = Depends(get_db)):
    """Get user profile by device_id."""
    result = await db.execute(select(User).where(User.device_id == device_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return _build_user_response(user)


def _build_user_response(user: User) -> UserResponse:
    accuracy = 0.0
    if user.total_votes > 0:
        accuracy = round((user.correct_predictions / user.total_votes) * 100, 1)
    return UserResponse(
        id=user.id,
        device_id=user.device_id,
        favorite_team=user.favorite_team,
        fan_iq=user.fan_iq,
        total_votes=user.total_votes,
        correct_predictions=user.correct_predictions,
        accuracy=accuracy,
    )
