[← API index](index.md) · schema [§9](../schema/09-moderation.md)

# Section 9: Moderation & Admin

User-facing report submit + the **SuperAdmin** web-panel endpoints. Admin routes require `@Roles('superadmin')` (JWT `role=superadmin`), offset pagination, and every write logs to `admin_actions`.

## User-facing
| Method · Path | Auth | Body → | Notes |
|---------------|------|--------|-------|
| `POST /v1/reports` | session | `{ target_type, target_id, reason, note? }` → `201` | rate 20/h; Idempotency-Key |

## Admin (`/v1/admin/*`, superadmin only)
| Method · Path | → | Notes |
|---------------|---|-------|
| `GET /v1/admin/reports?status=&offset=&limit=` | `{ data, meta:{total} }` | review queue |
| `POST /v1/admin/reports/{id}/action` | `204` | `{ action: dismiss\|hide\|remove\|block, note? }` → logs `admin_actions` |
| `GET /v1/admin/users?q=&offset=` | `{ data }` | search/list users (full detail) |
| `GET /v1/admin/users/{id}` | `{ user, content_summary }` | full detail |
| `POST /v1/admin/users/{id}/suspend` | `204` | `{ reason, suspended_until? }` → `user_suspensions` + `users.is_suspended`; socket `user.suspended` |
| `POST /v1/admin/users/{id}/unsuspend` | `204` | lift |
| `GET /v1/admin/posts` · `GET /v1/admin/tournaments` | `{ data, meta }` | browse/moderate all |
| `POST /v1/admin/posts/{id}/hide\|remove` · `…/tournaments/{id}/…` | `204` | moderate; logs `admin_actions` |
| `POST /v1/admin/tournaments` · `PATCH` · `DELETE` | — | full CRUD override |

**Touches:** sockets `user.suspended`/`user.suspension_lifted`. Queue `push-send` (moderation notices → "PigeonFly Team"). Cron `moderation-cleanup` (expired suspensions auto-lift).

> The admin **UI** (Next.js) is a separate surface (`admin/` — own AGENTS.md + docs later); it consumes only these endpoints, never the DB.
