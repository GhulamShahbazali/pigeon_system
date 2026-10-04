# AGENTS.md — PigeonFly Mobile (Flutter)

> **Inherits from:** `../AGENTS.md` (root context — read first, always)
> **Project:** PigeonFly Mobile App (iOS + Android)
> **Stack:** Flutter · Dart · `flutter_bloc` · `get_it` (manual) · `dio` · `go_router` · `flutter_secure_storage` · `socket_io_client` · `firebase_auth` · `firebase_messaging` · `record` · `audioplayers`
> **Last updated:** 2026-10-03 · **Version:** 1.0

Session orientation file for mobile development. Docs are the source of truth — this file navigates to them.

---

## Session Rules (Always Enforced)

- **All code changes go directly into the main branch source** at `/Users/apple/AndroidStudioProjects/pigeon_system/`. Never use worktrees.
- **No code generation.** No `freezed`, no `injectable`, no `json_serializable`, no `build_runner`. All classes and mappers are hand-written.
- **No `get_it` auto-registration.** DI is manual. `injection_container.dart` is the composition root only — feature registrations live in `features/<feature>/di/`.
- **`flutter_bloc` is the only state management library.** No Provider, no Riverpod, no GetX, no ChangeNotifier for state.
- **`Result<T>` everywhere for async operations.** No `dartz`, no `Either`, no raw exceptions crossing into Bloc.
- **`flutter_secure_storage` for tokens and sensitive data.** `SharedPreferences` only for non-sensitive app settings.
- **Backend lives at `/Users/apple/AndroidStudioProjects/pigeon_system/backend/`** (NestJS + Prisma + PostgreSQL). When a mobile change requires a schema/API change, coordinate with backend — never silently assume backend will follow.
- **Root docs are the source of truth for product/schema/API.** Mobile docs cover Flutter patterns only. Never duplicate a decision — link to the root doc.
- **RTL-First Support:** Urdu & Arabic require proper Right-to-Left (RTL) layout. Never hardcode left/right; use start/end and Directionality.

---

## Read These Files First — In Order

**Before any decision, code, or discussion:**

```
1. ../AGENTS.md                              ← Root context, absolute product rules
2. ../docs/product/locked-decisions.md       ← ALL product decisions (LAW)
3. ../docs/product/project-context.md        ← Concept, actors, scope
4. ../docs/technical/schema/index.md         ← Schema index → jump to section file(s) you need
5. ../docs/technical/api/index.md            ← API index → jump to section file(s) you need
6. ../docs/technical/tech-stack-decisions.md ← Approved technology list
7. ../docs/technical/performance-and-realtime.md ← Socket rooms, events, realtime topology
8. ../docs/wireframes/master-wireframes.html ← UI reference (structure + flow)
9. docs/architecture.md                      ← Flutter architecture patterns (this project)
```

**Rules:**
- Never assume a product decision → check `locked-decisions.md`.
- Never invent a schema → check `../docs/technical/schema/<section>.md`.
- Never invent an API contract → check `../docs/technical/api/<section>.md`.
- Never introduce a new library → check `tech-stack-decisions.md` and the approved-stack table below.
- **Don't read every schema/API section for every task.** Each index has a "what to read for X" table — load only the relevant file.

---

## Documentation Map

| File | Contents |
|---|---|
| `../AGENTS.md` | Root context, absolute rules, project navigation |
| `../docs/product/locked-decisions.md` | All product decisions (SSOT) |
| `../docs/product/project-context.md` | Business + strategic context, actors |
| `../docs/product/open-questions.md` | Pending decisions & backlog |
| `../docs/design-system/theme.md` | Brand tokens, colors, typography, RTL rules |
| `../docs/technical/schema/` | Database schema (indexed sections 01–09) |
| `../docs/technical/api/` | API contracts (indexed sections 01–09) |
| `../docs/technical/tech-stack-decisions.md` | Approved technologies |
| `../docs/technical/performance-and-realtime.md` | Socket.io rooms/events, Redis cache, BullMQ queues |
| `../docs/wireframes/` | Wireframes for all 7 mobile modules |
| `docs/architecture.md` | Folder tree, layer rules, `Result<T>`, `Failure`, `UseCase`, `ApiClient`, `DataSource`, `Repository`, `Entity`, `Model`, `Mapper`, `Bloc` structure, DI pattern, string management, validator placement, naming, anti-patterns |

