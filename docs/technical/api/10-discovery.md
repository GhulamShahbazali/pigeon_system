[← API index](index.md) · schema [§1](../schema/01-users-social.md) · [§3](../schema/03-tournaments.md) · [§5](../schema/05-records.md) · [§6](../schema/06-messages.md)

# Section 10: Discovery & Search

TikTok-style **Find friends** + per-screen **search**. **Read-only** — no new tables, no new writes: result rows reuse Follow (§2), Message (§6). Every query runs the `BlockFilter` (blocked either-way excluded) and hides suspended/soft-deleted users.

## Common query params
`q` **required**, trimmed, 1–80 chars (empty → `400 invalid_request`, `details.fields.q`). `limit` default 20, max 50. Case-insensitive; `@username` prefix is matched against `username`, free text against `display_name` + `username`.

## Find friends
| Method · Path | Auth | Body → Response | Notes |
|---------------|------|-----------------|-------|
| `GET /v1/discovery/suggestions?limit=` | session | → `{ data:[ user_card ] }` | people you don't follow yet, ordered by `follower_count ↓, last_active_at ↓`; self + followed + blocked excluded; `is_following` always `false` |

## Search (one component, per-screen endpoint)
| Method · Path | Auth | → | Powers screen | Notes |
|---------------|------|---|---------------|-------|
| `GET /v1/search/users?q=&limit=` | session | `{ data:[ user_card ] }` | Find friends · Chat "new chat" | `is_following` set per row → button shows Follow / Following |
| `GET /v1/search/tournaments?q=&limit=` | session | `{ data:[ tournament_result ] }` | Tournaments tab (1b) | title match; order `status ↑, follower_count ↓, created_at ↓` |
| `GET /v1/search/records?q=&limit=` | session | `{ data:[ live_record_result ] }` | Records tab (2b) | **live** records (`privacy=live, status=open`) whose **owner** matches `q`; order `went_live_at ↓` |
| `GET /v1/search/conversations?q=&limit=` | session | `{ data:[ conversation_result ] }` | Chat tab (1b) | your **accepted** conversations whose **other participant** matches `q`; order `last_message_at ↓` |

## Response shapes
```
user_card            { id, display_name, username, photo_url, city, country_code, follower_count, is_following }
tournament_result    { id, title, cover_url, status, num_days, follower_count, link_slug,
                       organizer:{ id, display_name, username, photo_url } }
live_record_result   { id, total_avg_seconds, returned_count, total_pigeons, like_count, view_count,
                       went_live_at, owner:{ id, display_name, username, photo_url } }
conversation_result  { id, status, last_message_at, other_user:{ id, display_name, username, photo_url } }
```

**Touches:** `BlockFilter` helper (all four searches + suggestions). No sockets, no queues, no new error codes (only `invalid_request`). Follow/Message actions on result rows → §2 / §6.
