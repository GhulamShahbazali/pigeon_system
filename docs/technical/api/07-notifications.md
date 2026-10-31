[← API index](index.md) · schema [§7](../schema/07-notifications.md)

# Section 7: Notifications

| Method · Path | Auth | → | Notes |
|---------------|------|---|-------|
| `GET /v1/notifications` | session | cursor → `{ data:[notification] }` | hydrated (actors, entity preview, `data`); block/mute filtered. Each row carries `data` (nullable) with granular detail — `participant_name`, `pigeon_name`, `landing_time`, `contact_no`, `tournament_title` — that `entity_id` alone can't convey; the client composes the localized sentence from `type` + `data` |
| `GET /v1/notifications/unread-count` | session | → `{ unread_count }` | bell badge |
| `POST /v1/notifications/read-all` | session | `204` | mark all read |
| `POST /v1/notifications/{id}/read` | session | `204` | mark one |

**Emit contract (internal):** one `NotificationsService.notify({recipient_id, type, entity_type, entity_id, actor_id?, data?})` that every module calls — inserts the row (with optional `data`), upserts `notification_actors`, emits `notification.new` (includes `data`) + `notification.bell_count` to `user:{id}`, enqueues `push-send` (respects §8 prefs). Types: `tournament_created`, `participant_added`, `tournament_day_results`, `post_created`, `new_follower`, `content_like`, `record_live_started`, `message_request`, moderation. Aggregation collapses repeated like/follow. Moderation-actor shows "PigeonFly Team".
**`data` (optional, per type):** `participant_added` → `{ tournament_title, participant_name }`; `tournament_day_results` → `{ tournament_title, participant_name, pigeon_name, landing_time, contact_no }`. Built once by the fan-out worker (resolves title + participant name/contact) so it's identical for every recipient of the event.
**Push body:** `push-send` composes a specific one-liner from `type` + `data` + the triggering actor's name (e.g. *"Ali's pigeon "Shaheen" landed at 10:42 in "City Cup" · +92…"*), falling back to a generic title per type; a light title lookup covers the follower-fan-out types that carry no `data`.
**Fan-out queues:** `follower-fanout` (`post_created`, `tournament_created` → the actor's followers); `tournament-fanout` (`participant_added`, `tournament_day_results` → the organizer's followers **and** the tournament's own followers, deduped, organizer excluded).
**Touches:** sockets `notification.new`, `notification.bell_count`. Queues `push-send`, `follower-fanout`, `tournament-fanout`. Retention cron `notification-cleanup`.
