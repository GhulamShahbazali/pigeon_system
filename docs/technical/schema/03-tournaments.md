[← Back to schema index](index.md)

---

# Section 3: Tournaments

> The flagship module. An organizer creates a tournament; participants each fly up to `pigeon_count` pigeons; the owner records each **returned** pigeon's landing time per day; averages (flight duration) rank participants **descending** (higher = winner). Public: anyone can follow/like/view, counts are live.
> Behaviour locked in `../../product/locked-decisions.md` §2 (T1–T33).

---

## Table: `tournaments`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `organizer_id` | UUID | Yes | FK `users` — the creator; **only they** edit/manage (T2) |
| `title` | string | Yes | |
| `rules` | text | No | |
| `description` | text | No | |
| `cover_url` | string | No | R2 image; **null → UI uses a gradient cover** (T6b) |
| `num_days` | integer | Yes | 1..N (T9) |
| `schedule_type` | enum | Yes | `every_day` \| `alternate_days` (T10) |
| `pigeon_count` | integer | Yes | **max pigeons each participant records per day** (T11) — never more, may be fewer |
| `fly_time` | time | Yes | daily release time (local wall-clock, applied per day) |
| `end_time` | time | Yes | daily ending time |
| `start_date` | date | Yes | Day 1; later day dates derive from `num_days` + `schedule_type` |
| `organizer_contact` | string | No | phone/WhatsApp number shown on detail (T14b) |
| `status` | enum | Yes | `active` \| `completed` — default `active` |
| `like_count` | integer | Yes | denormalized, default 0 |
| `view_count` | integer | Yes | denormalized, default 0 |
| `follower_count` | integer | Yes | denormalized, default 0 |
| `overall_avg_seconds` | integer | No | denormalized leader/overall average (see recompute) |
| `link_slug` | string | Yes | unique — the shareable deep link `pigeonfly.app/t/{link_slug}` (T14e) |
| `created_at` | timestamp | Yes | |
| `updated_at` | timestamp | Yes | |
| `deleted_at` | timestamp | No | soft delete (keep — participants/flights reference it) |

**Indexes:**
- `(status, created_at DESC)` partial WHERE `deleted_at IS NULL` — public list / "All"
- `(organizer_id, created_at DESC)` — "Mine"
- unique `(link_slug)` — deep-link resolve
- GIN `to_tsvector('simple', title)` — search

**Rules:**
- Create/edit/delete: **organizer only** (app-layer + `organizer_id` check). SuperAdmin override via admin module.
- Timezone: `fly_time`/`end_time` are wall-clock; the day's UTC release instant = `start_date`(+offset) at `fly_time` in the organizer's timezone (`users.timezone`). Needed to compute `duration_seconds`.
- Counts updated atomically in the like/view/follow transaction (never a job).

---

## Table: `tournament_days`

One row per flying day (handles alternate-day date gaps explicitly, rather than deriving on every read).

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `tournament_id` | UUID | Yes | FK `tournaments` (cascade) |
| `day_number` | integer | Yes | 1-based |
| `date` | date | Yes | actual calendar date of this flying day |
| `release_at` | timestamp | Yes | UTC instant of release (date + `fly_time` in organizer tz) — the subtrahend for `duration_seconds` |
| `created_at` | timestamp | Yes | |

**Indexes:** unique `(tournament_id, day_number)`; `(tournament_id, date)`.

---

## Table: `tournament_participants`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `tournament_id` | UUID | Yes | FK `tournaments` (cascade) |
| `name` | string | Yes | required (T16) |
| `photo_url` | string | No | R2 (T17) |
| `contact_no` | string | No | optional (T18) |
| `phone` | string | No | optional (T19) |
| `address` | string | No | optional (T20) |
| `overall_avg_seconds` | integer | No | **denormalized** average flight duration across all days (recorded flights only) — drives ranking |
| `overall_returned_count` | integer | Yes | total recorded (returned) flights across days, default 0 |
| `position` | integer | No | denormalized overall rank (1 = best), recomputed with `overall_avg_seconds` |
| `created_at` | timestamp | Yes | |
| `deleted_at` | timestamp | No | soft delete |

**Indexes:**
- `(tournament_id, overall_avg_seconds DESC)` partial WHERE `deleted_at IS NULL` — **standings, instant** (higher = better)
- `(tournament_id, name)` — lookup

**Rules:**
- Managed by the **organizer only**.
- A participant records **at most `pigeon_count`** flights per day (enforced in service; see `pigeon_flights`).

