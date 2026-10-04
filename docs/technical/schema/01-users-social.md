[← Back to schema index](index.md)

---

# Section 1: Users & Social

> Accounts (Google sign-in → backend JWT), devices/sessions, the follow graph, and blocks. Everything else FKs to `users`.
> Behaviour: `../../product/locked-decisions.md` §1 (A1–A5) + §0.

---

## Table: `users`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `auth_provider` | enum | Yes | `google` \| `apple` |
| `auth_provider_id` | string | Yes | Firebase UID — unique with `auth_provider` |
| `email` | string | No | from provider — **never exposed in any API response** |
| `display_name` | string | Yes | |
| `username` | string | Yes | unique, lowercase |
| `photo_url` | string | No | R2 |
| `bio` | text | No | |
| `city` | string | No | |
| `country_code` | string | No | FK `countries` (detected or chosen) |
| `timezone` | string | Yes | IANA (e.g. `Asia/Karachi`) — **drives the live-record local-midnight auto-end** (§5) |
| `language_code` | string | Yes | app language — `ur` \| `hi` \| `ar` \| `en` (default device locale) |
| `role` | enum | Yes | `user` \| `superadmin` — default `user` |
| `follower_count` | integer | Yes | denormalized, default 0 |
| `following_count` | integer | Yes | denormalized, default 0 |
| `is_suspended` | boolean | Yes | default false (see §9) |
| `last_active_at` | timestamp | No | presence fallback / last-seen (written on offline flip) |
| `created_at` | timestamp | Yes | |
| `updated_at` | timestamp | Yes | |
| `deleted_at` | timestamp | No | soft delete (30-day grace) |
| `permanent_delete_at` | timestamp | No | cron hard-delete after grace |

**Indexes:** unique `(auth_provider, auth_provider_id)`; unique `(username)`; `(country_code)`; GIN `to_tsvector('simple', display_name || ' ' || username)` — user search.

**Rules:** email + any rating/contact never returned in public responses. Soft delete → restore within grace (auth flow). SuperAdmin block sets `is_suspended` + hides content.

---

## Table: `user_devices`

Auth sessions / push tokens (one per device).

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `user_id` | UUID | Yes | FK `users` (cascade) |
| `device_id` | string | Yes | client-stable id |
| `device_type` | enum | Yes | `android` \| `ios` |
| `fcm_token` | string | No | push token |
| `app_version` | string | No | |
| `last_used_at` | timestamp | Yes | |
| `created_at` | timestamp | Yes | |

**Indexes:** unique `(user_id, device_id)`; `(user_id)`.
**Rules:** hard delete on logout (invalidates the session — JWT `sid` references this). FCM token used by `push-send`/`dm-push-send`.

---

## Table: `follows`

The core social edge (user → user). Drives post feed, live-record audience, and profile counts.

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `follower_id` | UUID | Yes | FK `users` (cascade) |
| `followee_id` | UUID | Yes | FK `users` (cascade) |
| `created_at` | timestamp | Yes | |

**Indexes:** unique `(follower_id, followee_id)`; `(followee_id, created_at DESC)` — a user's followers; `(follower_id, created_at DESC)` — who they follow.
**Rules:** hard delete on unfollow; `follower_count`/`following_count` updated atomically; a new follow → notification (§7).

---

## Table: `blocks`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `blocker_id` | UUID | Yes | FK `users` (cascade) |
| `blocked_id` | UUID | Yes | FK `users` (cascade) |
| `created_at` | timestamp | Yes | |

**Indexes:** unique `(blocker_id, blocked_id)`; `(blocked_id)`.
**Rules:** hard delete on unblock. Checked on **every chat send + presence subscribe + content query** (a `BlockFilterService`-style helper returns `blocked_by_me` / `blocked_me` sets; MVP = 2 queries, Phase-2 = Redis set cache). A block stops message delivery instantly (ticks stay single ✓ — §6).

---

*Section 1: Users & Social · v0.1 · 2026-10-03*
