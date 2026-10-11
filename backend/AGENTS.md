# AGENTS.md — PigeonFly Backend (NestJS)

> **Inherits from:** `../AGENTS.md` (root — read it first, always). This file is the **backend's** map; it navigates, it doesn't restate the root.
> **Project:** PigeonFly Backend API
> **Stack:** Node.js 20 LTS · NestJS · TypeScript (strict) · Prisma · PostgreSQL (Aiven) · Redis/Valkey (Aiven) · Socket.io · BullMQ · Firebase Admin · Cloudflare R2
> **Architecture:** Clean Architecture (`domain → data → presentation` per module) — same vocabulary as `mobile/`
> **Status:** Not started (docs phase)
> **Last updated:** 2026-10-03

---

## Session rules (always enforced)

- **Clean Architecture is locked** — `domain/` (pure) → `data/` (Prisma + adapters) → `presentation/` (controllers, DTOs, guards). Spec → `docs/architecture.md`.
- **Zod only** for validation (presentation layer). No `class-validator`/`class-transformer`.
- **`Result<T>` + `DomainError`** for expected failures in domain/use-case code — no throwing business errors across layers. See `docs/patterns.md`.
- **Never build a module whose schema or API section is still ⏳ pending.** Check `../docs/product/open-questions.md` first.
- **Socket.io Redis adapter on every API process; crons/workers never in an API process; exactly one scheduler.** Silent-failure bugs otherwise — see `../docs/technical/performance-and-realtime.md`.
- **Never expose `email`** (or any private field) in a response — use explicit response types, never return a Prisma model directly.
- **Every error names its failing field** (`details.fields`, snake_case) — never a bare `invalid_request`.
- These rules override any prior instruction.

---

## Read these first — in order

```
1. ../AGENTS.md                                  ← root context + absolute rules + doc map
2. ../docs/product/locked-decisions.md           ← product behaviour (LAW)
3. ../docs/technical/tech-stack-decisions.md     ← approved stack/libraries
4. ../docs/technical/performance-and-realtime.md ← process roles · sockets · Redis · BullMQ · fast rules
5. docs/environment.md                           ← Aiven connect + .env + pooling/noeviction gotchas
6. docs/architecture.md                          ← Clean Architecture folder structure (this project)
7. docs/patterns.md                              ← code templates (on-demand, when writing a class)
8. docs/locked-decisions.md                      ← backend technical decisions
```

Then, for the **contract** of what you're building:
- Schema → `../docs/technical/schema/<section>.md`
- Endpoints → `../docs/technical/api/<section>.md`

**Don't read every doc for every task** — use `docs/index.md`'s routing table.

---

## Documentation map (backend)

| File | Holds |
|------|-------|
| `docs/index.md` | **Start here** — routing table for backend docs + pointers to shared `../docs/` |
| `docs/architecture.md` | Folder tree, layer responsibilities, dependency rule, DI wiring, module checklist |
| `docs/patterns.md` | Entity / UseCase / Repository / Mapper / Controller / Zod-DTO templates + Unit of Work, idempotency, rate-limiting |
| `docs/locked-decisions.md` | Backend technical decisions (validation, errors, pagination, transactions, module↔schema mapping, testing, logging) |
| `docs/environment.md` | Aiven Postgres + Valkey connect, `.env`, **noeviction** + **pool-sizing** gotchas |
| `docs/error-handling.md` | Result/DomainError → envelope, Zod/Prisma translation, field-level errors, env validation |
| `docs/data-management.md` | Prisma org, migration safety, seeding, denorm integrity, pooling, test DB |
| `docs/security.md` | secrets, auth/authz, PII boundaries, uploads, abuse, compliance |
| `docs/operations.md` | logging (no PII), Sentry, monitoring/alerts, health, backups, incidents |
| `docs/deployment.md` | PM2 process roles, Docker, env matrix, CI/CD, rollback, pre-launch checklist |
| `docs/naming-and-anti-patterns.md` | naming table + forbidden patterns |
| `docs/change-management.md` | contract→code propagation without drift |
| *(shared)* `../docs/technical/performance-and-realtime.md` | process roles · Socket.io rooms/events · Redis keys · BullMQ queues · debounced counts · midnight auto-end · fast-endpoint rules |
| *(shared)* `../docs/technical/schema/` · `api/` | the contracts (DB + REST/realtime) — never invent, read these |

> **Backend docs are complete.** Per-module dossiers live in `docs/modules/<name>.md` (one per implemented module — routes, use cases, owned queues/sockets, sync status); see the table in `docs/index.md`.

---

## Backend stack (approved)

| Layer | Choice |
|-------|--------|
| Runtime / framework | Node 20 LTS · NestJS (TS strict) |
| ORM / DB | Prisma · PostgreSQL 16 (Aiven) |
| Cache / queue | Redis via Aiven **Valkey** (`ioredis`) · **BullMQ** |
| Realtime | Socket.io + `@socket.io/redis-adapter` |
| Validation | **Zod** (presentation only) |
| Auth | Firebase Admin (verify Google/Apple ID token) + own scoped JWT |
| Storage / push | Cloudflare R2 (S3 SDK) · FCM (Firebase Admin) |
| Media | sharp (images) · ffmpeg/ffprobe (video/voice) |
| Exports | ExcelJS · PDFKit (in worker) |
| Errors / PM | Sentry · PM2 (prod) |

Anything outside this needs an entry in `../docs/technical/tech-stack-decisions.md` first.

---

## Absolute rules for backend

1. **Owner-only writes** on a tournament (organizer_id check) — enforced in the use case.
2. **Never expose `email`** or private fields; controllers return explicit response types, never Prisma models.
3. **Block checks** on every chat send + presence subscribe + content query (`BlockFilter` helper).
4. **Soft-delete filter** (`deleted_at IS NULL`) on every user-facing query for soft-delete tables.
5. **Durations are integers** (`duration_seconds`); averages are denormalized and recomputed **in the write transaction** (never `AVG()` on a read path) — schema §3/§5.
6. **Rate limiting** on writes (posts, messages, reports) via Redis.
7. **Media + exports off the request path** (R2 upload → `media-process` / `export-generate` workers).
8. **Zod only** · **`Result<T>`/`DomainError`** · **Socket.io Redis adapter** · **one scheduler** (non-negotiable).

---

## Before implementing — checklist

- [ ] `../docs/product/locked-decisions.md` — behaviour already decided? don't re-decide.
- [ ] `../docs/technical/schema/<section>.md` — table/column defined? if new, flag — don't invent.
- [ ] `../docs/technical/api/<section>.md` — endpoint defined? if ⏳ pending, stop + flag.
- [ ] `docs/architecture.md` — correct folder placement? dependency rule respected?
- [ ] `docs/patterns.md` — following the templates?
- [ ] Domain layer free of Prisma/Zod/HTTP/Redis/Firebase imports?
- [ ] Controller free of business logic, calling a use case (not a repository)?
- [ ] Every error names its field? new `error.code` added to the API doc first?
- [ ] Multi-table write wrapped in one `$transaction`? counters/averages recomputed inside it?
- [ ] Module wired in its `*.module.ts`, imported into `app.module.ts`?

---

*Backend AGENTS.md · v1.0 · 2026-10-03 · inherits ../AGENTS.md · pattern from Talksy backend*