---

## Project Snapshot

**App:** PigeonFly Mobile — social and tournament platform for pigeon-flying (*kabootar bazi*).
**Features:**
- **Tournaments:** Multi-day tournaments, owner-only editing, participant management, landing times, averages (higher is better, unreturned pigeons excluded), live standings, deep-link sharing, contact dialer (WhatsApp/Call).
- **Personal Records:** Loft flight tracking (private or live broadcast), live landing streaming, auto-end at local midnight (00:00).
- **Home & Feed:** Live-now records strip, featured tournaments, Facebook-style posts feed.
- **1-on-1 Chat:** Request-to-talk (TikTok-style acceptance), message status ticks (WhatsApp-style: single, double, blue read), voice notes, photos/videos.
- **Settings & Profile:** 4 languages (Urdu, Hindi, Arabic, English) with RTL support, privacy and notification controls.

**Tech stack:** Flutter (Dart 3+) · `flutter_bloc` · `get_it` (manual) · `dio` · `go_router` · `flutter_secure_storage` · `socket_io_client` · `firebase_auth` · `firebase_messaging` · `record` · `audioplayers` · `cached_network_image`.
**Backend:** NestJS Clean Architecture REST + Socket.io + PostgreSQL (Aiven) + Valkey/Redis + BullMQ + Cloudflare R2.
**Architecture:** Feature-first Clean Architecture (`domain/` → `data/` → `presentation/`). Domain is pure Dart only.
**Auth:** Firebase Auth (Google Sign-In; Apple on iOS) → backend verifies Firebase ID token → backend issues app JWT → stored in `flutter_secure_storage`.

---

## Mobile-Specific Stack (Approved Libraries)

| Layer | Choice | Notes |
|---|---|---|
| Framework | Flutter | Dart 3+ |
| State management | `flutter_bloc` · `equatable` | Not Provider, not Riverpod |
| DI | `get_it` | Manual registration only, no `injectable` |
| Navigation | `go_router` | Declarative routing + deep links |
| HTTP client | `dio` · `connectivity_plus` | Wrapped by `ApiClient`; interceptors for auth + logging |
| WebSocket | `socket_io_client` | Realtime standings, live records, chat, counts, notifications |
| Firebase core | `firebase_core` | Bootstrap for Firebase |
| Auth SDK | `firebase_auth` | Google + Apple Sign-In |
| Google Sign-In | `google_sign_in` | Native Google sheet |
| Apple Sign-In | `sign_in_with_apple` | Native Apple sheet on iOS |
| Push notifications | `firebase_messaging` + `flutter_local_notifications` | FCM |
| Secure storage | `flutter_secure_storage` | Session JWT, refresh token, sensitive keys |
| Preferences | `shared_preferences` | Non-sensitive settings (language, theme) |
| App info | `package_info_plus` | `app_version` for auth payload |
| Device info | `device_info_plus` | `device_id`, `device_type` for auth/device registration |
| Feed viewport | `scrollable_positioned_list` | Viewport tracking — view batching + counts subscribe on stop |
| Image caching | `cached_network_image` | Avatars, post images, pigeon photos |
| Image picker | `image_picker` | Photo capture / gallery selection |
| Audio record | `record` | Chat voice notes |
| Audio playback | `audioplayers` | Chat voice notes playback |
| Fonts | `google_fonts` | Manrope + Plus Jakarta Sans |
| Share | `share_plus` | Share tournament links & export files |
| Path provider | `path_provider` | Local cache/audio files storage |

**Any library outside this table needs explicit approval and an entry in `../docs/technical/tech-stack-decisions.md` before use.**

---

## Design Reference

- **Brand Primary:** `#008080` (Deep Teal / Emerald brand)
- **Fonts:** Manrope (headings/numbers) + Plus Jakarta Sans (body)
- **RTL Support:** Mandatory for Urdu (`ur`) and Arabic (`ar`). Hindi (`hi`) and English (`en`) are LTR.
- Structure and flow → `../docs/wireframes/`
- Design tokens → `../docs/design-system/theme.md`
- Behavior rules → `../docs/product/locked-decisions.md`

