# PigeonFly — Environment & Managed Services

> How the backend connects to its managed infrastructure, and the **Aiven-specific gotchas** that will bite if missed. Secrets live only in `backend/.env` (git-ignored) — see `backend/.env.example`.
> **Last updated:** 2026-10-03

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

*environment.md · v1.0 · 2026-10-03*
