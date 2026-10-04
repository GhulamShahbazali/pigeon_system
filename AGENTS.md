# AGENTS.md — PigeonFly Root Context

> **For:** code agents and any new chat session. This file is the **map of the whole project** — read it, then open only the one or two files it routes you to. Do **not** read every doc for every task; that wastes tokens. The routing tables below tell you exactly where each answer lives.
> **How to use in a new chat:** paste this file, then describe your task.
> **Last updated:** 2026-10-03 · **Version:** 1.1

---

## 1. Project Identity

| Item | Value |
|------|-------|
| Product | **PigeonFly** |
| Type | Social platform for pigeon-flying (*kabootar bazi*) — tournaments · posts · live personal records · chat |
| Status | Pre-development — product + design + hi-fi wireframes done; mobile & backend docs complete |
| Stack | Flutter (mobile) · **NestJS** (backend) · **Next.js** (admin) · PostgreSQL/Prisma · Socket.io · Redis · BullMQ · R2 · FCM |
| Repo layout | Monorepo — `mobile/` · `backend/` · `admin/` · shared `docs/` |

---

## 2. Read these first (in order)

```
1. docs/product/project-context.md     ← what the product is + actors + scope
2. docs/product/locked-decisions.md    ← SSOT: every product/feature decision (LAW)
3. docs/product/open-questions.md      ← what's still undecided (never guess these in code)
4. docs/technical/tech-stack-decisions.md
5. docs/technical/performance-and-realtime.md   ← realtime + perf + process topology
```

Then jump to the **one** file the routing table (§4) points to for your task.

---

## 3. Documentation Map (every file, one line)

### Product — `docs/product/`
| File | Holds | Status |
|------|-------|--------|
| `project-context.md` | Concept, the 4 actors, scope, principles | ✅ |
| `locked-decisions.md` | **SSOT** — all decisions as ID-tagged rows (G/A/T/P/R/S/AD/M/X); this file wins over code | ✅ |
| `open-questions.md` | Open items + technical TODO backlog; blocking vs secondary | ✅ |

### Design — `docs/design-system/` + `docs/wireframes/`
| File | Holds | Status |
|------|-------|--------|
| `design-system/theme.md` | Brand tokens, type (Manrope/Jakarta), components, RTL/global rules | ✅ |
| `wireframes/master-wireframes.html` | **Index to every flow — open this first** | ✅ |
| `wireframes/ui-high-fidelity.html` | Design overview: theme panel + 6 key screens | ✅ |
| `wireframes/mobile/auth-onboarding-wireframes.html` | Splash · Google sign-in · chooser · profile setup · welcome (5) | ✅ |
| `wireframes/mobile/home-wireframes.html` | Home dashboard — full scroll: live now · featured · feed (4 + content map) | ✅ |
| `wireframes/mobile/tournaments-wireframes.html` | List · create · participants · standings · participant detail (viewer+owner) · record · contact/share dialogs · smart-link landing (14) | ✅ |
| `wireframes/mobile/posts-wireframes.html` | Feed · create · detail · report/hide (4) | ✅ |
| `wireframes/mobile/records-wireframes.html` | My records · Live now list · add/edit pigeons · live (watch+owner) · midnight auto-end · private (8) | ✅ |
| `wireframes/mobile/settings-profile-wireframes.html` | Profile · other user · settings · edit · language · notifications/privacy (6) | ✅ |
| `wireframes/mobile/notifications-wireframes.html` | Notifications list · empty (2) | ✅ |
| `wireframes/mobile/messages-wireframes.html` | Inbox · requests · accept/decline · chat (ticks/voice/image/video) · options · blocked · attach/record (7) | ✅ |
| `wireframes/assets/pigeonfly-ui.css` | Shared hi-fi design-system CSS (change `--brand` → re-skin all) | ✅ |

