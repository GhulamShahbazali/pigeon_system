# Backend — Naming & Anti-patterns

> Consistent names make the codebase navigable; the anti-patterns are the ones this architecture specifically forbids.

---

## Naming (suffixes carry meaning)
| Thing | Pattern | Example |
|-------|---------|---------|
| Entity (domain) | `*Entity` | `TournamentEntity`, `PigeonFlightEntity` |
| Use case | `*UseCase` | `RecordFlightUseCase`, `GoLiveUseCase` |
| Repository interface | `I*Repository` | `ITournamentRepository` |
| Prisma impl | `Prisma*Repository` | `PrismaTournamentRepository` |
| Injection token | `*_REPOSITORY` (Symbol) | `TOURNAMENT_REPOSITORY` |
| Domain error | `*Error` extends `DomainError` | `PigeonCapExceededError` |
| Controller | `*Controller` | `TournamentsController` |
| Module | `*Module` | `TournamentsModule` |
| Zod schema | `*Schema` | `RecordFlightSchema` |
| Response type/mapper | `*Response` / `to*Response` | `FlightResponse`, `toFlightResponse` |
| BullMQ processor | `*Processor` | `LiveRecordAutoEndProcessor` |
| Queue name | kebab-case | `push-send`, `export-generate` |

**Fields:** DB + API use `snake_case` (`duration_seconds`, `overall_avg_seconds`); TS variables use `camelCase`; mappers bridge the two. Durations/averages always carry the `_seconds` suffix.

## Forbidden (this architecture rejects these)
- ❌ Importing `@prisma/client` (or any Prisma type) in `domain/`.
- ❌ A controller importing/calling a **repository** directly (must go through a use case).
- ❌ Returning a **Prisma model or domain entity** from a controller (leaks fields incl. `email`) — always an explicit `*Response`.
- ❌ `throw`ing a business error out of a use case — return `Result<Err(...)>`.
- ❌ `class-validator`/`class-transformer` — **Zod only**.
- ❌ Another module importing a module's `data/repositories/*` — cross-module via its **use case**.
- ❌ `COUNT(*)`/`AVG()` on a hot read path — use the denormalized columns.
- ❌ Storing a formatted time/average as a string — store `*_seconds` integers.
- ❌ Registering a cron/repeatable job in the **API** process — scheduler only.
- ❌ Running 2+ API instances without the Socket.io Redis adapter.
- ❌ Computing `duration_seconds` on the client — server derives it from `release_at`.
- ❌ A bare `invalid_request` with no `details.fields`.
- ❌ PII in logs.

---

*backend/docs/naming-and-anti-patterns.md · v1.0 · 2026-10-03*
