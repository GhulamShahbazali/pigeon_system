[← API index](index.md) · schema [§1](../schema/01-users-social.md)

# Section 1: Auth & Session

Passwordless — Firebase (Google/Apple) → backend scoped JWT. Flow in [index.md](index.md#authentication-flow-google--backend-jwt).

| Method · Path | Auth | Body → Response | Notes / errors |
|---------------|------|-----------------|----------------|
| `POST /v1/auth/session` | none | `{ id_token, device_id, device_type, app_version, os_version?, fcm_token? }` → **new:** `202 { onboarding_required, temp_token }` · **returning:** `200 { user, session_token, expires_at }` | Firebase Admin verifies `id_token`. Upserts `user_devices`. `401 unauthenticated` if token invalid |
| `POST /v1/auth/complete-signup` | Bearer **temp_token** (onboarding scope) | `{ display_name, username, language_code, profile_photo_upload_id? }` → `201 { user, session_token, expires_at }` | one txn: insert `users` (timezone from device, country from IP) + default settings. `409 conflict` username taken; `422 unprocessable` bad name |
| `GET /v1/me` | session | → `{ user }` | hydrated self (never includes `email`) |
| `DELETE /v1/auth/session/current` | session | → `204` | logout this device (delete `user_devices` row + `session:{jti}`) |
| `DELETE /v1/auth/session/all` | session | → `204` | logout everywhere (bulk-invalidate `session:*` via `user_sessions:{id}`) |
| `GET /v1/health` | none | → `{ status, db, redis }` | liveness/readiness (performance §8) |

**Touches:** Redis `session:{jti}`, `user_sessions:{user_id}`. No sockets/queues.
