-- Application Database Schema for Chat App (PostgreSQL)
-- Idempotent: guarded with IF NOT EXISTS and repeatable constraints

-- Enable required extensions (safe if already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS "User" (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  display_name VARCHAR(100),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Messages table
CREATE TABLE IF NOT EXISTS "Message" (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  content VARCHAR(2000) NOT NULL,
  status VARCHAR(20) NOT NULL CHECK (status IN ('sent', 'delivered', 'read')),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_message_user
    FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE
);

-- Tags table
CREATE TABLE IF NOT EXISTS "Tag" (
  id SERIAL PRIMARY KEY,
  type VARCHAR(20) NOT NULL CHECK (type IN ('user', 'topic')),
  value VARCHAR(100) NOT NULL UNIQUE,
  display VARCHAR(100),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- MessageTag join table
CREATE TABLE IF NOT EXISTS "MessageTag" (
  message_id INTEGER NOT NULL,
  tag_id INTEGER NOT NULL,
  PRIMARY KEY (message_id, tag_id),
  CONSTRAINT fk_messagetag_message
    FOREIGN KEY (message_id) REFERENCES "Message"(id) ON DELETE CASCADE,
  CONSTRAINT fk_messagetag_tag
    FOREIGN KEY (tag_id) REFERENCES "Tag"(id) ON DELETE CASCADE
);

-- TagSuggestion table
CREATE TABLE IF NOT EXISTS "TagSuggestion" (
  id SERIAL PRIMARY KEY,
  trigger VARCHAR(2) NOT NULL CHECK (trigger IN ('@', '#')),
  value VARCHAR(100) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('user', 'topic')),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_tagsuggestion_tag_value
    FOREIGN KEY (value) REFERENCES "Tag"(value) ON DELETE CASCADE
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_message_user_id ON "Message"(user_id);
CREATE INDEX IF NOT EXISTS idx_tag_value ON "Tag"(value);
CREATE INDEX IF NOT EXISTS idx_tag_type ON "Tag"(type);
CREATE INDEX IF NOT EXISTS idx_tag_suggestion_trigger ON "TagSuggestion"(trigger);

-- Optional GIN index for full-text / fast search on tags (commented; enable if needed)
-- CREATE INDEX IF NOT EXISTS idx_tag_value_gin ON "Tag" USING gin (to_tsvector('english', value));
