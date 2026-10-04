# PigeonFly — Performance, Realtime & Runtime Topology

> **Why this doc exists:** PigeonFly is **live-first** — tournament standings, live personal records, like/view counts, chat, and notifications must all feel instant, and every REST endpoint must stay fast under load. This file locks how the backend is split into processes, how Socket.io / Redis / BullMQ are used, and the performance rules every endpoint follows.
>
> Pattern adapted from the Talksy backend (`runtime-topology.md` + `api/index.md`). Stack: NestJS · PostgreSQL/Prisma · Socket.io · Redis (`ioredis`) · BullMQ.
> **Last updated:** 2026-10-03 · **Version:** 1.0

---

## 1. Two bugs this design prevents

### Bug A — Socket.io broadcasts reach only some users
Socket.io keeps room membership **in the memory of the process that owns the connection**. With 2+ API instances, a user connected to instance 1 and a user connected to instance 2 are in different copies of `tournament:{id}` — an emit from instance 1 never reaches the instance-2 user. **Every live feature breaks partially and silently** (standings, counts, live records, DMs, notifications).

**Fix (locked):** `@socket.io/redis-adapter` on **every** API process (two separate ioredis connections — pub + sub). Wire it in all environments so the path is always exercised; **never run 2+ API instances without it.**

### Bug B — Scheduled jobs run once per process
If cron registration lives in the API process and the API runs 2 instances, every cron fires twice. For the **live-record midnight auto-end** and cleanup crons, a double run corrupts data.

**Fix (locked):** BullMQ **workers and schedulers never run in an API process.** Exactly **one** scheduler registers repeatable jobs.

---

## 2. Process roles (locked)

One codebase, role chosen at boot by `PROCESS_ROLE`.

| Role | `PROCESS_ROLE` | Instances | Does | Must NOT |
|------|----------------|-----------|------|----------|
| **API** | `api` | 2+ (scales with users) | HTTP routes · Socket.io gateway · **enqueues** jobs | never processes jobs, never registers crons |
| **Worker** | `worker` | 1+ (scales with queue depth) | processes BullMQ jobs (push, exports, media, fan-out, cleanup) | never binds HTTP, never accepts sockets |
| **Scheduler** | `scheduler` | **exactly 1** | registers repeatable/cron jobs only | never processes jobs, never serves HTTP |

Scheduler may collapse into one worker via `SCHEDULER_ENABLED=true` on exactly one instance — the "exactly one" must hold in every env (incl. staging).

`AppModule` (API) and `WorkerModule` share all feature modules — same use cases run in both; only the entry surface differs.

**Why separate:** a slow job (video transcode, Excel export, follower fan-out) must not block the event loop serving live standings; API scales on users, workers on queue depth; a crashing worker must not drop live sockets.

---

## 3. Socket.io channels (rooms)

Single namespace `/`. Rooms per concern. Clients join by what they're **viewing** (viewport-scoped) or their **identity** (always). JWT passed in the handshake (`auth.token`); on connect the socket auto-joins `user:{id}`.

### Rooms

| Room | Membership | Purpose |
|------|-----------|---------|
| `user:{user_id}` | auto on connect | notifications, bell count, DM delivery, message requests, live-started alerts, presence/suspension events to the user |
| `user:{user_id}:presence` | `presence.subscribe` while watching a user (chat header, inbox row, profile) | that user's online / last-seen |
| `tournament:{id}` | `tournament.subscribe` on the tournament detail screen | standings changed (new day result / participant) |
| `tournament:{id}:counts` | joined with the above | live **like / view** counts (debounced) |
| `record:{id}` | `record.subscribe` on a live record (watching someone fly) | **new landing** streamed (pigeon · land time · avg · totals) |
| `record:{id}:counts` | joined with the above | live like / view counts on the live record |
| `post:{id}:counts` | `post.counts.subscribe` when a post enters the viewport | like / share / view counts |
| `feed:global` | `feed.subscribe` on Home feed | "new posts" indicator |
| `chat:{conversation_id}` | on chat open | messages, typing, recording, read receipts |

