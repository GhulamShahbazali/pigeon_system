# PigeonFly — Tech Stack Decisions

> Finalized technology choices. New tech may not be introduced without an entry here.
> Pattern & best practices adapted from the Talksy backend docs.
> **Last updated:** 2026-10-03 · **Version:** 1.0

---

## Stack Overview

| Layer | Technology | Status |
|-------|------------|--------|
| Mobile app | **Flutter** (Android + iOS) | ✅ |
| Admin panel | **Next.js** (web) — consumes the backend API only | ✅ |
| Backend framework | **Node.js (LTS) + NestJS** (TypeScript, strict) | ✅ |
| Architecture | **Clean Architecture** (`domain → data → presentation` per module) | ✅ |
| Database | **PostgreSQL 16+** — hosted on **Aiven** (`defaultdb`) · see [backend/docs/environment.md](../../backend/docs/environment.md) | ✅ |
| ORM | **Prisma** (mind the Aiven ~20-connection limit → small pools) | ✅ |
| Realtime | **Socket.io** (single namespace, room-based) + `@socket.io/redis-adapter` | ✅ |
| Cache / ephemeral state | **Redis** via **Aiven Valkey** (`ioredis`, TLS `rediss://`) · set `noeviction` for BullMQ | ✅ |
| Background jobs / scheduling | **BullMQ** (Redis-backed) | ✅ |
| Auth | **Firebase Auth** (Google; Apple on iOS) → backend verifies, issues own JWT | ✅ |
| Push | **Firebase Cloud Messaging (FCM)** via Firebase Admin SDK | ✅ |
| File storage | **Cloudflare R2** (S3-compatible, zero egress) | ✅ |
| Media processing | **sharp** (images) · **ffmpeg/ffprobe** (video/voice note) | ✅ |
| Exports (share) | **ExcelJS** (.xlsx) · **PDFKit**/Puppeteer (PDF) · sharp (image card) — in worker | 🟡 |
| Deep links | Universal/App Links + a provider for **deferred** install→open — **pending** (see open-questions TS7) | ❓ |
| Validation | **Zod** (presentation layer only — no class-validator) | ✅ |
| Error tracking | **Sentry** | ✅ |
| Logging | Structured JSON (pino-style), no PII | ✅ |
| Hosting | VPS (Hetzner / DigitalOcean), load-balanced | 🟡 |
| CDN / DNS / WAF | **Cloudflare** | ✅ |
| CI/CD | GitHub Actions · Docker + Docker Compose (local) | 🟡 |

> **Not needed (unlike Talksy):** no WebRTC / coturn / LiveKit — PigeonFly has **no voice/video calls**. "Voice note / video" in chat are just **uploaded media files** (R2), not realtime streams.

---

## 1. Why these choices

- **NestJS + Clean Architecture** — structured, DI-first, matches the mobile app's layering vocabulary; testable; scales with the team.
- **PostgreSQL + Prisma** — strong consistency for tournaments/records, type-safe queries, first-class migrations, `jsonb` where flexibility helps, full-text search built-in (user/tournament search) before reaching for Meilisearch.
- **Socket.io + Redis adapter** — the app is **live-first** (standings, live records, counts, chat, notifications). The Redis adapter is **mandatory** so emits reach users across all API instances (see [performance-and-realtime.md](performance-and-realtime.md)).
- **Redis + BullMQ** — caching, presence, rate limiting, debounced count emits, and all async/scheduled work (push, exports, media processing, the **daily live-record auto-end**).
- **Firebase Auth (Google)** — passwordless, App-Store-compliant (Apple on iOS), backend verifies the ID token and issues its own scoped JWT.
- **Cloudflare R2** — participant photos, tournament covers, post images, chat media (image/video/voice note). Zero egress = cheap for a media feed.

---

## 2. Approved mobile packages (Flutter)

| Package | Use |
|---------|-----|
| `flutter_bloc` · `equatable` | state management |
| `get_it` | dependency injection |
| `dio` · `connectivity_plus` | HTTP + connectivity |
| `socket_io_client` | realtime (standings, live records, counts, chat, notifications, presence) |
| `go_router` | routing + **deep links** (tournament links) |
| `firebase_core` · `firebase_auth` · `google_sign_in` · `sign_in_with_apple` | auth |
| `firebase_messaging` | push |
| `flutter_secure_storage` · `shared_preferences` | token + prefs |
| `image_picker` · `cached_network_image` | photos (participant, cover, post, chat) |
| `record` · `audioplayers` · `path_provider` | chat **voice notes** (capture + playback) |
| video capture/playback package | chat **video** (TBD — confirm before use) |
| `scrollable_positioned_list` | feed viewport tracking (view batching + count room subscribe/unsubscribe) |
| `google_fonts` | Manrope + Plus Jakarta Sans (design-system) |

> Any package outside this table needs an entry here first.

---

## 3. Backend approved libraries

`@nestjs/*` · `@prisma/client` · `prisma` · `ioredis` · `bullmq` · `socket.io` · `@socket.io/redis-adapter` · `firebase-admin` · `@aws-sdk/client-s3` (R2) · `zod` · `jsonwebtoken` · `helmet` · `sharp` · `exceljs` · `pdfkit` (or `puppeteer` for PDF) · Sentry SDK.

Process manager: **PM2** (production). Env validated with Zod at boot.

---

## 4. Environments

| Env | API base |
|-----|----------|
| Dev | `http://localhost:3000` |
| Staging | `https://api-staging.pigeonfly.app` |
| Production | `https://api.pigeonfly.app` |

> **Staging must run 2+ API instances** to exercise the Socket.io Redis-adapter path (a single instance hides the multi-instance broadcast bug — see performance-and-realtime.md §1).

---

## 5. Pending technical decisions

- [ ] **Deep-link provider** for tournament links (deferred install→open) — TS7 in open-questions.
- [ ] **Average formula** (product Q2) — drives standings compute + caching shape.
- [ ] **Live-record auto-end** scheduling approach (per-user local midnight) — see performance-and-realtime.md §4.
- [ ] Video constraints in chat (max length / size / codec).
- [ ] Exact VPS sizes for launch.

---

*tech-stack-decisions.md · v1.0 · 2026-10-03 · pattern from Talksy backend docs*
