[← Back to schema index](index.md)

---

# Section 9: Moderation

> User reports + SuperAdmin actions (from the web admin panel). Kept for audit until the user is permanently deleted; moderator FKs `SET NULL`.
> Admin authority: `../../product/locked-decisions.md` §6 (AD1–AD9).

## Table: `reports`
| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | UUID | Yes | PK |
| `reporter_id` | UUID | No | FK `users` — **SET NULL** on reporter delete |
| `target_type` | enum | Yes | `post` \| `tournament` \| `user` \| `message` \| `record` |
| `target_id` | UUID | Yes | polymorphic |
| `reason` | enum | Yes | `spam` \| `abuse` \| `inappropriate` \| `other` |
| `note` | text | No | |
| `status` | enum | Yes | `open` \| `reviewed` \| `actioned` \| `dismissed` — default `open` |
| `created_at` | timestamp | Yes | |

**Indexes:** `(status, created_at DESC)` — admin queue; `(target_type, target_id)`; rate-limited (`rate_limit:reports`).

## Table: `user_suspensions`
| Column | Type | Req | Notes |
|--------|------|-----|-------|
| `id` | UUID | Yes | PK |
| `user_id` | UUID | Yes | FK `users` (cascade on permanent delete) |
| `moderator_id` | UUID | No | FK `users` — SET NULL |
| `reason` | text | No | |
| `suspended_until` | timestamp | No | null = indefinite (block) |
| `lifted_at` | timestamp | No | |
| `created_at` | timestamp | Yes | |

Setting a suspension updates `users.is_suspended`; expiry auto-lifts (cron) and emits a socket event.

## Table: `admin_actions`
Audit log of every SuperAdmin write (hide/remove/block/edit/delete).
| Column | Type | Req | Notes |
|--------|------|-----|-------|
| `id` | UUID | Yes | PK |
| `admin_id` | UUID | No | FK `users` — SET NULL |
| `action` | enum | Yes | `hide` \| `remove` \| `block` \| `unblock` \| `edit` \| `delete` |
| `target_type` | enum | Yes | `post` \| `tournament` \| `record` \| `user` \| `report` |
| `target_id` | UUID | Yes | |
| `note` | text | No | |
| `created_at` | timestamp | Yes | |

**Indexes:** `(admin_id, created_at DESC)`; `(target_type, target_id)`.

---

*Section 9: Moderation · v0.1 · 2026-10-03*
