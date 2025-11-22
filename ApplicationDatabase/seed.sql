-- Seed data for Chat App (idempotent)
-- Uses ON CONFLICT to upsert where applicable

-- Users
INSERT INTO "User" (username, display_name)
VALUES
  ('alice', 'Alice Johnson'),
  ('bob', 'Bob Smith'),
  ('charlie', 'Charlie Doe')
ON CONFLICT (username) DO UPDATE SET display_name = EXCLUDED.display_name;

-- Tags (user mentions and topic tags)
-- 'user' type values are the usernames; 'topic' type are topics without '#'
INSERT INTO "Tag" (type, value, display)
VALUES
  ('user', 'alice', '@alice'),
  ('user', 'bob', '@bob'),
  ('user', 'charlie', '@charlie'),
  ('topic', 'help', '#help'),
  ('topic', 'general', '#general'),
  ('topic', 'react', '#react'),
  ('topic', 'postgres', '#postgres')
ON CONFLICT (value) DO UPDATE SET
  type = EXCLUDED.type,
  display = EXCLUDED.display;

-- Tag Suggestions:
-- For trigger '@' suggest user-type tags; for '#' suggest topic-type tags.
-- Value references Tag.value; type mirrors Tag.type for consistency.
INSERT INTO "TagSuggestion" (trigger, value, type)
VALUES
  ('@', 'alice', 'user'),
  ('@', 'bob', 'user'),
  ('@', 'charlie', 'user'),
  ('#', 'help', 'topic'),
  ('#', 'general', 'topic'),
  ('#', 'react', 'topic'),
  ('#', 'postgres', 'topic')
ON CONFLICT DO NOTHING;

-- Messages
-- Create messages for each user
WITH u AS (
  SELECT id, username FROM "User"
),
msg_ins AS (
  INSERT INTO "Message" (user_id, content, status)
  SELECT id, 'Hello everyone! @bob check #general', 'sent' FROM u WHERE username = 'alice'
  RETURNING id
), msg2 AS (
  INSERT INTO "Message" (user_id, content, status)
  SELECT id, 'Thanks @alice! Let us discuss #react', 'delivered' FROM u WHERE username = 'bob'
  RETURNING id
), msg3 AS (
  INSERT INTO "Message" (user_id, content, status)
  SELECT id, 'I can help with #postgres indexing', 'read' FROM u WHERE username = 'charlie'
  RETURNING id
)
SELECT 1;

-- Link messages with tags if not already linked
-- Helper CTEs to get message ids and tag ids
WITH
  m1 AS (SELECT id AS message_id FROM "Message" ORDER BY id ASC LIMIT 1),
  m2 AS (SELECT id AS message_id FROM "Message" ORDER BY id ASC OFFSET 1 LIMIT 1),
  m3 AS (SELECT id AS message_id FROM "Message" ORDER BY id ASC OFFSET 2 LIMIT 1),
  t_bob AS (SELECT id AS tag_id FROM "Tag" WHERE value = 'bob'),
  t_alice AS (SELECT id AS tag_id FROM "Tag" WHERE value = 'alice'),
  t_general AS (SELECT id AS tag_id FROM "Tag" WHERE value = 'general'),
  t_react AS (SELECT id AS tag_id FROM "Tag" WHERE value = 'react'),
  t_postgres AS (SELECT id AS tag_id FROM "Tag" WHERE value = 'postgres')
INSERT INTO "MessageTag" (message_id, tag_id)
SELECT m.message_id, t.tag_id
FROM (
  SELECT message_id, tag_key FROM
  (SELECT message_id, 't_bob' AS tag_key FROM m1
   UNION ALL SELECT message_id, 't_general' FROM m1
   UNION ALL SELECT message_id, 't_alice' FROM m2
   UNION ALL SELECT message_id, 't_react' FROM m2
   UNION ALL SELECT message_id, 't_postgres' FROM m3) mt
) m
JOIN (
  SELECT 't_bob' AS tag_key, tag_id FROM t_bob
  UNION ALL SELECT 't_general', tag_id FROM t_general
  UNION ALL SELECT 't_alice', tag_id FROM t_alice
  UNION ALL SELECT 't_react', tag_id FROM t_react
  UNION ALL SELECT 't_postgres', tag_id FROM t_postgres
) t USING (tag_key)
ON CONFLICT DO NOTHING;
