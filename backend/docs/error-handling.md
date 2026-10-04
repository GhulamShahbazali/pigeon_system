# Backend — Error Handling

> Every failure returns the standard envelope and **names the failing field**. No bare `invalid_request`. Error codes are the contract in `../../docs/technical/api/index.md`.

---

## Layers
- **Domain / use-case:** return `Result<T>` with a `DomainError` subclass (`patterns.md`). Never `throw` a business error upward.
- **Presentation:** the controller rethrows `result.error` (or an uncaught exception) → the **exception filter** maps it to the envelope + logs to Sentry.

## Envelope (from api/index.md)
```json
{ "error": { "code": "pigeon_cap_exceeded", "message": "Max 20 pigeons",
  "details": { "fields": { "pigeon": "max 20" } }, "request_id": "uuid" } }
```

## DomainError → HTTP
Each `DomainError` carries `code` + `httpStatus` + optional `details`. The filter uses them directly; unknown throws → `500 internal_error` (message hidden, Sentry'd with `request_id`).

| DomainError | code | HTTP |
|-------------|------|------|
| `NotFoundError` | `not_found` | 404 |
| `NotOrganizerError` / forbidden | `forbidden` | 403 |
| `BlockedError` | `blocked` | 403 |
| `SuspendedError` | `suspended` | 403 (+`details.suspended_until`) |
| `ConflictError` (already follow/like) | `conflict` | 409 |
| `PigeonCapExceededError` | `pigeon_cap_exceeded` | 422 |
| `MessageRequestPendingError` | `message_request_pending` | 422 |
| `ProfanityError` | `unprocessable` | 422 |
| `RateLimitError` | `rate_limited` | 429 (+`Retry-After`) |

> A **new** `error.code` must be added to the API section file **before** it ships — the mobile client switches on `code`.

## Zod → field errors
The Zod validation pipe maps a `ZodError` to `400 invalid_request` with `details.fields` as `{ snake_case_path: message }`:
```
{ "code":"invalid_request",
  "details":{"fields":{"landing_time":"must be ISO datetime","day_id":"required"}} }
```
Nested/array paths join with `.` / `[i]`.

## Prisma error translation
A small translator in `shared/errors/` maps Prisma codes so they never leak raw:
| Prisma | → |
|--------|---|
| `P2002` unique violation | `409 conflict` (e.g. duplicate like/follow/username) — map the target to a field |
| `P2025` record not found | `404 not_found` |
| `P2003` FK violation | `409 conflict` or `404` depending on context |
| connection errors | `503 service_unavailable` |
Everything else → `500 internal_error` (Sentry).

## Semantic errors name the offending value
Not just "invalid" — say what and why: `pigeon_cap_exceeded` → `details.fields.pigeon = "max 20"`; a flight before release → `landing_time = "must be after fly time"`.

## Env validation (boot)
`shared/config/env.validation.ts` validates all env with Zod at startup; a missing/invalid var **fails fast** with a readable list (which var, expected shape) — never a half-booted process.

---

*backend/docs/error-handling.md · v1.0 · 2026-10-03*
