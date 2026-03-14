-- IPL Fan Battle Database Schema
-- Run this in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id VARCHAR(255) UNIQUE NOT NULL,
    favorite_team VARCHAR(100) NOT NULL,
    fan_iq INTEGER DEFAULT 0,
    total_votes INTEGER DEFAULT 0,
    correct_predictions INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_users_device_id ON users(device_id);
CREATE INDEX IF NOT EXISTS ix_users_fan_iq ON users(fan_iq DESC);

-- Polls table
CREATE TABLE IF NOT EXISTS polls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question TEXT NOT NULL,
    option_a VARCHAR(255) NOT NULL DEFAULT 'Agree',
    option_b VARCHAR(255) NOT NULL DEFAULT 'Disagree',
    category VARCHAR(100) DEFAULT 'hot_take',
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_polls_active ON polls(active);

-- Votes table
CREATE TABLE IF NOT EXISTS votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    vote VARCHAR(10) NOT NULL,
    team VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_user_poll_vote UNIQUE(user_id, poll_id)
);

CREATE INDEX IF NOT EXISTS ix_votes_poll_team ON votes(poll_id, team);
CREATE INDEX IF NOT EXISTS ix_votes_user ON votes(user_id);

-- Row Level Security (optional, for direct Supabase access)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;

-- Allow read access to polls for anonymous users
CREATE POLICY "Public polls are viewable by everyone" ON polls
    FOR SELECT USING (true);

-- Allow read access to vote counts
CREATE POLICY "Vote counts are viewable by everyone" ON votes
    FOR SELECT USING (true);
