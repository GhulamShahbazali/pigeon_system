# Backend — Locked Technical Decisions

> Backend implementation decisions (not product — product lives in `../../docs/product/locked-decisions.md`). If code disagrees with this file, the code is wrong.
> **Last updated:** 2026-10-03

| # | Decision | Value |
|---|----------|-------|
| B1 | Architecture | **Clean Architecture** — `domain → data → presentation` per module (`architecture.md`) |
| B2 | Validation | **Zod**, presentation layer only. No `class-validator`/`class-transformer` |
| B3 | Error handling | **`Result<T>` + `DomainError`** for expected failures; controllers rethrow → exception filter → envelope. Every error names its field (`details.fields`) |
| B4 | Response shape | `{ data, meta? }` success · `{ error: { code, message, details?, request_id } }` on failure. **Never return a Prisma model / domain entity** — explicit response types |
| B5 | Pagination | **cursor** (opaque base64 `{sort,id}`) for feeds/lists/chat; **offset** only in admin |
| B6 | Transactions | every multi-table write in one Prisma `$transaction`; **denormalized averages/counters recomputed inside it** |
| B7 | Durations/averages | store `duration_seconds` (int); averages denormalized (`avg_seconds`), recomputed on flight write — never `AVG()` on a read path (schema §3/§5) |
| B8 | IDs | UUID PKs (except `countries`/`languages` = ISO codes) |
| B9 | Soft delete | `deleted_at IS NULL` filter on every user-facing query for soft-delete tables |
| B10 | Auth | Firebase Admin verifies the Google/Apple ID token → backend issues a scoped JWT (`session`/`onboarding`); session cached in Redis `session:{jti}` |
| B11 | Realtime | Socket.io + **Redis adapter on every API process**; emits via `EmitService`; counts debounced (`performance-and-realtime.md`) |
| B12 | Jobs | **BullMQ**; workers/scheduler separate from API; exactly **one** scheduler; jobs **idempotent**; deterministic `jobId` for dedup |
| B13 | Rate limiting | Redis sliding window per endpoint bucket; `429` + `Retry-After` |
| B14 | Block filter | a shared `BlockFilter` helper returns `{blocked_by_me, blocked_me}`; composed into every content query + chat send + presence subscribe |
| B15 | Logging | structured JSON; **no PII** (user_id only, never email/content/tokens/IP); Sentry for errors with `request_id` |
| B16 | Media / exports | off the request path — R2 upload → `media-process`; share → `export-generate` worker |
| B17 | Env | Zod-validated at boot; secrets in `.env` only (`environment.md`); Aiven **noeviction** + **pool sizing** honoured |
| B18 | Testing | per layer — domain use cases (unit, pure), repositories (integration vs test DB), controllers (e2e happy + error path) |

---

## Module ↔ schema section mapping

| Backend module(s) | Schema section |
|-------------------|----------------|
| `auth`, `users`, `social` (follows/blocks), `reference` | §1 Users & Social, §2 Reference |
| `tournaments` (+ participants, pigeon-flights) | §3 Tournaments |
| `posts` | §4 Posts |
| `records` | §5 Personal Records |
| `conversations`/`messages` | §6 Messages |
| `notifications` | §7 Notifications |
| `settings` | §8 Settings |
| `moderation`, `admin` | §9 Moderation |

Home has **no** module/tables — it reads across §3/§4/§5.

---

## What is still open (don't build these blind)
- Average "Not returned" denominator is locked (returned only), but the **exact ranking tiebreakers** (equal averages) — confirm.
- `api/` endpoint contract — ⏳ being written (`../../docs/technical/api/`). Don't invent request/response shapes; read the section file.
- Deep-link provider (TS7), video constraints — see `../../docs/product/open-questions.md`.

---

*backend/docs/locked-decisions.md · v1.0 · 2026-10-03*
