[← backend docs](../index.md) · api [§4](../../../docs/technical/api/04-posts.md) · schema [§4](../../../docs/technical/schema/04-posts.md)

# Module: `posts` (+ global feed)

**Scope:** Social posts (image/text), global feed, like/share/hide/report. Block-filtered everywhere.
**Layers:** `domain`-lite (`post.use-cases`) · `data` (`prisma-post.repository` — block filter) · `presentation` (controller, mapper).

**Routes**
| Method · Path | Notes |
|---|---|
| `GET /v1/feed` | cursor feed, block-filtered |
| `GET /v1/users/:id/posts` | a single author's posts (profile "Posts"); `is_liked` batched |
| `POST /v1/posts` | create (idempotency-key supported) |
| `GET`/`PATCH`/`DELETE /v1/posts/:id` | read/edit/soft-delete (owner) |
| `POST`/`DELETE /v1/posts/:id/like` | like/unlike; counter atomic |
| `POST`/`DELETE /v1/posts/:id/hide` | hide/unhide from own feed |
| `POST /v1/posts/:id/report` · `/share` | report (→ moderation) · share |

**Queues:** none owned. **Sockets:** `post.new` (feed), debounced count updates to `post:{id}:counts`.
**Notifications raised:** `content_like`.
**Sync status:** ✅ implemented · routes mapped (feed + CRUD + engagement); like/hide block-filter in repo.
**Invariants:** blocked authors never appear; soft-deleted/hidden excluded from feed; counts recomputed in txn, not `COUNT()` on read.
