-- Minimum user table expected by the Round Table engine.
--
-- The engine reads exactly FOUR columns from `users`:
--   id              — stable identifier (text or integer, cast to text internally)
--   created_at      — used to compute account age for eligibility
--   verified_at     — non-null means the account is "verified" (any timestamp)
--   profile_public  — 1 means public profile exists (also counts toward eligibility)
--
-- If you already have a users table from your auth system, add these four
-- columns (or adapt /api/rt/me in round-table.js to read from your schema).
-- Everything else in your users table is yours — the engine ignores it.

CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  verified_at INTEGER,
  profile_public INTEGER DEFAULT 1
);
