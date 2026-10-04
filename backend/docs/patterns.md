# Backend Patterns — Code Templates

> Copy these shapes. Read on-demand when writing a class. Conventions are locked in `locked-decisions.md`.

---

## `Result<T>` — expected failures (no throwing across layers)

```ts
export type Result<T> = { ok: true; value: T } | { ok: false; error: DomainError };
export const Ok  = <T>(value: T): Result<T> => ({ ok: true, value });
export const Err = (error: DomainError): Result<never> => ({ ok: false, error });
```
Use cases return `Result<T>`. Only the presentation layer turns an `Err` into an HTTP envelope (via the exception filter / a small mapper). **Never** `throw` a business error out of a use case.

## `DomainError`
```ts
export abstract class DomainError extends Error {
  abstract readonly code: string;       // kebab/snake → api error.code
  abstract readonly httpStatus: number;
  details?: Record<string, unknown>;    // e.g. { fields: { landing_time: 'after fly time' } }
}
export class NotOrganizerError extends DomainError {
  readonly code = 'forbidden'; readonly httpStatus = 403;
}
export class PigeonCapExceededError extends DomainError {
  readonly code = 'pigeon_cap_exceeded'; readonly httpStatus = 422;
  constructor(cap: number) { super(`Max ${cap} pigeons`); this.details = { fields: { pigeon: `max ${cap}` } }; }
}
```
Every error **names its failing field** in `details.fields` — never a bare `invalid_request`.

## Entity (pure, no Prisma)
```ts
export class PigeonFlightEntity {
  constructor(
    readonly id: string,
    readonly participantId: string,
    readonly dayId: string,
    readonly pigeonName: string,
    readonly landingTime: Date,
    readonly durationSeconds: number,   // computed = landing − release; stored as int
  ) {}
}
```

## Repository — interface in domain, Prisma impl in data
```ts
// domain/repositories/tournament.repository.ts
export interface ITournamentRepository {
  findById(id: string): Promise<TournamentEntity | null>;
  addFlight(input: NewFlight, tx?: UnitOfWork): Promise<PigeonFlightEntity>;
  recomputeParticipantStats(participantId: string, tx?: UnitOfWork): Promise<void>;
}
export const TOURNAMENT_REPOSITORY = Symbol('TOURNAMENT_REPOSITORY');
```
```ts
// data/repositories/prisma-tournament.repository.ts
@Injectable()
export class PrismaTournamentRepository implements ITournamentRepository { /* Prisma + mapper */ }
```

## Use case — business logic, returns Result, owns the transaction
```ts
@Injectable()
export class RecordFlightUseCase {
  constructor(@Inject(TOURNAMENT_REPOSITORY) private repo: ITournamentRepository,
              private uow: UnitOfWork, private emit: EmitService) {}

  async execute(cmd: RecordFlightCommand): Promise<Result<PigeonFlightEntity>> {
    const t = await this.repo.findById(cmd.tournamentId);
    if (!t) return Err(new NotFoundError('tournament'));
    if (t.organizerId !== cmd.actorId) return Err(new NotOrganizerError());

    return this.uow.run(async (tx) => {               // ← one transaction
      const count = await this.repo.flightCount(cmd.participantId, cmd.dayId, tx);
      if (count >= t.pigeonCount) return Err(new PigeonCapExceededError(t.pigeonCount));

      const duration = Math.floor((cmd.landingTime.getTime() - cmd.releaseAt.getTime()) / 1000);
      const flight = await this.repo.addFlight({ ...cmd, durationSeconds: duration }, tx);
      await this.repo.recomputeParticipantStats(cmd.participantId, tx);  // denorm avg, in txn
      return Ok(flight);
    }).then((r) => {
      if (r.ok) { this.emit.tournamentUpdate(cmd.tournamentId); this.queue.followerFanout(cmd.tournamentId); }
      return r;
    });
  }
}
```
This is the **canonical PigeonFly write**: owner check → cap check → compute `duration_seconds` → insert → recompute denormalized average **inside the same transaction** → emit socket + enqueue fan-out **after commit**.

## Controller — thin
```ts
@Controller('tournaments')
export class TournamentsController {
  constructor(private recordFlight: RecordFlightUseCase) {}

  @Post(':id/flights') @UsePipes(new ZodValidationPipe(RecordFlightSchema))
  async record(@Param('id') id: string, @Body() body: RecordFlightDto, @Req() req) {
    const r = await this.recordFlight.execute({ tournamentId: id, actorId: req.user.id, ...body });
    if (!r.ok) throw r.error;                 // exception filter → envelope
    return toFlightResponse(r.value);         // explicit response type, never the entity/Prisma model
  }
}
```

## Zod DTO (presentation only)
```ts
export const RecordFlightSchema = z.object({
  participant_id: z.string().uuid(),
  day_id: z.string().uuid(),
  pigeon_name: z.string().min(1),
  landing_time: z.string().datetime(),
});
```

## Unit of Work
`UnitOfWork.run(cb)` wraps `prisma.$transaction`; repositories accept an optional `tx` so a use case composes several writes atomically (flight + stats + counters).

## Idempotency
For create endpoints with side effects, honour an `Idempotency-Key` header → store `{key → first response}` in Redis 24h (`idemp:{key}`). BullMQ jobs use a deterministic `jobId` for dedup.

## Rate limiting
`@RateLimit('messages')` decorator → Redis sliding window (`rate_limit:messages:{user_id}`) → `429` + `Retry-After`. Limits per `../../docs/technical/performance-and-realtime.md`.

---

*backend/docs/patterns.md · v1.0 · 2026-10-03*
