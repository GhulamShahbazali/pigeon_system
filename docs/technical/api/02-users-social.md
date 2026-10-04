[← API index](index.md) · schema [§1](../schema/01-users-social.md)

# Section 2: Users, Profile & Social

Profile, follow graph, blocks. `email`/private fields never returned.

## Profile
| Method · Path | Auth | Body → Response | Notes |
|---------------|------|-----------------|-------|
| `GET /v1/users/{id}` | session | → `{ user, stats:{follower_count,following_count,tournament_count}, is_following, is_blocked }` | public profile; soft-delete/block filtered |
| `GET /v1/users/{username}` | session | → same | by username |
| `PATCH /v1/me` | session | `{ display_name?, bio?, city?, photo_upload_id? }` → `{ user }` | edit own profile; profanity backstop |
| `GET /v1/users/{id}/tournaments` · `/posts` · `/records` | session | cursor → `{ data:[…] }` | that user's content (records: public/live only unless self) |

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