### Technical — `docs/technical/`
| File | Holds | Status |
|------|-------|--------|
| `tech-stack-decisions.md` | Locked stack + approved libraries (mobile + backend) + environments | ✅ |
| `performance-and-realtime.md` | **Process roles** (API/worker/scheduler) · Socket.io rooms+events · Redis keys · BullMQ queues · debounced counts · **midnight live-end** · fast-endpoint rules · shutdown/scaling | ✅ |
| `schema/index.md` + `schema/01..09` | DB schema — conventions, delete reference, extra best-practices, and 9 section files (users/social · reference · tournaments · posts · records · messages · notifications · settings · moderation). **Durations as `duration_seconds`, denormalized `avg_seconds`, higher = winner, "not returned" = no row.** | ✅ |
| `api/index.md` + `api/01..09` | REST + realtime contract — conventions (base URL, auth, error codes, pagination, idempotency, uploads), auth flow, cross-cutting pipeline, and 9 endpoint sections. Realtime/Redis/queue inventory lives in `performance-and-realtime.md` | ✅ |

### Backend implementation — `backend/`
| File | Holds |
|------|-------|
| `backend/AGENTS.md` | **Backend agent context** (inherits this file) — read before backend work |
| `backend/docs/` | Clean-Architecture `architecture.md` · `patterns.md` · backend `locked-decisions.md` · `environment.md` (Aiven connect) · `index.md` (routing) |

### Mobile implementation — `mobile/`
| File | Holds |
|------|-------|
| `mobile/AGENTS.md` | **Mobile agent context** (inherits this file) — read before Flutter work |
| `mobile/docs/` | Clean-Architecture `architecture.md` (layers, `Result<T>`, `Failure`, `ApiClient`, BLoC, manual DI, RTL) · `index.md` (routing) |

> **Separation:** shared **contracts** (product, schema, api, tech-stack, performance-and-realtime) live in root `docs/`; **backend implementation mechanics** live in `backend/docs/`; **mobile implementation mechanics** live in `mobile/docs/`. The admin (Next.js) will get its own `AGENTS.md` + `docs/` the same way.

---

## 4. Where an answer lives (routing — read ONLY what matches)

