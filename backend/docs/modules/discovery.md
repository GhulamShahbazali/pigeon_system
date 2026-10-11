[← backend docs](../index.md) · api [§10](../../../docs/technical/api/10-discovery.md) · schema §1/§3/§5/§6 (read-only)

# Module: `discovery` (find friends + search)

**Scope:** TikTok-style friend discovery and per-screen search. **Read-only** — owns no tables, creates no writes; result rows reuse Follow (`social`) and Message (`messages`).
**Layers:** `discovery.use-cases` · `data` (`prisma-discovery.repository` — block filter, following-among) · presentation (controller, mappers).

**Routes**
| Method · Path | Powers | Notes |
|---|---|---|
| `GET /v1/discovery/suggestions` | Find friends | popular not-yet-followed users; self/followed/blocked excluded |
| `GET /v1/search/users` | Find friends · chat new-chat | returns `is_following` per row |
| `GET /v1/search/tournaments` | Tournaments tab | title match |
| `GET /v1/search/records` | Records tab | live records by **owner** name |
| `GET /v1/search/conversations` | Chat tab | your accepted threads by other participant |

**Query rules:** `q` required 1–80 (empty → `invalid_request`), `limit` max 50; `BlockFilter` on all five.
**Queues:** none. **Sockets:** none. **Notifications:** none. **New error codes:** none.
**Sync status:** ✅ implemented & verified — suggestions, user/tournament/record/conversation search all 200; empty `q` → 400.
**Invariants:** no new tables (queries existing ones); never introduces a write — Follow/Message actions belong to their own modules.
