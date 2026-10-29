[← backend docs](../index.md) · api [§7](../../../docs/technical/api/07-notifications.md) · schema [§7](../../../docs/technical/schema/07-notifications.md)

# Module: `notifications` (global)

**Scope:** The single entry point every module calls to raise a notification: writes the row, emits realtime, enqueues push. `@Global` — exported so any module injects `NotificationsService`.
**Layers:** `notifications.service` (entry point `notify()`) · controller (feed) · workers (`push-send.processor`, `follower-fanout.processor`, `tournament-fanout.processor`).

**Routes**
| Method · Path | Notes |
|---|---|
| `GET /v1/notifications` | feed (with actors) |
| `GET /v1/notifications/unread-count` | bell count |
| `POST /v1/notifications/read-all` · `/:id/read` | mark read |

**`notify(input)`** (`{recipientId, type, entityType, entityId, actorId?, data?}`) → create `notifications` (+ optional `data` JSON, + actor), skip self-notify, compute unread, emit `notification.new` (carries `data`) + `notification.bell_count` to `user:{id}`, enqueue `pushSend`. `feed()` returns `data` so the client renders a granular, localized sentence.
**Queues owned:** `pushSend` (consumes → prefs + devices → FCM; body composed from `type` + `data` + actor name), `followerFanout` (one event → all of an actor's followers, paginated 500/page), `tournamentFanout` (participant/flight event → organizer's followers **and** the tournament's own followers, deduped; resolves `tournament_title` + participant `name`/`contact` once into `data`).
**Sockets:** `notification.new`, `notification.bell_count`.
**Notification types (raised by callers):** `new_follower`, `tournament_created`, `post_created`, `participant_added`, `tournament_day_results`, `record_live_started`, `content_like`, `message_request`, moderation. `data` payloads: `participant_added` `{tournament_title, participant_name}`; `tournament_day_results` `{tournament_title, participant_name, pigeon_name, landing_time, contact_no}`.
**Sync status:** ✅ implemented & verified — `new_follower` + `record_live_started` rows created during smoke; workers boot in the worker process.
**Invariants:** no self-notifications; push respects `UserNotificationPreferences`; `data` holds only what `entity_id` can't convey.
