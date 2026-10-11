# PigeonFly — Environment & Managed Services

> How the backend connects to its managed infrastructure, and the gotchas that will bite if missed.
> **Test/dev = Aiven** (`backend/.env`, template `.env.example`). **Production = DigitalOcean** (`backend/.env.production`, template `.env.production.example`). The app code is identical for both — only the connection URLs differ, because we already use `sslmode=require` + `rediss://` TLS + the S3 SDK. Secrets live only in the git-ignored env files.
> **Last updated:** 2026-10-10

---

## Managed services (Aiven)

| Service | What | Notes |
|---------|------|-------|
| **Aiven for PostgreSQL** | the database (§schema) | `defaultdb`, user `avnadmin`, TLS required (`sslmode=require`). Free/hobby tier → **~20 max connections** |
| **Aiven for Valkey** | the Redis layer (cache · presence · BullMQ · Socket.io adapter) | Valkey is a drop-in Redis fork — `ioredis`, `bullmq`, `@socket.io/redis-adapter` all work unchanged. TLS required (`rediss://`) |

> Connection details (host, port, db, user) come from the Aiven console → *Connection information*. The **password is never written into any committed file** — put the full `DATABASE_URL` / `REDIS_URL` in `backend/.env` (git-ignored). Rotate freely; nothing in git depends on a specific secret.

---

## Secret handling (do this once)

1. `cp backend/.env.example backend/.env`
2. Paste the real **Service URI** values from Aiven into `DATABASE_URL` and `REDIS_URL`.
3. `.env` is git-ignored (`backend/.gitignore`). Never commit it. If a secret ever lands in git, **rotate it in the Aiven console** (one click) — don't just delete the commit.

---

## ⚠️ Aiven gotcha 1 — Valkey eviction policy (BullMQ will warn / lose jobs)

BullMQ **requires** the Redis/Valkey eviction policy to be **`noeviction`** — otherwise, under memory pressure, Valkey can evict queue keys and silently drop jobs (push, exports, the midnight auto-end).

- In the **Aiven console → Valkey service → Advanced configuration**, set **`valkey_maxmemory_policy = noeviction`**.
- BullMQ logs `Eviction policy is volatile-lru. It should be "noeviction"` if this is wrong — treat that as a must-fix.

**ioredis connection options for Aiven Valkey (TLS):**
```ts
new IORedis(process.env.REDIS_URL!, {
  tls: {},                      // rediss:// → TLS on
  maxRetriesPerRequest: null,   // required by BullMQ
  enableReadyCheck: false,      // managed Redis/Valkey friendliness
});
```
Use **two separate** ioredis connections for the Socket.io Redis adapter (pub + sub) — a subscriber connection can't run normal commands (performance-and-realtime §1).

---

## ⚠️ Aiven gotcha 2 — Postgres connection limit (~20) → size Prisma pools

Prisma opens a connection **pool per process**. With the locked topology (API ×2 + worker + scheduler = 4 processes) against a **20-connection** Aiven tier:

```
total connections = Σ (per-process connection_limit)  ≤  20  (leave headroom for migrations/psql)
```

- Set `connection_limit` **explicitly** in `DATABASE_URL` (e.g. `?connection_limit=4`). 4 × 4 processes = 16, leaving room.
- Don't rely on Prisma's default (`num_cpus*2+1`) — on a multi-core box that alone blows past 20.
- When you outgrow it: upgrade the Aiven plan, or put **PgBouncer** (transaction pooling) in front (then add `pgbouncer=true` to the Prisma URL).
- This is the exact trap flagged in performance-and-realtime §8 — adding processes **multiplies** connections.

---

## TLS / certificates

- **Postgres:** `sslmode=require` in the URL is enough for most clients. For strict verification, download Aiven's **CA certificate** and point the client at it (`sslmode=verify-full` + `sslrootcert`).
- **Valkey:** `rediss://` scheme = TLS. Aiven uses a public CA; `tls: {}` works out of the box.

---

## Local vs Aiven

- You may run **local Postgres + Valkey via Docker Compose** for day-to-day dev (fast, offline, no connection-limit worry) and point `.env` at Aiven only for shared/staging testing.
- **Staging must run 2+ API instances** against Aiven Valkey to exercise the Socket.io Redis-adapter path (performance-and-realtime §1).

---

## Production — DigitalOcean (`.env.production`)

Aiven is test-only. Production runs on DigitalOcean; concepts map 1:1 and the code is unchanged.

| DO service | Role | Key setting |
|------------|------|-------------|
| **Droplet** (2vCPU/4GB+) | compute — Docker Compose: api (PM2 cluster) + worker ×2 + scheduler ×1 + nginx | `docker-compose.prod.yml` |
| **Managed Postgres** | database | enable a **Connection Pool (transaction mode)**; runtime uses the **pooled** URL (port 25061, `pgbouncer=true`), migrations use the **direct** URL (25060) |
| **Managed Redis** | cache · presence · BullMQ · Socket.io adapter | set **`eviction_policy = noeviction`** (console) — same reason as Aiven gotcha 1 |
| **Load Balancer** | TLS + routing | terminate TLS here; enable **sticky sessions** for Socket.io |
| **Cloudflare R2** (kept) | media | works from DO, free egress — no code change. DO Spaces is S3-compatible but needs a one-line `StorageService` endpoint change |

**The same two gotchas apply, but DO solves the first for you:**
1. **Connection pooling** — use DO's built-in PgBouncer (Connection Pools) instead of counting raw connections. Runtime `DATABASE_URL` = pooled + `pgbouncer=true` + small `connection_limit`; `DATABASE_DIRECT_URL` = direct, for `prisma migrate deploy` / `db execute` only.
2. **`noeviction`** — set it on DO Managed Redis; every cache key already carries a TTL so memory stays bounded while BullMQ keys are never evicted.

**One-time setup (direct URL):**
```bash
DATABASE_URL="$DATABASE_DIRECT_URL" npx prisma migrate deploy
DATABASE_URL="$DATABASE_DIRECT_URL" npx prisma db execute --file prisma/sql/01-search-indexes.sql --schema prisma/schema.prisma
```

---

*environment.md · v1.1 · 2026-10-10 (added DigitalOcean production)*
