# Backend Architecture — Clean Architecture in NestJS

> Clean Architecture is **locked** (`locked-decisions.md`). Product/schema/API contracts live in `../../docs/`, not here. Same `domain → data → presentation` vocabulary as `mobile/`.

---

## Folder tree

```
backend/
├── src/
│   ├── main.ts                      ← role-based bootstrap (api | worker | scheduler)
│   ├── app.module.ts                ← API root module
│   ├── worker.module.ts             ← worker/scheduler root (shares feature modules)
│   ├── shared/                      ← cross-cutting infra
│   │   ├── config/env.validation.ts ← Zod-validated env at boot
│   │   ├── prisma/                  ← PrismaService singleton
│   │   ├── redis/                   ← ioredis singleton (Valkey, TLS)
│   │   ├── socket/                  ← Socket.io gateway + Redis adapter + EmitService
│   │   ├── queue/                   ← BullMQ setup (one queue per job type)
│   │   ├── storage/                 ← Cloudflare R2 client
│   │   ├── push/                    ← Firebase Admin (FCM)
│   │   ├── auth/                    ← AuthGuard, RolesGuard (superadmin), scope decorator
│   │   ├── result/result.ts         ← Result<T>  (patterns.md)
│   │   ├── errors/domain-error.ts   ← DomainError hierarchy (patterns.md)
│   │   ├── filters/                 ← DomainError + unexpected → standard envelope
│   │   ├── interceptors/            ← response-envelope, request-id
│   │   ├── pipes/                   ← zod-validation.pipe
│   │   ├── rate-limit/              ← Redis sliding-window guard
│   │   └── social/                  ← BlockFilter helper (used by content queries)
│   └── modules/
│       ├── auth/        users/      social/     (follows/blocks)
│       ├── tournaments/ participants/           (+ pigeon-flights inside tournaments)
│       ├── posts/       records/    messages/
│       ├── notifications/ settings/ moderation/ admin/
│       └── reference/   (countries/languages)
├── prisma/            ← schema.prisma + migrations/ + seed/
├── docs/              ← you are here
└── test/              ← mirrors src/
```

One module folder per schema-section group (`../../docs/technical/schema/index.md` module mapping).

## Feature module internal shape (every module)

```
modules/tournaments/
├── domain/
│   ├── entities/            ← TournamentEntity, PigeonFlightEntity — plain TS, no Prisma/decorators
│   ├── repositories/        ← interfaces only: ITournamentRepository (+ tokens.ts)
│   ├── services/            ← domain services (e.g. average recompute policy)
│   ├── use-cases/           ← CreateTournamentUseCase, RecordFlightUseCase, …
│   └── errors/              ← NotOrganizerError, PigeonCapExceededError (extend DomainError)
├── data/
│   ├── repositories/        ← PrismaTournamentRepository implements the interface
│   ├── mappers/             ← Prisma row ↔ entity
│   ├── adapters/            ← module-specific external calls
│   └── processors/          ← BullMQ job processors owned by this module
└── presentation/
    ├── controllers/         ← thin — Zod validate, auth guard, call a use case
    ├── dto/                 ← Zod schemas
    └── responses/           ← explicit response types (never return a Prisma model)
```

## Dependency rule (never violate)

```
Presentation ─┐        ┌─ Data
              ▼        ▼
            ┌──────────────┐
            │    Domain     │  pure TypeScript only
            └──────────────┘
```

- **Domain** imports: TS stdlib + `shared/result` + `shared/errors` only. **No** Prisma, Zod, HTTP, Redis, Firebase, Socket.io.
- **Data** imports: domain (implements interfaces) + Prisma + SDKs. No HTTP/Zod DTOs.
- **Presentation** imports: domain (via use cases) + NestJS HTTP + Zod. **Never** a Prisma type, **never** a repository directly — always through a use case.
- `@Injectable()` on use cases/repositories is allowed (DI marker only); domain must not depend on NestJS *behaviour*.

## Module wiring (DI)

Bind a repository interface to its Prisma impl via an injection token **inside the feature module** (never in `app.module.ts` or `shared/`):

```ts
@Module({
  imports: [PrismaModule],
  controllers: [TournamentsController],
  providers: [
    CreateTournamentUseCase, RecordFlightUseCase,
    { provide: TOURNAMENT_REPOSITORY, useClass: PrismaTournamentRepository },
  ],
})
export class TournamentsModule {}
```
Tokens live in `domain/repositories/tokens.ts`; use cases inject via `@Inject(TOURNAMENT_REPOSITORY)`.

## Cross-module rule
A module's `data/repositories/` are **private**. `TournamentsModule` may depend on `NotificationsModule`'s **use case** (to emit a notification) — never on its repository.

## Add-a-module checklist
1. Confirm schema (`../../docs/technical/schema/<N>.md`) + API (`../../docs/technical/api/<N>.md`) are complete; if pending, stop + flag.
2. `domain/{entities,repositories,services,use-cases,errors}/`
3. `data/{repositories,mappers,adapters,processors}/`
4. `presentation/{controllers,dto,responses}/`
5. Wire `*.module.ts`, import into `app.module.ts` (and `worker.module.ts` if it owns jobs).
6. Tests per layer.

---

*backend/docs/architecture.md · v1.0 · 2026-10-03*