---

## Table: `participant_day_stats`

Per-participant, per-day denormalized average (so the day tab renders without `AVG()`).

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `participant_id` | UUID | Yes | FK `tournament_participants` (cascade) |
| `day_id` | UUID | Yes | FK `tournament_days` (cascade) |
| `avg_seconds` | integer | No | average flight duration this day (recorded flights only) |
| `returned_count` | integer | Yes | recorded flights this day (≤ `pigeon_count`), default 0 |

**Indexes:** unique `(participant_id, day_id)`.

---

## Table: `pigeon_flights`

The core record — **one row per returned pigeon, per participant, per day.** A pigeon that doesn't return is **never inserted** (so it never affects the average — T27b).

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `tournament_id` | UUID | Yes | FK `tournaments` (cascade) — denormalized for query locality |
| `participant_id` | UUID | Yes | FK `tournament_participants` (cascade) |
| `day_id` | UUID | Yes | FK `tournament_days` (cascade) |
| `pigeon_name` | string | Yes | |
| `landing_time` | timestamp | Yes | UTC instant the pigeon returned |
| `duration_seconds` | integer | Yes | **= `landing_time − tournament_days.release_at`**, computed on insert, stored |
| `created_at` | timestamp | Yes | |
| `updated_at` | timestamp | Yes | |

**Indexes:**
- `(participant_id, day_id)` — a participant's pigeons for a day (the detail table)
- `(day_id, duration_seconds DESC)` — per-day leaderboard
- `(tournament_id)` — cascade / counts

**Rules:**
- **Owner-only** insert/edit/delete (T2).
- **Count cap:** `COUNT(*) WHERE participant_id, day_id` must stay `≤ tournaments.pigeon_count` — enforced in the service before insert (T11). Never more; fewer is fine.
- `duration_seconds` is **always derived server-side** from `release_at`; the client only sends `landing_time`.
- On insert/edit/delete, **recompute in the same transaction**: `participant_day_stats` (that day) and `tournament_participants.overall_avg_seconds` + `overall_returned_count` + `position`, then emit `tournament.update` (socket) + enqueue `follower-fanout` for notifications.
- **Higher `overall_avg_seconds` = better** (longest average flight wins). "Not returned" never appears here.

**Cascade:** on tournament/participant/day delete → cascade. Deleting a flight (owner correction) → row removed, averages recomputed.

---

## Table: `tournament_follows`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `tournament_id` | UUID | Yes | FK (cascade) |
| `user_id` | UUID | Yes | FK `users` (cascade) |
| `created_at` | timestamp | Yes | |

**Indexes:** unique `(tournament_id, user_id)`; `(user_id, created_at DESC)` — a user's followed tournaments.
**Rules:** hard delete on unfollow; `tournaments.follower_count` updated atomically; follow is what drives **notifications** (T32) via `follower-fanout`.

---

## Table: `tournament_likes`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `tournament_id` | UUID | Yes | FK (cascade) |
| `user_id` | UUID | Yes | FK `users` (cascade) |
| `created_at` | timestamp | Yes | |

**Indexes:** unique `(tournament_id, user_id)`.
**Rules:** hard delete on unlike; `like_count` atomic; `tournament.counts` socket emit debounced 2s (performance doc §3).

---

## Table: `tournament_views`

Deduped view tracking (a user counts once).

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `tournament_id` | UUID | Yes | FK (cascade) |
| `user_id` | UUID | Yes | FK `users` (cascade) |
| `created_at` | timestamp | Yes | |

**Indexes:** unique `(tournament_id, user_id)` — one view per user; `view_count` denormalized on first insert.

---

## Application-layer patterns

- **Standings read** = `SELECT * FROM tournament_participants WHERE tournament_id=? AND deleted_at IS NULL ORDER BY overall_avg_seconds DESC` — pure index scan, no aggregation.
- **Day tab** = `participant_day_stats` join `pigeon_flights` for the selected `day_id`.
- **Average math** lives in one service method (`recomputeParticipantStats(participant_id)`) called inside every flight write transaction — the single place duration→average logic exists.
- **Export (Excel/PDF/Image)** reads the denormalized stats + flights; generated in the `export-generate` worker (never inline).
- **Deep link** resolves `link_slug` → tournament id (performance doc; smart-link landing).

---

*Section 3: Tournaments · v0.1 · 2026-10-03*
