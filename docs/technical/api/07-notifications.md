[← API index](index.md) · schema [§7](../schema/07-notifications.md)

# Section 7: Notifications

| Method · Path | Auth | → | Notes |
|---------------|------|---|-------|
| `GET /v1/notifications` | session | cursor → `{ data:[notification] }` | hydrated (actors, entity preview); block/mute filtered |
| `GET /v1/notifications/unread-count` | session | → `{ unread_count }` | bell badge |
| `POST /v1/notifications/read-all` | session | `204` | mark all read |
| `POST /v1/notifications/{id}/read` | session | `204` | mark one |

**Emit contract (internal):** one `NotificationsService.emit({recipient_id, type, entity})` that every module calls — inserts the row, upserts `notification_actors`, emits `notification.new` + `notification.bell_count` to `user:{id}`, enqueues `push-send` (gated: skip if recipient online within 30s; respects §8 prefs). Types: `tournament_created`, `participant_added`, `tournament_day_results`, `new_follower`, `content_like`, `record_live_started`, `message_request`, moderation. Aggregation collapses repeated like/follow. Moderation-actor shows "PigeonFly Team".
**Touches:** sockets `notification.new`, `notification.bell_count`. Queue `push-send`. Retention cron `notification-cleanup`.
