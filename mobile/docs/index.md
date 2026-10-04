# Mobile Docs — Index (routing)

> Start here for Flutter mobile work. **Read only what your task needs.** Shared contracts live in `../../docs/`; this folder is Flutter mobile implementation mechanics.

---

## Reading order by task

| I'm working on… | Read |
|-----------------|------|
| Anything mobile (first time) | `../AGENTS.md` → `architecture.md` → `../../docs/design-system/theme.md` |
| Folder placement, layers, DI, adding a feature | `architecture.md` §1–§4, §16 |
| Writing an entity / use case / repository / model / mapper | `architecture.md` §9–§15 |
| BLoC state management & events | `architecture.md` §17 |
| Error handling, Result pattern & Failure hierarchy | `architecture.md` §6–§8 |
| RTL, fonts, typography & strings (Urdu / Arabic / Hindi / English) | `architecture.md` §18 + `../../docs/design-system/theme.md` |
| Realtime events & Socket.io rooms (standings, chat, records) | `../../docs/technical/performance-and-realtime.md` |
| Screen layout & user flow | `../../docs/wireframes/` (per-module HTML wireframes) |
| What an endpoint accepts/returns, error codes | `../../docs/technical/api/<section>.md` |
| Is this product behavior decided? | `../../docs/product/locked-decisions.md` (SSOT) |
| Forbidden patterns & anti-patterns | `architecture.md` §22 |

---

## Mobile docs in this folder

| File | Holds |
|------|-------|
| `architecture.md` | Feature-First Clean Architecture (`domain → data → presentation`), `Result<T>`, `Failure`, `ApiClient`, `DataSource`, `RepositoryImpl`, BLoC, manual DI (`get_it`), RTL layout rules, anti-patterns |

---

*mobile/docs/index.md · v1.0 · 2026-10-03*
