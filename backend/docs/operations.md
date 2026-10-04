# Backend — Operations (logging, monitoring, backups, incidents)

> Running it in production. Pairs with `deployment.md` (how it's deployed) and `../../docs/technical/performance-and-realtime.md` (scaling signals, health checks).

---

## 1. Logging
- **Structured JSON** (pino-style), one line per event. Fields: `level`, `ts`, `request_id`, `user_id` (when known), `route`, `status`, `latency_ms`, `process_role`.
- **No PII** — never email, display name, message/post content, tokens, IP. `user_id` only.
- Worker logs prefix the queue + `job_id`. API vs worker lines distinguishable (`process_role`).
- Log levels: `error` (Sentry too), `warn` (recoverable/degraded), `info` (lifecycle), `debug` (dev only).

## 2. Error tracking — Sentry
- Every `500` and every job that fails after final retry → Sentry with `request_id` + context (route/queue, `user_id`, payload **minus PII**).
- A silently dead-lettered job is an outage nobody sees — ensure final-retry failures alert.

## 3. Monitoring & alerts
| Signal | Source | Alert when |
|--------|--------|------------|
| API p95 latency, 5xx rate | app logs / APM | p95 rising or 5xx spike |
| **BullMQ queue depth** per queue | BullMQ metrics | `push-send`/`high-priority` backing up |
| **Job failure rate** | BullMQ | failures climbing (poison payload / dependency down) |
| DB connections in use | Aiven metrics | near the ~20 limit (pool trap) |
| Redis/Valkey memory + evictions | Aiven metrics | any eviction (must be `noeviction` — see environment.md) |
| Socket connection count | gateway | near FD limits → scale API |
| Uptime: `/v1/health` + TURN n/a | Better Stack/UptimeRobot | down |

Workers have no HTTP port — monitored by **queue depth + failure rate**, not an endpoint.

## 4. Health checks
- **Liveness** (cheap, no deps) → restart on fail. **Readiness** (DB + Redis ping) → drain from LB on fail, not restart (a DB blip shouldn't restart-loop the fleet). Detail: performance-and-realtime §8.

## 5. Backups & recovery
- Aiven managed backups for Postgres (+ Valkey if persistence matters — most Redis state is ephemeral/rebuildable). Know the retention + PITR window of the chosen plan.
- Media on R2 — durable; keep the DB↔R2 reference integrity (orphan cleanup cron).
- Test a restore before launch; document the runbook.

## 6. Incident basics
- Correlate with `request_id` (client can send `X-Request-Id`).
- Common ones: `EADDRINUSE` (leftover process — dev script clears), missing migration (`column does not exist` → `migrate deploy`), Redis `ETIMEDOUT` (Aiven connectivity), online dot stuck (worker not running), "too many connections" (pool sizing).
- Deploys/restarts use graceful shutdown (performance §7) so in-flight work + live sockets drain.

---

*backend/docs/operations.md · v1.0 · 2026-10-03*
