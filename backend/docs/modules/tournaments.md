[← backend docs](../index.md) · api [§3](../../../docs/technical/api/03-tournaments.md) · schema [§3](../../../docs/technical/schema/03-tournaments.md)

# Module: `tournaments` (+ participants, pigeon-flights)

**Scope:** Organizer-created tournaments, day schedule, participants, per-day pigeon flights, live standings, follow/like/share. Core domain math lives here.
**Layers:** `domain` (`write.use-cases`, `read.use-cases`, `tournament.repository` port, `tournament.errors`) · `data` (`prisma-tournament.repository` — tz math + recompute) · `presentation` (schemas, responses, controller).

**Routes**
| Method · Path | Notes |
|---|---|
| `GET`/`POST /v1/tournaments` | list (all/upcoming/ongoing/past/mine/following) · create (organizer) |
| `GET /v1/tournaments/by-user/:userId` | a given organizer's tournaments (profile "Tournaments") |
| `GET /v1/tournaments/:id` | detail + days |
| `GET`/`POST /v1/tournaments/:id/participants` | list · add (organizer only) |
| `GET /v1/tournaments/:id/participants/:pid` | participant per-day detail |
| `POST /v1/tournaments/:id/participants/:pid/flights` | record a flight (organizer only) |
| `POST`/`DELETE /v1/tournaments/:id/follow` · `/like` | engagement |

**Domain rules:** `duration_seconds = landing − day.release_at` (tz-correct via `Intl.DateTimeFormat`); day avg + overall avg + positions recomputed **inside the write txn** (`{timeout:20000}` for Aiven latency); **higher average wins** (rank desc); pigeon cap = max per participant/day → `pigeon_cap_exceeded (422)`; landing before release → `flight_before_release`.
**Queues:** `followerFanout` (on create → `tournament_created` to organizer's followers); `tournamentFanout` (on participant add + flight → fans to organizer's followers **and** the tournament's own followers, deduped). **Sockets:** `tournament.update` (fresh standings to `tournament:{id}` on each flight).
**Notifications raised:** `tournament_created` (follower-fanout) · `participant_added` (tournament-fanout, `data.participant_name`) · `tournament_day_results` (tournament-fanout, `data.participant_name` + `pigeon_name` + `landing_time`; the processor adds `tournament_title` + `contact_no`).
**Participant lock (T3b):** `AddParticipantUseCase` rejects with `422 tournament_started` once `startDate` (UTC day) is reached — unless called with `{ allowAfterStart: true }` (bot seeder only, for backfilling historical/running tournaments).
**Perf:** flight `recompute` re-ranks only the participants whose `position` actually changed (avoids N serial UPDATEs per flight); `findDetail` fetches tournament + viewer follow/like in one parallel batch; `detail` records the view fire-and-forget.
**Sync status:** ✅ implemented & verified — 2 participants, flights, standings (#1 avg 24750s, cap on 3rd flight, tz correct).
**Invariants:** owner-only writes; no new participants after start (T3b); a not-returned pigeon is simply **no row** (never counts toward average).
