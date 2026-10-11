[← backend docs](../index.md) · api [§2](../../../docs/technical/api/02-users-social.md) · schema [§1](../../../docs/technical/schema/01-users-social.md)

# Module: `social` (users, profile, follow, block)

**Scope:** Public profiles, profile edit, follow graph, block graph. Owns the `BlockFilter` relationship used across content queries.
**Layers:** `domain` (`social.use-cases`, `social.repository` port) · `data` (`prisma-social.repository`) · `presentation` (controller, presentation mapper).

**Routes**
| Method · Path | Notes |
|---|---|
| `GET /v1/users/:id` · `GET /v1/users/by-username/:username` | public profile + `is_following`/`is_blocked`/`tournament_count` |
| `PATCH /v1/me` | edit own profile |
| `POST`/`DELETE /v1/users/:id/follow` | follow/unfollow; counters atomic in txn |
| `POST`/`DELETE /v1/users/:id/block` | block removes follow both ways; counters fixed in txn |
| `GET /v1/users/:id/followers` · `/following` · `GET /v1/me/blocks` | lists |

**Queues:** none directly (push fan-out happens via Notifications). **Sockets:** none here.
**Notifications raised:** `new_follower` (via `NotificationsService.notify` on follow).
**Sync status:** ✅ implemented & verified — follow→`followers=1 is_following=true`; block removes follow + emits block state.
**Invariants:** block is symmetric for visibility (`blockExistsEitherWay`); follow counters never drift (single `$transaction`).
