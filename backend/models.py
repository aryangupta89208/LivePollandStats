import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Integer, Boolean, DateTime, ForeignKey, UniqueConstraint, Index, Text
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_id = Column(String(255), unique=True, nullable=False, index=True)
    favorite_team = Column(String(100), nullable=False)
    fan_iq = Column(Integer, default=0)
    total_votes = Column(Integer, default=0)
    correct_predictions = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    votes = relationship("Vote", back_populates="user", lazy="selectin")


class Poll(Base):
    __tablename__ = "polls"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    question = Column(Text, nullable=False)
    option_a = Column(String(255), nullable=False, default="Agree")
    option_b = Column(String(255), nullable=False, default="Disagree")
    category = Column(String(100), default="hot_take")
    active = Column(Boolean, default=True, index=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    votes = relationship("Vote", back_populates="poll", lazy="selectin")


class Vote(Base):
    __tablename__ = "votes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    poll_id = Column(UUID(as_uuid=True), ForeignKey("polls.id"), nullable=False)
    vote = Column(String(10), nullable=False)  # "a" or "b"
    team = Column(String(100), nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="votes")
    poll = relationship("Poll", back_populates="votes")

    __table_args__ = (
        UniqueConstraint("user_id", "poll_id", name="uq_user_poll_vote"),
        Index("ix_votes_poll_team", "poll_id", "team"),
    )
