[← backend docs](../index.md) · api [§9](../../../docs/technical/api/09-moderation-admin.md) · schema [§9](../../../docs/technical/schema/09-moderation.md)

# Module: `moderation` (+ admin)

**Scope:** User-filed reports + SuperAdmin actions (review reports, hide/remove content, suspend/unsuspend users). Admin routes gated by `@Roles('superadmin')`.
**Layers:** `moderation.service` + controller.

**Routes**
| Method · Path | Auth | Notes |
|---|---|---|
| `POST /v1/reports` | session | file a report (post/tournament/user/message/record) |
| `GET /v1/admin/reports` | superadmin | offset-paginated queue |
| `POST /v1/admin/reports/:id/action` | superadmin | `dismiss`/`hide`/`remove`/`block` → logs `admin_actions` |
| `GET /v1/admin/users` | superadmin | search users |
| `POST /v1/admin/users/:id/suspend` · `/unsuspend` | superadmin | suspend + invalidate sessions |
| `DELETE /v1/admin/tournaments/:id` | superadmin | soft-delete any tournament (T5) → `deleted_at` + logs `admin_actions` (`remove`) |

**Suspend:** writes `user_suspensions` + `users.is_suspended` in one txn, deletes `session:{jti}` caches (via `user_sessions:{id}`), emits `user.suspended`. Unsuspend lifts + emits `user.suspension_lifted`.
**Queues:** none. **Sockets:** `user.suspended`, `user.suspension_lifted`.
**Sync status:** ✅ implemented · routes mapped with role guard; every admin action written to `admin_actions`.
**Invariants:** admin-only via `@Roles`; actions are audit-logged; hide = temporary (`hidden_until`), remove = soft-delete.
