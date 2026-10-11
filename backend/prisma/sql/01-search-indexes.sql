-- Trigram search indexes — make ILIKE '%q%' use an index instead of a seq scan.
-- pg_trgm GIN indexes accelerate LIKE/ILIKE substring search up to millions of rows,
-- so the existing Prisma `contains` / `mode: insensitive` search queries scale
-- WITHOUT any query rewrite. Applied out-of-band (not via `prisma db push`).
--
-- At production scale, recreate these with CREATE INDEX CONCURRENTLY (cannot run in a
-- transaction, so run each statement separately) to avoid locking the table.

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- /search/users  → users.display_name (ILIKE) + users.username (LIKE)
CREATE INDEX IF NOT EXISTS idx_users_displayname_trgm
  ON users USING gin (display_name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_users_username_trgm
  ON users USING gin (username gin_trgm_ops);

-- /search/tournaments  → tournaments.title (ILIKE)
CREATE INDEX IF NOT EXISTS idx_tournaments_title_trgm
  ON tournaments USING gin (title gin_trgm_ops);
