# PigeonFly — Documentation Index

Shared source of truth for all surfaces (mobile · backend · admin). **Read product docs before writing any code.**

## Product

| File | What it holds |
|------|---------------|
| [`product/project-context.md`](product/project-context.md) | Product concept, actors, and the scope of each module. Start here. |
| [`product/locked-decisions.md`](product/locked-decisions.md) | **SSOT** — every product/feature decision. This file is law. |
| [`product/open-questions.md`](product/open-questions.md) | Everything still undecided + the TODO backlog. Nothing here may be guessed in code. |

## Technical (⏳ pending)

| File | Status |
|------|--------|
| `technical/tech-stack-decisions.md` | ⏳ Not written — confirm Flutter / NestJS / Next.js / Postgres |
| `technical/tech-stack-decisions.md` | ✅ Locked stack (Flutter · NestJS · Postgres/Prisma · Socket.io · Redis · BullMQ · R2 · FCM) |
| `technical/performance-and-realtime.md` | ✅ Process roles · Socket.io rooms · Redis keys · BullMQ queues · fast-endpoint rules |
| `technical/schema/` | ✅ Index + 9 sections (users/social · reference · tournaments · posts · records · messages · notifications · settings · moderation) |
| `technical/api/` | ✅ Index + 9 sections (auth · users-social · tournaments · posts · records · messages · notifications · settings · moderation-admin) |
| `backend/AGENTS.md` + `backend/docs/` | ✅ Backend implementation (architecture · patterns · locked-decisions · environment) |

## Design system

| File | What it holds |
|------|---------------|
| [`design-system/theme.md`](design-system/theme.md) | Brand tokens, type, components, RTL/globalization |

## Wireframes

| File | What it holds |
|------|---------------|
| [`wireframes/master-wireframes.html`](wireframes/master-wireframes.html) | Index to all flows (open this first) |
| [`wireframes/ui-high-fidelity.html`](wireframes/ui-high-fidelity.html) | Design overview — theme + 6 key screens |
| `wireframes/mobile/*.html` | Hi-fi screens per module (auth · home · tournaments · posts · records · settings · notifications · messages) |

---

## Reading order for a new session

```
1. ../AGENTS.md                      ← root context + absolute rules
2. product/project-context.md        ← what & who
3. product/locked-decisions.md       ← what's decided
4. product/open-questions.md         ← what's not
```

*docs/README.md · 2026-10-03*