`subscribe`/`unsubscribe` are **room membership on the one socket**, not new connections (join is O(1), empty rooms discarded). Each is acknowledged `{ ok: true|false }`; `false` = not authed or bad id → re-subscribe on next change.

### Events server → client

| Event | Room | Payload (illustrative) |
|-------|------|------------------------|
| `notification.new` | `user:{id}` | `{ notification_id, type, actor_preview, entity_ref, created_at }` |
| `notification.bell_count` | `user:{id}` | `{ unread_count }` |
| `tournament.update` | `tournament:{id}` | `{ tournament_id, day, reason: 'day_results'|'participant_added', standings_version }` — client merges or refetches that day |
| `tournament.counts` | `tournament:{id}:counts` | `{ tournament_id, like_count, view_count }` (debounced 2s, **full snapshot**) |
| `record.update` | `record:{id}` | `{ record_id, pigeon_name, land_time, avg, landed_count, total_count, total_avg }` |
| `record.counts` | `record:{id}:counts` | `{ record_id, like_count, view_count }` (debounced 2s) |
| `record.live_started` | `user:{followerId}` | `{ record_id, owner_preview }` — powers "Live now" + notification |
| `record.live_ended` | `record:{id}` + followers | `{ record_id, final_avg, not_returned }` (also fired by the midnight auto-end) |
| `post.counts` | `post:{id}:counts` | `{ post_id, like_count, share_count, view_count }` (debounced 2s) |
| `post.new` | `feed:global` | `{ post_id, author_id }` — client fetches only if it passes the active feed |
| `message.new` | `chat:{id}` + `user:{recipientId}` | full message row |
| `message.request_new` | `user:{recipientId}` | `{ conversation_id, sender_preview, first_message_preview }` — TikTok-style request |
| `message.deleted` | `chat:{id}` | `{ message_id }` |
| `chat.typing` / `chat.recording` | `chat:{id}` | `{ user_id, started_at }` |
| `chat.read` | `chat:{id}` | `{ user_id, last_read_message_id, last_read_at }` — drives ✓✓→blue |
| `user.presence` | `user:{id}:presence` | `{ user_id, is_online, last_seen_at }` |
| `user.block_state_changed` | `user:{id}` | multi-device block sync |

### Events client → server
`feed.subscribe/unsubscribe` · `tournament.subscribe/unsubscribe {tournament_id}` · `record.subscribe/unsubscribe {record_id}` · `post.counts.subscribe/unsubscribe {post_id}` · `chat.typing.start/stop {conversation_id}` · `chat.recording.start/stop {conversation_id}` · `presence.subscribe/unsubscribe {user_id}`.
Most writes go via REST — only true realtime signals use socket events.

### Debounced count emits (the "fast counts" rule)
`tournament.counts`, `record.counts`, `post.counts` are capped at **1 emit per entity per 2s** via an atomic Redis claim `SET throttle:<kind>_counts:{id} 1 NX EX 2` — concurrent likes across instances collapse to one emit. Payload is always a **full snapshot** (client replaces, never merges). If Redis is down the emit is skipped (not retried); the REST response still carries authoritative counts and the next change past the window re-syncs everyone.

### Presence (online + last seen)
Source of truth is **Redis, never a column**: `presence:conn:{user_id}` (set of live socket ids — **online ⇔ non-empty**, multi-device-correct) + `presence:{user_id}` (last-seen epoch ms, 3-min sliding TTL, refreshed on heartbeat). Offline flip uses a **grace window** (`presence:disconnect_pending`, ~30–45s) so flaky mobile sockets don't flicker the dot; on real offline, write `users.last_active_at` and emit. Privacy + **block gating**: `presence.subscribe` refused when a block exists either way.

---

## 4. BullMQ job queues

Every async task runs through a named queue. Workers are stateless → scale by adding processes.