---

## Absolute Product Rules

Enforced on client AND server. Full product-decision catalog → `../docs/product/locked-decisions.md`.

1. **Tournament edit/delete is Owner-Only** — only creator can edit details, participants, or record flights.
2. **"Not returned" pigeons are excluded** — pigeons that didn't return are NOT entered; average is calculated strictly over returned pigeons.
3. **Flight duration calculation** — `landing_time - fly_time`. Higher duration wins (endurance ranking).
4. **Live records auto-end at 00:00 local time** — status flips to completed; never deleted.
5. **Chat first-message request** — recipient must Accept before regular messaging starts (TikTok-style).
6. **Chat ticks** — ✓ sent, ✓✓ delivered, ✓✓ blue read; single ✓ if blocked.
7. **Participant share** — export options: Excel (.xlsx), PDF, Text, Image.
8. **Tournament smart deep links** — app installed → open tournament; app not installed → store → open tournament after install.
9. **Passwordless Auth** — Google Sign-in primary.

---

## Environments

| Env | Base URL |
|---|---|
| Dev | `http://localhost:3000` |
| Staging | `https://api-staging.pigeonfly.app` |
| Production | `https://api.pigeonfly.app` |

Auth: app JWT sent as `Authorization: Bearer <token>` header via `AuthInterceptor`.

---

## Before Implementing Changes — Checklist

- [ ] `../docs/product/locked-decisions.md` — is this feature/behavior decided? Do not re-decide.
- [ ] `../docs/technical/schema/` — is the entity defined?
- [ ] `../docs/technical/api/` — is the endpoint defined?
- [ ] `../docs/wireframes/` — is the UI wireframed? Follow the wireframe.
- [ ] `docs/architecture.md` — any dependency rule violations?
- [ ] Data source / repository — accepts `AppLogger`? `debug` + `warning` present?
- [ ] `Result<T>` everywhere async? No raw exceptions reaching the Bloc?
- [ ] Naming: `Entity` / `UseCase` / `Event` / `Bloc` suffixes correct?
- [ ] No Dio in `domain/` or `presentation/`?
- [ ] No `freezed` / `injectable` / `json_serializable` / `build_runner`?
- [ ] All UI strings via `AppStrings` or `<Feature>Strings`?
- [ ] RTL compliance checked? (No hardcoded `.left` / `.right`).
- [ ] DI module in `features/<feature>/di/`, registered from `injection_container.dart`?

---

## Strict Forbidden Patterns

Full catalog → `docs/architecture.md` → Anti-Patterns.

- **Dio imports** in `presentation/` or `domain/` — only in `data/` via `ApiClient`.
- **Domain layer** importing Flutter, Firebase, storage, logging, or third-party — pure Dart only.
- **Bloc calling a repository** directly — always through a use case.
- **Silent `catch`** without emitting a typed `Failure`.
- **`freezed` / `injectable` / `json_serializable` / `build_runner`** — everything hand-written.
- **`dartz` / `Either`** — `Result<T>` only.
- **Any state management** other than `flutter_bloc`.
- **Raw string literals** in widgets, Blocs, or validator methods — use `AppStrings` or `<Feature>Strings`.
- **Hardcoding left/right** in padding or layout — use `EdgeInsetsDirectional` for RTL.
- **`SharedPreferences` for tokens** — `flutter_secure_storage` for anything sensitive.
- **Feature DI module in `core/di/`** — belongs in `features/<feature>/di/`.
- **`injection_container.dart`** importing a datasource, use case, or Bloc — only `register*` functions.
- **PII in logs** (phone, email, full name, chat message).
- **Hardcoded API base URL** — always from `AppEnv`.
- **`socket_io_client`** outside `core/realtime/`; **`firebase_auth`** outside `core/firebase_auth/`.
- **List endpoint** as `NoParamsUseCase` or without pagination params — server always paginates.

---

*Mobile AGENTS.md · Version 1.0 · 2026-10-03*
