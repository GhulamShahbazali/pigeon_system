# PigeonFly

> The home ground for pigeon-flying — run your tournament, follow the flights live, and share your loft.

PigeonFly is a social platform for the pigeon-flying community (*kabootar bazi*): organizers run **tournaments**, enthusiasts follow the flights with **live** results, share **posts**, and keep **personal daily records** — with a web **admin panel** for moderation.

## Status

Pre-development. **Product docs are being written and locked first** (this is that stage). Implementation follows.

| Area | Status |
|------|--------|
| Product concept + actors | 🟡 Drafted |
| Product decisions | 🟡 Locked v1.0 (some client-facing items open) |
| Tech stack | ⏳ To confirm |
| Database schema | ⏳ Not started |
| API contract | ⏳ Not started |
| Mobile app | ⏳ Fresh Flutter scaffold |
| Backend | ⏳ Not started |
| Admin panel | ⏳ Not started |

## Modules

1. **Tournaments** — single/multi-day competitions, participants, public viewing, follow/like/view live, follower notifications, per-day & overall averages.
2. **Posts** — Facebook-style public feed: image, like/share/view, follow, report, hide.
3. **Personal Records** — daily flight log, private or broadcast live to followers.
4. **Settings & Profile** — notifications, privacy, 4-language support (Urdu/Hindi/Arabic/English), contact, profile edit.
5. **Admin Panel (web)** — full moderation + CRUD over everything.

## Documentation

Start at **[`docs/README.md`](docs/README.md)**. The source of truth is **[`docs/product/locked-decisions.md`](docs/product/locked-decisions.md)**.

For AI agents / new chat sessions, read **[`AGENTS.md`](AGENTS.md)** first.

## Tech Stack (assumed — confirm)

| Layer | Choice |
|-------|--------|
| Mobile | Flutter |
| Backend | NestJS + PostgreSQL/Prisma |
| Admin | Next.js |
| Realtime | Socket.io |
| Push | FCM |

---

*Project structure and docs conventions follow the Talksy pattern.*
