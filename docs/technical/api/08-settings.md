[← API index](index.md) · schema [§8](../schema/08-settings.md)

# Section 8: Settings

One combined GET; one PATCH per settings table.

| Method · Path | Auth | Body → | Notes |
|---------------|------|--------|-------|
| `GET /v1/me/settings` | session | → `{ notifications, privacy, app }` | all three rows |
| `PATCH /v1/me/settings/notifications` | session | `{ push_enabled?, notify_new_follower?, notify_likes?, notify_followed_tournament?, notify_live_record?, notify_messages? }` → `{notifications}` | read by `push-send` |
| `PATCH /v1/me/settings/privacy` | session | `{ private_account?, show_online_status? }` → `{privacy}` | `show_online_status` → presence projection |
| `PATCH /v1/me/settings/app` | session | `{ language_code }` → `{app}` | `ur\|hi\|ar\|en`; mirrors `users.language_code` |
| `POST /v1/me/contact` | session | `{ subject, message }` → `201` | "Contact us" / support |
| `DELETE /v1/me` | session | `204` | soft-delete account (30-day grace) |

No sockets/queues (except a settings change may affect later `push-send` reads).
