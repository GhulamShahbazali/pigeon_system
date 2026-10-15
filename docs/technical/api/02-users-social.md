[← API index](index.md) · schema [§1](../schema/01-users-social.md)

# Section 2: Users, Profile & Social

Profile, follow graph, blocks. `email`/private fields never returned.

## Profile
| Method · Path | Auth | Body → Response | Notes |
|---------------|------|-----------------|-------|
| `GET /v1/users/{id}` | session | → `{ user, stats:{follower_count,following_count,tournament_count,post_count}, is_following, is_blocked }` | public profile; soft-delete/block filtered. Drives the mobile profile screen (name, @username, photo, city, stats, Follow state) |
| `GET /v1/users/{username}` | session | → same | by username |
| `PATCH /v1/me` | session | `{ display_name?, bio?, city?, photo_upload_id? }` → `{ user }` | edit own profile; profanity backstop |
| `GET /v1/users/{id}/posts` | session | `?limit` → `{ data:[post] }` | **implemented** — that user's posts, newest first, with the viewer's `is_liked`. Powers profile "Posts" (own + others) |
| `GET /v1/tournaments/by-user/{userId}` | session | `?limit` → `{ data:[card] }` | **implemented** — that user's tournaments (see [03-tournaments.md](03-tournaments.md)). Powers profile "Tournaments" |
| `GET /v1/me/records` | session | → `{ data:[record] }` | own records — powers profile "My Records". (Another user's public/live records endpoint is not implemented yet.) |

## Follow
| Method · Path | Auth | → | Notes |
|---------------|------|---|-------|
| `POST /v1/users/{id}/follow` | session | `204` | insert `follows`; `follower/following_count` atomic; → notification §7; `409` already |
| `DELETE /v1/users/{id}/follow` | session | `204` | hard delete |
| `GET /v1/users/{id}/followers` · `/following` | session | cursor → `{ data:[…] }` | |

## Block
| Method · Path | Auth | → | Notes |
|---------------|------|---|-------|
| `POST /v1/users/{id}/block` | session | `204` | insert `blocks`; removes any follow both ways; stops chat delivery instantly; emits `user.block_state_changed` |
| `DELETE /v1/users/{id}/block` | session | `204` | hard delete |
| `GET /v1/me/blocks` | session | → `{ data:[…] }` | |

**Touches:** `BlockFilter` helper (every content query). Sockets: `user.block_state_changed`. Queue: `push-send` (new follower).
