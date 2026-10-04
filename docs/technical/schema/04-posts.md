[← Back to schema index](index.md)

---

# Section 4: Posts

> Facebook-style public feed: text + optional image, like / share / view counts, report, hide. Reports live in §9.
> Behaviour: `../../product/locked-decisions.md` §3 (P1–P11).

---

## Table: `posts`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `author_id` | UUID | Yes | FK `users` (cascade on permanent delete) |
| `content` | text | No | caption/body |
| `image_url` | string | No | R2 (one image MVP — P4 pending for many) |
| `like_count` | integer | Yes | denormalized, default 0 |
| `share_count` | integer | Yes | denormalized, default 0 |
| `view_count` | integer | Yes | denormalized, default 0 |
| `hidden_until` | timestamp | No | moderator temp hide (§9); feed filters `hidden_until IS NULL OR < NOW()` |
| `created_at` | timestamp | Yes | |
| `updated_at` | timestamp | Yes | |
| `deleted_at` | timestamp | No | soft delete |

**Indexes:** `(created_at DESC)` partial WHERE `deleted_at IS NULL` — Home feed; `(author_id, created_at DESC)` — profile; GIN FTS on `content`.
**Rules:** author create/edit/delete (P9 pending); profanity backstop; counts atomic; `post.new` → `feed:global`, `post.counts` debounced 2s.

## Table: `post_likes`
| Column | Type | Req | Notes |
|--------|------|-----|-------|
| `id` | UUID | Yes | PK |
| `post_id` | UUID | Yes | FK (cascade) |
| `user_id` | UUID | Yes | FK (cascade) |
| `created_at` | timestamp | Yes | |

Unique `(post_id, user_id)`; hard delete on unlike; `like_count` atomic. Like → notification to author (§7).

## Table: `post_views`
Dedup — unique `(post_id, user_id)`; `view_count` denormalized; cascade on parent delete.

## Table: `post_shares`
Records a share action (for `share_count` + analytics). `(id, post_id, user_id, channel?, created_at)`. `share_count` atomic.

## Table: `post_hides`
Per-viewer hide — `(id, post_id, user_id, created_at)`, unique `(post_id, user_id)`. The feed query excludes a viewer's hidden posts. Hard delete if un-hidden.

---

*Section 4: Posts · v0.1 · 2026-10-03*