### Realtime async (triggered by API/socket events)
| Queue | Trigger | Purpose | Priority |
|-------|---------|---------|----------|
| `push-send` | notification INSERT | FCM push respecting §settings prefs; **skip if recipient online within 30s** (delivers on next foreground). 5 retries, exp backoff | high |
| `dm-push-send` | message INSERT | DM push (no notification row); respects block + request rule | high |
| `message-request-push` | first-message request | push for a new chat request | high |
| `follower-fanout` | tournament update · record goes live · new post by a followed user | fan out notifications / `record.live_started` to followers (chunked — a 10k-follower organizer must not stall the loop) | default |
| `media-process` | `POST /v1/uploads` | image resize (sharp), video thumbnail/transcode (ffmpeg), voice-note normalize | default |
| `export-generate` | share → Excel/PDF/Image | build the file in the worker, upload to R2, return/push the link (heavy — never inline on the request) | default |
| `profanity-check` | post/comment/message/name INSERT | server-side backstop → auto-hide or reject | default |

### Scheduled (cron) — registered by the **scheduler only**
| Queue | Trigger | Purpose |
|-------|---------|---------|
| **`live-record-auto-end`** | **per-record delayed job** scheduled at each owner's **next local midnight** (`jobId=record-end:{record_id}`), + an **hourly safety sweep** backstop | end every live record at **00:00 local time**: `live → completed`, mark un-landed pigeons **"Not returned"**, emit `record.live_ended`, notify followers, persist (never delete — stays in My Records). See §4.1 |
| `uploads-cleanup` | hourly | delete uploads not consumed within 1h |
| `notification-cleanup` | `0 3 * * *` | retention (30d), dangling polymorphic refs |
| `media-cleanup` | `0 3 * * *` | orphaned R2 media (soft-deleted content) |
| `denorm-counter-recompute` | nightly + on-demand | recompute follower counts, post/tournament counters, averages; cheap on-demand triggers on write |

### 4.1 The midnight live-record auto-end (per-user local time)
Because the cutoff is **each user's own local midnight** (locked product rule R15), a single UTC cron is wrong. Approach:
- When a record goes live, **enqueue a BullMQ delayed job** targeting that owner's next local 00:00 (from `users.timezone`), with deterministic `jobId=record-end:{record_id}` so a re-enqueue is deduped.
- An **hourly safety sweep** ends any live record whose owner's local time is already ≥ next-midnight (covers timezone changes, missed jobs, server restarts).
- The job **re-checks inside the transaction** (`status='live' AND local-midnight passed`) before ending — never trusts the payload alone (idempotent, at-least-once safe).

### Job safety (locked)
Idempotent processors (same end state if run twice) · destructive/stateful jobs re-check their condition **inside the transaction** · deterministic `jobId` for dedup · high-priority pool for push/requests/live events so a backlog of exports/cleanup never delays a notification · failed jobs after final retry → Sentry (name + payload minus PII).

---

## 5. Redis key inventory

| Key | Type | TTL | Purpose |
|-----|------|-----|---------|
| `presence:conn:{user_id}` | Set | — (members removed on disconnect) | **authoritative online** signal |
| `presence:{user_id}` | String (ms) | 3 min sliding | last-seen; DM push "online within 30s" gate |
| `presence:disconnect_pending:{user_id}` | String | ~30–45s | offline grace flip |
| `live_records:active` | Set of record_ids | — | powers the **"Live now"** list fast (no table scan) |
| `throttle:tournament_counts:{id}` | String | 2s | debounce `tournament.counts` |
| `throttle:record_counts:{id}` | String | 2s | debounce `record.counts` |
| `throttle:post_counts:{id}` | String | 2s | debounce `post.counts` |
| `typing:{conversation_id}:{user_id}` | String | 5s | typing indicator |
| `recording:{conversation_id}:{user_id}` | String | 3s | voice-note recording indicator |
| `rate_limit:posts:{user_id}` | Counter | 1h | post creation cap |
| `rate_limit:messages:{user_id}` | Counter | 1m / 1h | DM anti-spam |
| `rate_limit:reports:{user_id}` | Counter | 1h | report anti-abuse |
| `rate_limit:api:{user_id}:{bucket}` | Counter | 1m | general per-endpoint-group limit |
| `session:{jti}` | Hash | 1h | cached user context (id, role, is_suspended) — avoids a `users` read per request |
| `user_sessions:{user_id}` | Set | — | tracks a user's `session:*` keys for bulk logout |
| `tournament:standings:{id}:{day}` | String (JSON) | short / invalidate on write | hot standings cache (optional, if compute-on-read is heavy) |
| `blocked_by_me:{user_id}` / `blocked_me:{user_id}` | Set | until invalidation | block cache (Phase 2 — MVP queries DB) |
| `idemp:{key}` | Hash | 24h | idempotency-key → first response |
| `reference_data:etag:{table}` | String | until change | ETag for reference-data endpoints |

