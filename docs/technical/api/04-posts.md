[← API index](index.md) · schema [§4](../schema/04-posts.md)

# Section 4: Posts

Facebook-style public feed (also the Home feed). Like / share / view / follow / report / hide.

| Method · Path | Auth | Body → | Notes |
|---------------|------|--------|-------|
| `GET /v1/feed?tab=for_you\|following` | session | cursor → `{ data:[post] }` | Home feed; `BlockFilter` + hidden + soft-delete filtered; counts via sockets |
| `GET /v1/users/{id}/posts` | session | `?limit` → `{ data:[post] }` | a single author's posts, newest first, with the viewer's `is_liked` annotated (batched). Powers the profile "Posts" list (own or another user) |
| `GET /v1/posts/{id}` | session | → `{ post }` | records dedup view |
| `POST /v1/posts` | session | `{ content?, image_upload_id? }` → `201 {post}` | rate 60/h; profanity backstop; `post.new`→`feed:global`. Idempotency-Key |
| `PATCH /v1/posts/{id}` | session | `{ content?, image_upload_id? }` → `{post}` | author only |
| `DELETE /v1/posts/{id}` | session | `204` | author only; soft delete |
| `POST /v1/posts/{id}/like` / `DELETE` | session | `204` | `like_count` atomic; `post.counts` debounced; like → notification |
| `POST /v1/posts/{id}/share` | session | `204` | `share_count`++ |
| `POST /v1/posts/{id}/hide` / `DELETE` | session | `204` | per-viewer hide (excluded from that user's feed) |
| `POST /v1/posts/{id}/report` | session | `{ reason, note? }` → `201` | → §9 `reports`; rate 20/h |

**Touches:** sockets `post.new`, `post.counts`. Redis `throttle:post_counts:{id}`, `rate_limit:posts`. Queue `push-send` (likes).
