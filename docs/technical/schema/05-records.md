[← Back to schema index](index.md)

---

# Section 5: Personal Records

> A user's own daily flying routine. Each record is **private** (stored only) or **live** (broadcast). Live records appear in the "Live now" list, stream landings in real time, and **auto-end at the owner's local midnight** — `live → completed`, kept in history, never deleted. Same duration/average model as tournaments.
> Behaviour locked in `../../product/locked-decisions.md` §4 (R1–R19).

---

## Table: `personal_records`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `user_id` | UUID | Yes | FK `users` (cascade on permanent delete) — the owner |
| `record_date` | date | Yes | the day this record is for |
| `fly_time` | time | Yes | release time (owner wall-clock) |
| `release_at` | timestamp | Yes | UTC release instant (date + `fly_time` in owner tz) — subtrahend for `duration_seconds` |
| `total_pigeons` | integer | Yes | how many flown that day (header field) |
| `privacy` | enum | Yes | `private` \| `live` — default **`private`** (R7) |
| `status` | enum | Yes | `open` \| `completed` — a live record is `open` until it ends |
| `total_avg_seconds` | integer | No | denormalized average flight duration (recorded pigeons only) |
| `returned_count` | integer | Yes | recorded (returned) pigeons, default 0 |
| `like_count` | integer | Yes | denormalized, default 0 (live only) |
| `view_count` | integer | Yes | denormalized, default 0 (live only) |
| `went_live_at` | timestamp | No | when broadcast started |
| `auto_end_at` | timestamp | No | **UTC instant of the owner's next local midnight** — target for the auto-end job (performance §4.1) |
| `ended_at` | timestamp | No | when it ended (auto at midnight or manual) |
| `created_at` | timestamp | Yes | |
| `updated_at` | timestamp | Yes | |
| `deleted_at` | timestamp | No | soft delete (owner delete) |

**Indexes:**
- `(user_id, record_date DESC)` partial WHERE `deleted_at IS NULL` — "My records"
- `(privacy, status)` partial WHERE `privacy='live' AND status='open'` — **the "Live now" source** (tiny hot index); mirrored by the Redis `live_records:active` set
- `(auto_end_at)` partial WHERE `status='open'` — the hourly safety sweep for the midnight auto-end

**Rules:**
- **Private** records are visible to the owner only; **live** records are visible to the owner's followers + carry like/view counts.
- Going live: set `privacy='live'`, `went_live_at=NOW()`, compute `auto_end_at` from `users.timezone`, add id to Redis `live_records:active`, enqueue the delayed `live-record-auto-end` job (`jobId=record-end:{id}`), emit `record.live_started` to followers + `follower-fanout` notification.
- **Auto-end (midnight, owner-local):** the job (or hourly sweep) sets `status='completed'`, `ended_at=NOW()`, removes from `live_records:active`, emits `record.live_ended`, notifies followers. **Record is kept** (R16). Un-returned pigeons were never recorded (R17) — the "not returned" count = `total_pigeons − returned_count`.
- Switching `private ↔ live` later: allowed? → still open (R11 / open-questions Q10). Schema supports it; the service gate is TBD.

---

## Table: `record_pigeons`

One row per **returned** pigeon (same "not returned = no row" rule as tournaments).

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `record_id` | UUID | Yes | FK `personal_records` (cascade) |
| `pigeon_name` | string | Yes | |
| `landing_time` | timestamp | Yes | UTC instant returned |
| `duration_seconds` | integer | Yes | `= landing_time − personal_records.release_at`, computed on insert |
| `created_at` | timestamp | Yes | |
| `updated_at` | timestamp | Yes | |

**Indexes:** `(record_id, created_at)` — the landings list.

**Rules:**
- Owner-only add/edit/delete (also while live — each new landing streams out).
- On insert/edit/delete, **recompute** `personal_records.total_avg_seconds` + `returned_count` in the same transaction; if live, emit `record.update` (socket) to `record:{id}` and `record.counts` where relevant.
- Count cap: `returned_count ≤ total_pigeons`.

**Cascade:** cascade on record delete.

---

## Table: `record_likes`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `record_id` | UUID | Yes | FK (cascade) |
| `user_id` | UUID | Yes | FK `users` (cascade) |
| `created_at` | timestamp | Yes | |

**Indexes:** unique `(record_id, user_id)`. Hard delete on unlike; `like_count` atomic; `record.counts` debounced 2s.

---

## Table: `record_views`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `record_id` | UUID | Yes | FK (cascade) |
| `user_id` | UUID | Yes | FK `users` (cascade) |
| `created_at` | timestamp | Yes | |

**Indexes:** unique `(record_id, user_id)` — one view per user; `view_count` denormalized.

---

## Application-layer patterns
- **"Live now" list** = members of Redis `live_records:active` (hydrate ids → records), or the partial index as fallback. Never a full-table scan.
- **Average** recompute lives in one `recomputeRecordStats(record_id)` service method (same shape as tournaments).
- **Followers** of the owner (`follows` §1) are the audience for `record.live_started` / `record.live_ended` and notifications.

---

*Section 5: Personal Records · v0.1 · 2026-10-03*
