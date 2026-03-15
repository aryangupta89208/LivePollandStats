from pydantic import BaseModel, Field
from typing import Optional, List
from uuid import UUID
from datetime import datetime


# ── Auth ──
class SignupRequest(BaseModel):
    device_id: str = Field(..., min_length=1, max_length=255)
    favorite_team: str = Field(..., min_length=1, max_length=100)
    display_name: Optional[str] = Field(None, max_length=100)


class UserResponse(BaseModel):
    id: UUID
    device_id: str
    display_name: str
    favorite_team: str
    fan_iq: int
    total_votes: int
    correct_predictions: int
    accuracy: float = 0.0

    class Config:
        from_attributes = True


# ── Polls ──
class PollResponse(BaseModel):
    id: UUID
    question: str
    option_a: str
    option_b: str
    category: str
    active: bool
    created_at: datetime
    votes_a: int = 0
    votes_b: int = 0
    total_votes: int = 0
    percentage_a: float = 0.0
    percentage_b: float = 0.0
    user_vote: Optional[str] = None

    class Config:
        from_attributes = True


class TeamBreakdown(BaseModel):
    team: str
    votes_a: int
    votes_b: int
    total: int
    percentage_a: float


class PollResultResponse(BaseModel):
    poll: PollResponse
    team_breakdown: List[TeamBreakdown]


# ── Votes ──
class VoteRequest(BaseModel):
    user_id: UUID
    poll_id: UUID
    vote: str = Field(..., pattern="^(a|b)$")


class VoteResponse(BaseModel):
    success: bool
    message: str
    poll: Optional[PollResponse] = None


# ── Leaderboard ──
class LeaderboardEntry(BaseModel):
    rank: int
    id: UUID
    display_name: str
    favorite_team: str
    fan_iq: int
    total_votes: int
    accuracy: float


class LeaderboardResponse(BaseModel):
    period: str
    entries: List[LeaderboardEntry]


# ── Admin ──
class CreatePollRequest(BaseModel):
    question: str = Field(..., min_length=5)
    option_a: str = Field(default="Agree", max_length=255)
    option_b: str = Field(default="Disagree", max_length=255)
    category: str = Field(default="hot_take", max_length=100)


class UpdatePollRequest(BaseModel):
    question: Optional[str] = None
    option_a: Optional[str] = None
    option_b: Optional[str] = None
    active: Optional[bool] = None
    category: Optional[str] = None
