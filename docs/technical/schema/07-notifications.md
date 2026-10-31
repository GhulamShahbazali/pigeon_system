[← Back to schema index](index.md)

---

# Section 7: Notifications

> Real-time feed + push. Triggers: tournament created / participant added / day results (to followers), new follower, like on your content, live record started, new message request. Delivered via `user:{id}` socket room + FCM (`push-send`, gated by presence).

## Table: `notifications`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `recipient_id` | UUID | Yes | FK `users` (cascade) |
| `type` | enum | Yes | `tournament_created` \| `participant_added` \| `tournament_day_results` \| `new_follower` \| `content_like` \| `record_live_started` \| `message_request` \| moderation types |
| `entity_type` | enum | Yes | `tournament` \| `post` \| `record` \| `user` \| `conversation` |
| `entity_id` | UUID | Yes | polymorphic target (resolved app-side; cleaned by cron if dangling) |
| `is_read` | boolean | Yes | default false |
| `is_aggregated` | boolean | Yes | default false — group "+42 liked" |
| `data` | jsonb | No | optional granular detail that can't be re-derived from `entity_id` alone — e.g. `participant_name`, `pigeon_name`, `landing_time`, `contact_no`, `tournament_title` for a tournament update (whose `entity_id` is the tournament). Rendered app-side + in push. |
| `created_at` | timestamp | Yes | |

**Indexes:** `(recipient_id, created_at DESC)` — feed; `(recipient_id)` partial WHERE `is_read=false` — bell count.
**Rules:** hard delete after 30 days (`notification-cleanup`). Emitting = one `NotificationsService.emit()` entry point that every module calls; it inserts the row, upserts actors, emits `notification.new` + `notification.bell_count`, and enqueues `push-send`. Moderation-actor notifications show "PigeonFly Team". Aggregation collapses repeated like/follow within a window.

## Table: `notification_actors`
Who triggered it (for "A, B and 3 others").
| Column | Type | Req | Notes |
|--------|------|-----|-------|
| `id` | UUID | Yes | PK |
| `notification_id` | UUID | Yes | FK (cascade) |
| `actor_id` | UUID | Yes | FK `users` (cascade) |
| `created_at` | timestamp | Yes | |

Unique `(notification_id, actor_id)`.

---

*Section 7: Notifications · v0.1 · 2026-10-03*
