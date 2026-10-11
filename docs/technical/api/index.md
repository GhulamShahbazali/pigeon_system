# PigeonFly — API Design (Index)

> **Purpose:** the REST + realtime contract for the backend, consumed by the **mobile app** and **admin panel**. Companion to [`../schema/index.md`](../schema/index.md) (what's stored) and [`../performance-and-realtime.md`](../performance-and-realtime.md) (Socket.io rooms/events · Redis keys · BullMQ queues — **not duplicated here**).
> **Pattern:** follows the Talksy API docs. **Last updated:** 2026-10-10 · **Version:** 0.2 (added §10 Discovery & Search)

---

## How to use this doc
One file per feature area — **don't read them all.** This index (conventions + structure) is shared context worth reading once; endpoint files are read on-demand.

| I'm working on… | Read (+ this index) |
|-----------------|----------------------|
| Sign-in, sessions, onboarding | [01-auth.md](01-auth.md) |
| Profile, follow, block | [02-users-social.md](02-users-social.md) |
| Tournaments, participants, flights, follow/like/share | [03-tournaments.md](03-tournaments.md) |
| Posts, likes, shares, hides, reports | [04-posts.md](04-posts.md) |
| Personal records (private/live), landings | [05-records.md](05-records.md) |
| Chat — inbox, requests, send, receipts | [06-messages.md](06-messages.md) |
| Notifications feed | [07-notifications.md](07-notifications.md) |
| Settings | [08-settings.md](08-settings.md) |
| Reports, suspensions, admin panel | [09-moderation-admin.md](09-moderation-admin.md) |
| Find friends + search (users / tournaments / records / chats) | [10-discovery.md](10-discovery.md) |
| Bots / liveness engine controls (admin) | [11-bots-admin.md](11-bots-admin.md) |

Socket.io events, Redis keys, and BullMQ queues are **catalogued once** in `../performance-and-realtime.md` (§3–§5). Each endpoint file lists which of those it touches.

---

# Conventions

## Base URL & versioning
- **Base:** `https://api.pigeonfly.app/v1` (dev `http://localhost:3000/v1`)
- Versioning in the path (`/v1`). Breaking changes → `/v2`.
- `Content-Type: application/json; charset=utf-8` (uploads = `multipart/form-data`).

## Auth
Every route except `/v1/auth/*` and `/v1/health`:
```
Authorization: Bearer <session_jwt>
```
Socket.io: `io('wss://api.pigeonfly.app', { auth: { token: '<session_jwt>' } })`.

## Response envelope
**Success:** `{ "data": <payload>, "meta": { … optional } }`
**Error:** `{ "error": { "code": "snake_case", "message": "…", "details": { … }, "request_id": "uuid" } }`

### Standard error codes
| HTTP | `code` | Meaning |
|------|--------|---------|
| 400 | `invalid_request` | malformed body/query — `details.fields` has per-field errors |
| 401 | `unauthenticated` | missing/invalid/expired JWT |
| 403 | `forbidden` | not allowed (e.g. not the organizer) |
| 403 | `suspended` | account suspended — `details.suspended_until` |
| 403 | `blocked` | blocked relationship |
| 404 | `not_found` | missing or soft-deleted from this user's view |
| 409 | `conflict` | already following/liked, etc. |
| 422 | `unprocessable` | semantic failure (profanity, age, **`pigeon_cap_exceeded`**, **`message_request_pending`**) |
| 429 | `rate_limited` | see `Retry-After` |
| 500 | `internal_error` | server bug — trace via `request_id` |
| 503 | `service_unavailable` | DB/Redis down |

Feature codes are listed in their section file.

## Pagination
**Cursor (default)** — feeds, lists, chat:
```
GET …?cursor=<opaque>&limit=20   → { data:[…], meta:{ next_cursor, has_more } }
```
Opaque base64 of `{sort_col,id}`; `limit` default 20 / max 100. Newer items arrive via sockets, not re-fetch.
**Offset** — admin only: `?offset=&limit=` → `meta:{ offset, limit, total }`.

## Timestamps / enums / codes
- ISO 8601 UTC in responses; accepted in any tz (converted to UTC). "time ago" is client-side.
- **Durations** returned as `*_seconds` integers (client formats `7h 40m`); **averages** as `avg_seconds`. Never a pre-formatted string.
- Enums lowercase `snake_case`. `language_code` ISO 639-1 (`ur/hi/ar/en`); `country_code` ISO 3166-1 alpha-2.

## Idempotency
`Idempotency-Key: <uuid>` on side-effectful POSTs → first response cached 24h (Redis `idemp:{key}`). Supported on: `POST /v1/posts`, `POST /v1/tournaments`, `…/flights`, `POST /v1/messages`, `POST /v1/reports`.

## Rate limiting
Headers `X-RateLimit-{Limit,Remaining,Reset}` on every response; `429` + `Retry-After`. Buckets: posts 60/h, messages 30/min→200/h, reports 20/h, default 100/min per endpoint group.

## File uploads
`POST /v1/uploads` (multipart): `file` + `purpose` ∈ `participant_photo` \| `tournament_cover` \| `post_image` \| `profile_photo` \| `chat_image` \| `chat_video` \| `voice_note`. Returns `{ upload_id, url, expires_at? }`; referenced in later create calls. Processing (resize/thumbnail/transcode) runs in the `media-process` worker. Unused uploads cleaned hourly.

---

# Backend structure (NestJS)

Feature modules map 1:1 to schema sections (see `backend/docs/architecture.md`). Layered per module: **Controller** (Zod + guards, no logic) → **UseCase** (business, transactions, emits, enqueues) → **Repository** (Prisma). Cross-module via a use case, never another module's repository.

## Authentication flow (Google → backend JWT)
```
1. Client: Firebase Sign-In (Google/Apple) → Firebase ID token
2. POST /v1/auth/session { id_token, device_id, device_type, app_version, fcm_token? }
3. Server: Firebase Admin verifies → find user by (auth_provider, auth_provider_id)
   • new user  → 202 { onboarding_required: true, temp_token }   (30-min onboarding scope)
   • returning → issue session JWT → 200 { user, session_token, expires_at }
4. (new) POST /v1/auth/complete-signup  Bearer <temp_token>
        { display_name, username, language_code, profile_photo_upload_id? }
   → BEGIN TXN: insert users (+ timezone from device, country from IP) + default settings rows → COMMIT
   → issue session JWT
```
**JWT:** HS256/RS256; claims `sub`(user_id), `sid`(user_devices.id), `role`, `scope`(`session`/`onboarding`), `jti`, `exp`. Session 7d; onboarding 30m. No refresh token (re-auth via Firebase). Session cached in Redis `session:{jti}` (1h). Logout deletes the device row + cache.

## Cross-cutting pipeline (evaluation order)
```
request-id → rate-limit guard → auth guard (JWT + Redis session) →
suspension guard (@RequiresActive on writes) → roles guard (@Roles('superadmin') on admin) →
Zod validation pipe → [handler: use case → BlockFilter in queries → profanity backstop] →
exception filter (→ error envelope, Sentry) → response-envelope interceptor → logging (no PII)
```

---

*api/index.md · v0.2 · 2026-10-10 · pattern from Talksy API docs. Realtime/Redis/BullMQ inventory → ../performance-and-realtime.md*
