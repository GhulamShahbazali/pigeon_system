[← backend docs](../index.md) · api [§1](../../../docs/technical/api/01-auth.md) · schema [§1](../../../docs/technical/schema/01-users-social.md)

# Module: `auth`

**Scope:** Passwordless sign-in via Firebase (Google/Apple ID token) → backend scoped JWT; onboarding (complete-signup); session (device) lifecycle.
**Layers:** `domain` (sign-in, complete-signup use cases, `auth.repository` port) · `data` (`prisma-auth.repository`, `adapters/firebase-verifier`) · `presentation` (controller, Zod schemas, user response).

**Routes**
| Method · Path | Notes |
|---|---|
| `POST /v1/auth/session` | verify ID token → returning user: session JWT; new user: `202 { onboarding_required, temp_token }` |
| `POST /v1/auth/complete-signup` | `onboarding` scope → create user + default settings rows (one txn) → session JWT |
| `GET /v1/auth/me` | current user from JWT |
| `DELETE /v1/auth/session/current` · `/all` | logout this device / all devices |

**Scopes/JWT:** `session` 7d, `onboarding` 30m; `jti` cached in Redis `session:{jti}` (1h); suspension/logout invalidates cache.
**Queues:** none. **Sockets:** none. **Notifications:** none.
**Sync status:** ✅ implemented · sign-in / onboarding verified end-to-end on Aiven.
**Invariants:** never return `email`/provider ids; Firebase verify is an adapter behind the domain port (domain has no Firebase import).
