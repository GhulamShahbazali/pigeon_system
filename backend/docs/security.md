# Backend — Security

> Secrets, authz, PII boundaries, uploads, abuse. These are enforced in code, not just intended.

---

## Secrets
- Only in `backend/.env` (git-ignored) — see `environment.md`. Env Zod-validated at boot.
- Never log secrets, tokens, or connection strings. Rotate in the Aiven/Firebase/R2 console if leaked (don't just delete the commit).
- Firebase Admin service-account JSON in `secrets/` (git-ignored), path via `FIREBASE_ADMIN_SDK_KEY`.

## Authentication
- Firebase Admin verifies the client's Google/Apple **ID token** (never trust client claims). Backend issues its own **scoped JWT** (`session`/`onboarding`).
- AuthGuard: verify signature + expiry + scope → Redis `session:{jti}` (hit) or DB (miss, then cache 1h) → confirm the `user_devices` row still exists (so logout-all is effective) → inject `req.user`.
- No refresh token; client re-auths via Firebase on expiry.

## Authorization
- **Owner-only** writes (tournaments, participants, flights, records, posts, messages' own) — checked in the use case against `req.user.id`.
- **`@Roles('superadmin')`** on all `/v1/admin/*`.
- **Block gating** everywhere user content meets user content: chat send, presence subscribe, and every content query via the `BlockFilter` helper.
- **Soft-delete + suspension** filters applied to user-facing reads/writes.

## PII boundaries
- **`email` is never returned** in any response — not in profile, not in admin (unless a later explicit admin-only need is documented). Enforced by **explicit response types** (controllers never return a Prisma model/entity).
- **No PII in logs** — `user_id` only; never email, display name, message/post content, tokens, or IP.
- Participant contact fields (phone/address) are shown only where the product intends (tournament contact dialog); treat as sensitive.

## Uploads
- `POST /v1/uploads` validates **MIME + size + purpose** before accepting; images re-encoded (sharp), video probed (ffprobe) in the worker. Reject oversized/unknown types.
- Files stored on **R2**, never the VPS filesystem. Public URLs via the CDN base; private where needed via presigned URLs.
- Strip EXIF/location from uploaded images.

## Transport & edge
- HTTPS everywhere (Cloudflare). TLS to Aiven Postgres (`sslmode=require`) + Valkey (`rediss://`).
- `helmet` for secure headers. CORS restricted to known origins (`CORS_ORIGINS`).
- Cloudflare WAF + edge rate limiting in front of app-level Redis rate limits.

## Abuse prevention
- Redis rate limits on writes (posts 60/h, messages 30/min→200/h, reports 20/h).
- Profanity backstop (server-authoritative) on posts/comments/messages/names.
- Report → admin queue; suspend/block flow (§9).
- Idempotency keys stop duplicate side-effects on retries.

## Compliance hooks
- Account soft-delete (30-day grace) → permanent delete cron (data export/erasure ready).
- Media retention + cleanup crons.

---

*backend/docs/security.md · v1.0 · 2026-10-03*