---

## 6. Making every endpoint fast

| Rule | Detail |
|------|--------|
| **Cursor pagination everywhere** | feeds, chat scrollback, standings lists, inbox. Opaque base64 `{sort_col,id}` cursor, `limit` default 20 / max 100. New items arrive via sockets, not re-fetch. Offset only in the admin panel. |
| **Counts via sockets, not polling** | like/view/comment counts stream over the debounced count rooms; clients never poll an endpoint for them. |
| **Denormalized counters** | follower/following, post counts, tournament participant count, averages stored as columns, incremented on write, **recomputed nightly** by cron to self-heal drift. Never `COUNT(*)` on a hot read path. |
| **No N+1** | hydrate lists in batched queries (one query for rows + one for related, mapped in memory) — never a query per row. |
| **Indexes** | every FK + every sort column (`created_at`); composite indexes for feed (`author_id, created_at`), standings (`tournament_id, day, avg`); GIN for full-text (user/tournament search). |
| **Prisma pool sizing** | pool is **per process**; `instances × pool_size ≤ Postgres max_connections`. Set `connection_limit` explicitly with total process count in mind (a real production trap). |
| **Transactions** | multi-table writes (create tournament + participants; record + pigeons; message + conversation) run in one Prisma `$transaction`. |
| **Hot-path caching** | reference data (ETag + Redis), standings (short-TTL cache invalidated on new result), session context (`session:{jti}`). Cache only what's read far more than written. |
| **Response envelope + request id** | `{ data, meta }`; `X-Request-Id` on every request for tracing; p95 latency tracked per route. |
| **Rate limiting at the edge + app** | Cloudflare WAF + Redis sliding-window per endpoint bucket; `429` with `Retry-After`. |
| **Media off the request path** | uploads go straight to R2; resize/transcode/thumbnail happen in `media-process` worker; the request returns an `upload_id` immediately. |
| **Exports off the request path** | Excel/PDF/image built in `export-generate` worker, not during the share tap. |

---

## 7. Graceful shutdown (SIGTERM — deploy / autoscale)

**API:** fail `/v1/health` immediately (drain from LB) → let in-flight HTTP finish (bounded 15s) → notify sockets so clients reconnect deliberately (live standings/records/chat) → close Redis + Prisma last. Enable `app.enableShutdownHooks()`.

**Worker:** stop pulling jobs → let in-flight jobs finish (`worker.close()`) → BullMQ stalled-job recovery re-queues anything unfinished (safe because jobs are idempotent).

---

## 8. Health & scaling signals

- **Liveness** (cheap, no deps) → restart on failure. **Readiness** (DB + Redis ping) → drain from LB on failure, **not** restart.
- Workers expose no port — monitored via **BullMQ queue depth + job failure rate**.

| Symptom | Scale | Not |
|---------|-------|-----|
| HTTP p95 rising, API CPU high | API instances | workers |
| BullMQ depth / job latency rising (exports, push, fan-out) | worker instances | API |
| Socket count near FD limits | API instances | workers |
| DB connection saturation | pooling / read replica — **adding processes makes it worse** | more processes |

---

*performance-and-realtime.md · v1.0 · 2026-10-03 · pattern from Talksy runtime-topology + api/index*
