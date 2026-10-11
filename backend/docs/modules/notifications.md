[← backend docs](../index.md) · api [§7](../../../docs/technical/api/07-notifications.md) · schema [§7](../../../docs/technical/schema/07-notifications.md)

# Module: `notifications` (global)

**Scope:** The single entry point every module calls to raise a notification: writes the row, emits realtime, enqueues push. `@Global` — exported so any module injects `NotificationsService`.
**Layers:** `notifications.service` (entry point `notify()`) · controller (feed) · workers (`push-send.processor`, `follower-fanout.processor`).

**Routes**
| Method · Path | Notes |
|---|---|
| `GET /v1/notifications` | feed (with actors) |
| `GET /v1/notifications/unread-count` | bell count |
| `POST /v1/notifications/read-all` · `/:id/read` | mark read |

**`notify(input)`** → create `notifications` (+ actor), skip self-notify, compute unread, emit `notification.new` + `notification.bell_count` to `user:{id}`, enqueue `pushSend`.
**Queues owned:** `pushSend` (consumes → prefs + devices → FCM), `followerFanout` (fan one event to all of an actor's followers, paginated 500/page, each via `notify()`).
**Sockets:** `notification.new`, `notification.bell_count`.
**Notification types (raised by callers):** `new_follower`, `tournament_created`, `record_live_started`, `content_like`, `message_*` (push titles mapped in `push-send.processor`).
**Sync status:** ✅ implemented & verified — `new_follower` + `record_live_started` rows created during smoke; workers boot in the worker process.
**Invariants:** no self-notifications; push respects `UserNotificationPreferences`.