| Your task / question | Open |
|----------------------|------|
| Is this product behaviour decided? | `product/locked-decisions.md` |
| Why does the product exist? who are the actors? | `product/project-context.md` |
| Is this still undecided? | `product/open-questions.md` |
| What tech/library am I allowed to use? | `technical/tech-stack-decisions.md` |
| Socket.io room/event · Redis key · BullMQ queue · how counts/presence/midnight-end work · why 2 API processes · how to keep an endpoint fast | `technical/performance-and-realtime.md` |
| What table/column stores this? | `technical/schema/` (⏳ — ask, don't invent) |
| What does this endpoint accept/return, what error code? | `technical/api/` (⏳ — ask, don't invent) |
| Colours, type, spacing, a component, RTL | `design-system/theme.md` |
| What does screen X look like / which screens exist for module Y? | `wireframes/` (per-module file above) |

---

## 5. Product summary (30s)

A user signs in with **Google** and lands on **Home** (live-now strip + featured tournaments + posts feed). Any user can create a **tournament** (single/multi-day, rules, pigeon quantity, fly/end times, every-day or alternate schedule, optional cover image + organizer contact number) and add **participants** (photo + name, optional contact). Tournaments are **public**: anyone can view, **follow**, **like** — counts update **live**; followers get **notifications** when the tournament is created, a participant is added, or a day's flight results are recorded. Only the **creator** can edit/add/delete participants and their day-by-day pigeon detail. Browsing: list → detail (standings, day tabs) → participants → participant detail (that person's pigeons per day, + day & overall averages). A participant's record can be **shared** (Excel/PDF/Text/Image) and the whole tournament via a **smart link** (installed → opens it; not installed → store → opens after install).

Alongside: **Posts** (Facebook-style: image, like/share/view, follow, report, hide); **Personal Records** (daily routine; **private** or **live** — live records show in a "Live now" list, stream landings in real time, and **auto-end at the owner's local midnight**, keeping the record in history); **Chat** (1-to-1, voice/image/video, **TikTok-style** first-message request, block, **WhatsApp ticks** ✓/✓✓/blue, single ✓ when blocked); **Settings** (notifications, privacy, language ur/hi/ar/en with RTL, contact, profile edit); and a **Next.js admin panel** (full moderation + CRUD).

---

## 6. Modules (7) → wireframe + one-line behaviour

| Module | Wireframe | Behaviour |
|--------|-----------|-----------|
| Auth & Onboarding | `auth-onboarding-*` | Google sign-in (passwordless); new users set up a short profile |
| Home | `home-*` | dashboard: live-now · featured tournaments · posts feed |
| Tournaments | `tournaments-*` | create/manage (owner-only), public view, day-by-day standings, live counts, contact + share/deep-link |
| Posts | `posts-*` | public feed, like/share/view, follow, report, hide |
| Personal Records | `records-*` | private or live daily record; Live-now list; midnight auto-end |
| Settings & Profile | `settings-profile-*` | notifications, privacy, 4-language (RTL), edit profile, my content |
| Notifications | `notifications-*` | real-time feed (created/participant/day-results/follow/like/live) |
| Messages & Chat | `messages-*` | 1-1 chat, request-to-talk, block, ticks, voice/image/video |
| Admin panel | ⏳ (web) | full access — reports, posts, tournaments, block users, CRUD |

---

## 7. Most-referenced decisions

| Decision | Value |
|----------|-------|
| Patient/user auth | **Google sign-in** (passwordless); Apple on iOS (optional) |
| Tournament authority | **owner-only** edit/add/delete; everyone else view |
| Visibility | tournaments + posts **public** |
| Realtime | counts (like/view) + notifications + live records are **live** (Socket.io + Redis adapter) |
| Live record auto-end | **00:00 local time** → `live→completed`, un-landed = "Not returned", **never deleted** |
| Chat first message | **one message** → recipient **Accepts** to continue (TikTok-style) |
| Chat ticks | ✓ sent · ✓✓ delivered · ✓✓ blue read; **single ✓ when blocked** |
| Share | participant record (Excel/PDF/Text/Image) + tournament **smart deep link** |
| Languages | **Urdu · Hindi · Arabic · English** (ur/ar = RTL) |
| Storage | Cloudflare R2 (photos, covers, post + chat media) |

Full detail with IDs → `docs/product/locked-decisions.md`.

---

## 8. Absolute rules (cannot be overridden)

1. A tournament is editable **only by its creator**; others view only.
2. Tournaments & published posts are **public**; **soft-delete / hide**, never hard-delete rows referenced elsewhere.
3. Backend (NestJS) and admin (Next.js) are **separate**; the admin uses the API only, never the DB directly.
4. **4 languages** with **RTL** for Urdu/Arabic; never hard-code left/right.
5. Live counts + follower notifications must be **real-time**, not refresh.
6. **`locked-decisions.md` is law** — if code disagrees, the code is wrong.
7. Where a technical doc is ⏳ **pending**, **ask — don't invent** a schema/endpoint/formula.
8. Backend non-negotiables (see `performance-and-realtime.md`): Socket.io **Redis adapter** on every API process · crons/workers **never** in an API process, **one** scheduler · idempotent jobs.

---

## 9. Status

- ✅ Product: context · locked-decisions · open-questions
- ✅ Design: theme + **hi-fi wireframes for all 7 mobile modules** (+ overview + index)
- ✅ Technical: tech-stack · performance-and-realtime · **schema (9 sections)** · **api (9 sections)** · backend AGENTS + docs
- ⏳ Admin panel wireframes
- ⏳ Monorepo split (`mobile/` · `backend/` · `admin/`) + implementation

---

*Root AGENTS.md · v1.1 · 2026-10-03 — navigation hub; structure & best-practices pattern from the Talksy docs.*
*v1.0: initial context. v1.1: turned into a full documentation map + routing tables (token-efficient navigation); added design-system, wireframes, and the two technical docs; added Messages module and the latest locked decisions.*
