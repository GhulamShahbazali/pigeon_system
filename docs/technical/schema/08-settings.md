[← Back to schema index](index.md)

---

# Section 8: Settings

> Per-user preferences, one row per table, created with defaults at signup. Served as one combined `GET /v1/me/settings`; one PATCH per table.

## Table: `user_notification_preferences`
| Column | Type | Req | Notes |
|--------|------|-----|-------|
| `user_id` | UUID | Yes | PK + FK `users` (cascade) |
| `push_enabled` | boolean | Yes | master switch, default true |
| `notify_new_follower` | boolean | Yes | default true |
| `notify_likes` | boolean | Yes | default true |
| `notify_followed_tournament` | boolean | Yes | default true |
| `notify_live_record` | boolean | Yes | default true |
| `notify_messages` | boolean | Yes | default true |
| `updated_at` | timestamp | Yes | |

Read by `push-send` before sending.

## Table: `user_privacy_preferences`
| Column | Type | Req | Notes |
|--------|------|-----|-------|
| `user_id` | UUID | Yes | PK + FK (cascade) |
| `private_account` | boolean | Yes | default false |
| `show_online_status` | boolean | Yes | default true (presence projection, §performance) |
| `updated_at` | timestamp | Yes | |

## Table: `user_app_preferences`
| Column | Type | Req | Notes |
|--------|------|-----|-------|
| `user_id` | UUID | Yes | PK + FK (cascade) |
| `language_code` | string | Yes | `ur` \| `hi` \| `ar` \| `en` (mirrors `users.language_code`) |
| `updated_at` | timestamp | Yes | |

---

*Section 8: Settings · v0.1 · 2026-10-03*
