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
| Prod | api.pigeonfly.app | **DigitalOcean** (Managed Postgres + Redis) | Droplet: api cluster + worker ×2 + scheduler ×1 + nginx, behind a DO LB |

## Production on DigitalOcean (Docker)
Aiven is test-only; production runs on a DO Droplet with DO Managed Postgres + Redis (see `environment.md` → *Production — DigitalOcean*). Ship files (committed): `Dockerfile` (multi-stage), `.dockerignore`, `docker-compose.prod.yml` (api/worker/scheduler/nginx), `deploy/nginx.conf`, `.env.production.example`.

```bash
cp .env.production.example .env.production      # fill real DO values
# one-time schema + trigram indexes via the DIRECT (non-pooled) url:
DATABASE_URL="$DATABASE_DIRECT_URL" npx prisma migrate deploy
DATABASE_URL="$DATABASE_DIRECT_URL" npx prisma db execute --file prisma/sql/01-search-indexes.sql --schema prisma/schema.prisma
docker compose -f docker-compose.prod.yml up -d --build
```
- API runs **PM2 cluster (`-i max`)** inside its container (all droplet cores); worker/scheduler run plain `node`.
- **Scheduler replicas must stay 1.** Workers scale freely.
- TLS + **sticky sessions** (Socket.io) at the **DO Load Balancer** in front of nginx.
- Runtime uses the **pooled** `DATABASE_URL` (`pgbouncer=true`); migrations use `DATABASE_DIRECT_URL`.

## CI/CD (GitHub Actions)
1. install → `prisma generate` → typecheck → lint → test
2. build → (staging) auto-deploy; (prod) manual approval
3. `prisma migrate deploy` as a deliberate deploy step (gated), **never** auto `migrate dev`
4. PM2 reload (zero-downtime: new instances up, old drained via graceful shutdown)

## Rollback
- App: `pm2 reload` to the previous build (images/artifacts retained).
- DB: forward-only migrations — a bad migration is fixed by a new compensating migration, not a down-migration on live data. Keep migrations small + reversible-by-design (expand/contract).

## Pre-launch checklist
- [ ] **DO Managed Redis** `eviction_policy = noeviction` (Aiven Valkey too, for staging)
- [ ] Runtime on the **pooled** `DATABASE_URL` (`pgbouncer=true`, small `connection_limit`); migrations on `DATABASE_DIRECT_URL`
- [ ] **DO Load Balancer**: TLS + **sticky sessions** for Socket.io
- [ ] Socket.io Redis adapter wired; prod runs 2+ API (PM2 cluster counts)
- [ ] **Exactly one scheduler** container (`replicas: 1`)
- [ ] Trigram indexes applied (`prisma/sql/01-search-indexes.sql`)
- [ ] `/v1/health` (liveness) + `/v1/health/ready` wired to LB + UptimeRobot
- [ ] Sentry DSN set; pino JSON logs shipping
- [ ] Backups verified (DO Managed DB daily backup + restore test)

---

*backend/docs/deployment.md · v1.1 · 2026-10-10 (DigitalOcean production)*
