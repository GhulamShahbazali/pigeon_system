[← backend docs](../index.md) · api [§8](../../../docs/technical/api/08-settings.md) · schema [§8](../../../docs/technical/schema/08-settings.md)

# Module: `settings`

**Scope:** Per-user preference rows — app (language, theme), notifications (push toggles), privacy. Default rows are created at signup (auth module, in the onboarding txn).
**Layers:** `settings.service` + controller (thin; no cross-module writes).

**Routes**
| Method · Path | Notes |
|---|---|
| `GET /v1/me/settings` | all three preference groups |
| `PATCH /v1/me/settings/app` | language, theme, etc. |
| `PATCH /v1/me/settings/notifications` | push/notify toggles (read by push workers) |
| `PATCH /v1/me/settings/privacy` | privacy preferences |

**Queues:** none. **Sockets:** none. **Notifications:** none.
**Sync status:** ✅ implemented · routes mapped; notification toggles consumed by `push-send` / `dm-push` processors.
**Invariants:** preference rows are 1:1 with user and always exist (created at signup); PATCH is partial-merge.
