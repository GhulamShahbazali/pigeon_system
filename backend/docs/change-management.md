# Backend — Change Management

> How a change propagates without drift. The rule: **docs change before code, and the contract changes before the implementation.**

---

## Where a change starts (by kind)
| Change | Update first | Then |
|--------|--------------|------|
| New/changed product behaviour | `../../docs/product/locked-decisions.md` | downstream schema/api |
| New/renamed table or column | `../../docs/technical/schema/<section>.md` | Prisma model + migration |
| New/changed endpoint or response shape | `../../docs/technical/api/<section>.md` | controller/DTO/response |
| New `error.code` | the API section file | the `DomainError` + filter |
| New Socket.io event / Redis key / BullMQ queue | `../../docs/technical/performance-and-realtime.md` | emit/consumer code |
| New library | `../../docs/technical/tech-stack-decisions.md` | install + use |
| New backend technical rule | `locked-decisions.md` (this folder) | code |
| New Clean-Arch pattern/folder | `architecture.md` / `patterns.md` | code |
| Infra/deploy/env change | `deployment.md` / `environment.md` | pipeline |

If a change doesn't fit an existing doc, **ask before creating a new one** — don't scatter docs.

## Propagation rule (contract → implementation)
1. Product decision locked.
2. Schema section updated → Prisma model → migration (expand/contract if live).
3. API section updated (request/response/error codes) → **mobile + admin see the contract** before backend ships it.
4. Backend implements: use case + repository + controller + tests.
5. Performance doc updated if a socket/redis/queue surface changed.

A contract (schema/api) must never silently diverge from code — a reviewer checks the section file matches the PR.

## Changing an existing module (safe edits)
- **Add a column:** schema doc → migration (nullable or defaulted) → backfill → use it. Never a breaking not-null add on a live table.
- **Change a response shape:** additive first (new field) → mobile adopts → remove old in a later version. Breaking → `/v2`.
- **Change average/duration logic:** update schema §3/§5 + the one `recompute*Stats` service method + a data backfill migration recomputing stored `*_seconds`. One place owns the math.
- **Deprecate an endpoint:** mark in the API doc, keep during a window, then remove.

## Per-module dossier (when implementation starts)
Create `docs/modules/<name>.md` per module: scope, entities, use cases, which queues/sockets it owns, sync status vs schema/api. Keeps a module's moving parts in one place.

## Definition of done for a change
- [ ] Relevant doc(s) updated **in the same PR** as the code.
- [ ] Contract (schema/api) matches implementation.
- [ ] Migration safe on a live DB (expand/contract).
- [ ] Tests per layer updated.
- [ ] No new anti-pattern (`naming-and-anti-patterns.md`).

---

*backend/docs/change-management.md · v1.0 · 2026-10-03*
