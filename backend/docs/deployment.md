# Backend — Deployment

> How the three process roles ship and run. Infra choices: `../../docs/technical/tech-stack-decisions.md`; connect/env: `environment.md`; process roles: `../../docs/technical/performance-and-realtime.md`.

---

## Processes (PM2)
Three roles from one build, selected by `PROCESS_ROLE`:
```
pm2 start dist/main.js --name pf-api       -i 2   # API ×2 (Redis adapter mandatory)
pm2 start dist/main.js --name pf-worker    -i 1   # worker(s)
pm2 start dist/main.js --name pf-scheduler -i 1   # EXACTLY ONE (or SCHEDULER_ENABLED on one worker)
```
`-i 2` API gives you the multi-instance path the Socket.io Redis adapter exists for. Enable `app.enableShutdownHooks()` so SIGTERM graceful shutdown runs (performance §7).

## Build
```
npm ci
npx prisma generate
npm run build            # nest build → dist/
npx prisma migrate deploy   # shared DB — deliberate, never migrate dev
```

## Docker (local dev)
`docker compose up -d` brings up local Postgres + Valkey (so you don't burn Aiven connections in day-to-day dev). `.env` points at local; switch to Aiven for shared/staging testing.

```yaml
# docker-compose.yml (sketch)
services:
  postgres: { image: postgres:16, ports: ["5432:5432"], environment: { POSTGRES_PASSWORD: dev } }
  valkey:   { image: valkey/valkey:7, command: ["--maxmemory-policy","noeviction"], ports: ["6379:6379"] }
```

## Environments
| Env | API base | DB/Redis | Notes |
|-----|----------|----------|-------|
| Dev | localhost:3000 | local Docker (or Aiven) | 1 API instance (Bug A hidden — see performance §1) |
| Staging | api-staging.pigeonfly.app | **Aiven** | **2+ API instances** — must test the adapter path |
| Prod | api.pigeonfly.app | Aiven (or upgraded) | 2+ API, 1+ worker, 1 scheduler |

## CI/CD (GitHub Actions)
1. install → `prisma generate` → typecheck → lint → test
2. build → (staging) auto-deploy; (prod) manual approval
3. `prisma migrate deploy` as a deliberate deploy step (gated), **never** auto `migrate dev`
4. PM2 reload (zero-downtime: new instances up, old drained via graceful shutdown)

## Rollback
- App: `pm2 reload` to the previous build (images/artifacts retained).
- DB: forward-only migrations — a bad migration is fixed by a new compensating migration, not a down-migration on live data. Keep migrations small + reversible-by-design (expand/contract).

## Pre-launch checklist
- [ ] Aiven Valkey `maxmemory-policy = noeviction`
- [ ] `connection_limit` set so `Σ ≤ 20` (or upgrade / PgBouncer)
- [ ] Socket.io Redis adapter wired; staging runs 2+ API
- [ ] Exactly one scheduler in every env
- [ ] Sentry DSN + uptime monitor live
- [ ] Backups verified (restore test)

---

*backend/docs/deployment.md · v1.0 · 2026-10-03*
