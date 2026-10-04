# PigeonFly — Database Schema (Index)

> **Purpose:** Complete conceptual DB schema — the single source of truth for every table, column, relationship, and index. Conceptual (column names + types, not raw SQL/Prisma); developers generate the Prisma schema from this.
> **Pattern:** follows the Talksy schema docs. Read with [`../performance-and-realtime.md`](../performance-and-realtime.md) (Redis/sockets/queues) and [`../../product/locked-decisions.md`](../../product/locked-decisions.md) (behaviour).
> **Last updated:** 2026-10-03 · **Version:** 0.1 (in progress)

---

## How to use this doc
One file per section — **don't read every file for every task.** Find the section(s) relevant to your work and read only those + this index.

| I'm working on… | Read |
|-----------------|------|
| Users, auth/devices, follows, blocks | [01-users-social.md](01-users-social.md) |
| Countries, languages | [02-reference-data.md](02-reference-data.md) |
| Tournaments, participants, days, pigeon flights, follow/like/view | [03-tournaments.md](03-tournaments.md) |
| Posts, likes, views, shares, hides | [04-posts.md](04-posts.md) |
| Personal records (private/live), record pigeons | [05-records.md](05-records.md) |
| Chat — conversations, messages, media, requests, receipts | [06-messages.md](06-messages.md) |
| Notifications | [07-notifications.md](07-notifications.md) |
| User settings (notifications/privacy/app) | [08-settings.md](08-settings.md) |
| Reports, suspensions, admin audit | [09-moderation.md](09-moderation.md) |

---

## Table of Contents
1. **Users & Social** — `users`, `user_devices`, `follows`, `blocks`
2. **Reference Data** — `countries`, `languages`
3. **Tournaments** — `tournaments`, `tournament_days`, `tournament_participants`, `pigeon_flights`, `tournament_follows`, `tournament_likes`, `tournament_views`
4. **Posts** — `posts`, `post_likes`, `post_views`, `post_shares`, `post_hides`
5. **Personal Records** — `personal_records`, `record_pigeons`, `record_likes`, `record_views`
6. **Messages** — `conversations`, `conversation_participants`, `messages`, `message_media`
7. **Notifications** — `notifications`, `notification_actors`
8. **Settings** — `user_notification_preferences`, `user_privacy_preferences`, `user_app_preferences`
9. **Moderation** — `reports`, `user_suspensions`, `admin_actions`

Module → section mapping mirrors the app modules (Home reads across §3/§4/§5; it owns no tables).

---

## Conventions used throughout

| Convention | Rule |
|------------|------|
| Primary keys | **UUID** (except `countries`/`languages` which use ISO codes) |
| Timestamps | every table has `created_at`; `updated_at` where rows mutate (all times stored **UTC**) |
| Foreign keys | suffixed `_id` (`organizer_id`, `tournament_id`) |
| Soft delete | `deleted_at` (null = active); `users` also has `permanent_delete_at` (grace cleanup) |
| Hard delete | state/engagement rows removed outright (likes, follows, views, blocks) |
| Booleans | default stated explicitly |
| Enums | values listed explicitly, stored lowercase `snake_case` |
| Money/anything | n/a (no payments in MVP) |
| **Durations** | pigeon **flight time** stored as `duration_seconds` (integer) — never a formatted string; UI formats `7h 40m` |
| **Averages** | stored **denormalized** as `avg_seconds` (integer), recomputed in the same transaction as a flight insert/edit/delete (see §3) |
| Counters | `like_count` / `view_count` / `follower_count` denormalized integers, updated **atomically in the write transaction**, self-healed nightly by `denorm-counter-recompute` |

---

## Soft vs hard delete reference

**Soft delete (`deleted_at`) — rows referenced elsewhere:**
- `users` (30-day grace → `permanent_delete_at` cron)
- `tournaments`, `tournament_participants` (keep so historical links/averages resolve)
- `posts`
- `personal_records`
- `conversations`, `messages`

**Hard delete (row removed):**
- `follows`, `tournament_follows`, `blocks` (state)
- `tournament_likes`, `post_likes`, `record_likes` (unlike)
- `*_views` (dedup rows; cascade on parent delete)
- `post_hides`, `post_shares`
- `user_devices` (on logout)
- `pigeon_flights`, `record_pigeons` (cascade on parent delete; owner may delete a flight = removes the row → average recomputes)
- `notifications` (30-day retention cron)
- `message_media` references expire (R2 cleanup)

**Kept for audit (until the user is permanently deleted):**
- `reports`, `user_suspensions`, `admin_actions` (moderator FKs SET NULL)

---

## Extra best practices (beyond Talksy — specific to PigeonFly)

1. **Never store a formatted time or average as text.** Store `landing_time` (timestamptz) + `duration_seconds` (int). Compute averages from seconds; format only in the UI. (Mixing clock-time and duration is the #1 source of bugs here.)
2. **`duration_seconds = landing_time − tournament fly_time of that day`**, computed **once on insert** and stored — so ranking/averages are plain integer math (fast, index-friendly), not per-read time arithmetic.
3. **Averages are denormalized and recomputed in the write transaction**, not on every read: `tournament_participants.overall_avg_seconds`, per-day average (in `tournament_days` or a small `participant_day_stats`), `personal_records.total_avg_seconds`. A read never runs `AVG()` on a hot path.
4. **Ranking is `ORDER BY overall_avg_seconds DESC`** (higher = winner). Index `(tournament_id, overall_avg_seconds DESC)` for instant standings.
5. **"Not returned" = no row.** A pigeon that doesn't return is simply never inserted, so it never affects the average (denominator = recorded flights). The "not returned" count shown in the UI = `pigeon_count − recorded_flights_that_day`.
6. **Owner timezone drives the midnight auto-end** — `users.timezone` (IANA, e.g. `Asia/Karachi`) + `personal_records.auto_end_at` (UTC instant of the owner's next local midnight). The BullMQ delayed job reads this (see performance-and-realtime §4.1).
7. **Chat ticks are derived, not a per-message flag soup:** `messages.created_at` = sent; delivery/read come from `conversation_participants.last_read_message_id` + a lightweight delivered marker — a blocked recipient never gets the delivered marker, so the sender stays on a single ✓ naturally.
8. **Message request = `conversations.status`** (`pending` → `accepted`), not a separate table. Until `accepted`, the sender can insert **one** message (enforced in the service + a partial unique guard).
9. **Partial indexes** on `deleted_at IS NULL` for every feed/list query, and `WHERE status='live'` for the Live-now list — keep hot indexes small.
10. **One Prisma `$transaction` per multi-table write** (tournament + days + participants; record + pigeons; message + media + conversation bump) — partial writes corrupt averages/counters.

---

*schema/index.md · v0.1 · 2026-10-03 · pattern from Talksy schema docs*
