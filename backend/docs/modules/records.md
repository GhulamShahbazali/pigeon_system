[← backend docs](../index.md) · api [§5](../../../docs/technical/api/05-records.md) · schema [§5](../../../docs/technical/schema/05-records.md)

# Module: `records` (personal day records, private/live)

**Scope:** A flyer's own day record — add pigeons (landings), keep private or go live; live records stream to followers and auto-end at owner-local midnight.
**Layers:** `data` (`prisma-record.repository` — tz release/auto-end, `LIVE_SET` redis) · use cases (`record.use-cases`) · presentation (controller, mapper) · worker (`live-record-auto-end.processor`).

**Routes**
| Method · Path | Notes |
|---|---|
| `GET`/`POST /v1/me/records` | my records · create (private\|live) |
| `GET /v1/records/live` | live records **from people you follow** |
| `GET /v1/records/:id` | detail (+pigeons); private hidden unless owner |
| `POST /v1/records/:id/pigeons` | add landing; duration from `release_at`; live → emits update |
| `POST /v1/records/:id/go-live` · `/end` | publish / end (owner) |
| `POST`/`DELETE /v1/records/:id/like` | engagement |

**Averages:** mean of returned pigeons, recomputed in txn; same "higher avg = better" rule as tournaments.
**Queues:** `liveRecordAutoEnd` — **delayed** job at go-live, `jobId: record-end-{id}` (no `:` — BullMQ rule), fires at owner-local midnight; idempotent.
**Sockets:** `record.live_started` (to followers), `record.update` (`record:{id}`), `record.live_ended`.
**Notifications raised:** `record_live_started` (to followers).
**Sync status:** ✅ implemented & verified — create→pigeons (6000s/7500s)→avg 6750s, go-live (auto_end 19:00 UTC = local midnight), delayed job queued, end drops from live list.
**Invariants:** `records/live` requires a follow relationship; not-returned pigeon = no row.
