# Backend Docs — Index (routing)

> Start here for backend work. **Read only what your task needs.** Shared contracts live in `../../docs/`; this folder is backend implementation mechanics.

## Reading order by task

| I'm working on… | Read |
|-----------------|------|
| Anything backend (first time) | `../AGENTS.md` → `architecture.md` → `../../docs/technical/performance-and-realtime.md` |
| Connecting to DB/Redis, `.env`, pooling, Aiven gotchas | `environment.md` |
| Folder placement, layers, DI, adding a module | `architecture.md` |
| Writing an entity / use case / repository / controller / DTO | `patterns.md` |
| A backend technical decision (validation, errors, pagination, transactions, testing) | `locked-decisions.md` |
| Returning any error / adding a validation rule / a new error code | `error-handling.md` |
| Migrations, seeding, denorm integrity, test DB, pooling | `data-management.md` |
| Tokens, PII, authz, uploads, abuse, compliance | `security.md` |
| Logging, monitoring, alerts, backups, incidents | `operations.md` |
| Shipping it — PM2 roles, Docker, CI/CD, rollback, env matrix | `deployment.md` |
| Naming a class, or "is this allowed?" | `naming-and-anti-patterns.md` |
| Changing an existing schema/API/module without drift | `change-management.md` |
| A specific feature module (routes, use cases, queues, invariants) | `modules/<name>.md` |
| Process roles, Socket.io rooms/events, Redis keys, BullMQ queues, fast-endpoint rules | `../../docs/technical/performance-and-realtime.md` *(shared)* |
| What table/column stores this | `../../docs/technical/schema/<section>.md` *(shared — never invent)* |
| What an endpoint accepts/returns, error codes | `../../docs/technical/api/<section>.md` *(shared — never invent)* |
| Is this behaviour decided? | `../../docs/product/locked-decisions.md` |

## Backend docs in this folder (complete)
| File | Holds |
|------|-------|
| `architecture.md` | Clean Architecture folder tree, dependency rule, DI wiring, add-a-module checklist |
| `patterns.md` | Entity/UseCase/Repository/Mapper/Controller/Zod templates + UoW, idempotency, rate-limit |
| `locked-decisions.md` | backend technical decisions (B1–B18) + module↔schema mapping |
| `error-handling.md` | Result/DomainError → envelope, Zod/Prisma translation, field-level errors, env validation |
| `data-management.md` | Prisma org, migration safety, seeding, denorm integrity, pooling, test DB |
| `security.md` | secrets, auth/authz, PII boundaries, uploads, abuse, compliance |
| `operations.md` | logging (no PII), Sentry, monitoring/alerts, health, backups, incidents |
| `deployment.md` | PM2 process roles, Docker, env matrix, CI/CD, rollback, pre-launch checklist |
| `naming-and-anti-patterns.md` | naming table + the forbidden patterns |
| `change-management.md` | how changes propagate contract→code without drift |
| `environment.md` | Aiven Postgres + Valkey connect, `.env`, noeviction + pool-sizing |

## Per-module dossiers — `modules/`
One file per implemented module (scope, routes, use cases, owned queues/sockets, notifications, sync status, invariants). Read the one you're touching.

| Module | Dossier | API | Queues / sockets |
|--------|---------|-----|------------------|
| `auth` | [auth.md](modules/auth.md) | §1 | — |
| `social` (users/follow/block) | [social.md](modules/social.md) | §2 | → `new_follower` |
| `tournaments` | [tournaments.md](modules/tournaments.md) | §3 | `followerFanout` · `tournament.update` |
| `posts` | [posts.md](modules/posts.md) | §4 | `post.new` · count debounce |
| `records` | [records.md](modules/records.md) | §5 | `liveRecordAutoEnd` · `record.*` |
| `messages` | [messages.md](modules/messages.md) | §6 | `dmPush` · `message.*` `chat.read` |
| `notifications` (global) | [notifications.md](modules/notifications.md) | §7 | `pushSend` · `followerFanout` · `notification.*` |
| `settings` | [settings.md](modules/settings.md) | §8 | — |
| `moderation` (+admin) | [moderation.md](modules/moderation.md) | §9 | `user.suspended` |
| `discovery` (find friends + search) | [discovery.md](modules/discovery.md) | §10 | — (read-only) |

---

*backend/docs/index.md · v1.1 · 2026-10-10 (added per-module dossiers)*
