# PigeonFly — Bot / Liveness System (Index)

> **Purpose:** Source-of-truth for PigeonFly's content-seeding bot system — read by the **backend** (implements `BotsModule`) and the **admin** (implements the Bots dashboard). Keeps the app feeling **alive and real** before/while real users arrive: posts with images, likes, views, follows (→ real notifications), and racing tournaments across many countries.
> **Pattern:** follows the Talksy bot system, adapted to PigeonFly's domain. **Status:** 🟢 backend engine implemented; admin UI next. **Last updated:** 2026-10-10 · v1.0

---

## 1. What bots do (and don't)

Bots are **real `users` rows** with `is_bot = true`. They act **at the service layer** (in-process, no HTTP/JWT/Firebase) through the **same use-cases real users do** — so every counter, dedup, notification and socket emit is the real one. Five actions:

| Action | Through | Effect |
|--------|---------|--------|
| **Post** | `PostUseCases.create` | image + caption post → feed + `post.new` socket |
| **Like** | `PostUseCases.like` | like count ↑ + `content_like` **notification** to the author |
| **View** | post repo `view` | view count ↑ (de-duped per viewer) |
| **Follow** | `SocialUseCases.follow` | follower graph + `new_follower` **notification** |
| **Tournament** | `CreateTournamentUseCase` (+ participants) | a racing tournament (cover image, city/country, N pigeons) → follower fan-out |

**Boundaries:** bots never message, never appear in moderation, are excluded from "real user" counts via `is_bot`. One kill-switch (`bot_config.enabled`) stops everything.

## 2. Identity
- `users.is_bot = true`, `users.bot_key` (stable, unique → the upsert key), `active_start_hour` / `active_end_hour` (UTC awake window).
- `auth_provider = 'bot'` (new enum value — can never collide with Google/Apple), synthetic `email = bot+<bot_key>@pigeonfly.internal` (never returned by the API).

## 3. Roster (countries)
Curated, culturally-matched personas across the racing world — **PK · IN · BD · AE (UAE) · KW · SA · UK · US · AU** (plus a few more English-speaking). Each bot has a city, a pigeon-racer display name, an avatar URL, and a spread UTC active window. Generated once by `prisma/seed/bots.ts` (idempotent upsert on `bot_key`), then hand-editable.

## 4. Engine (§ runs in the scheduler process only — exactly one)
One tick every `tick_interval_sec`, reads `bot_config` **live** each tick. Computes the **awake set** (Schedule = per-bot UTC window, or Manual = an admin-picked Redis selection), then runs **rate-driven streams** — each emitted action picks its own random awake bot:
- **Posts** gap-fill: bots add only the shortfall vs. posts already in a rolling window (`posts_per_min` target). Per-bot post cooldown.
- **Likes / views** at full rate, newest-biased, with a per-post bot-like cap + per-bot per-minute caps (never "botty").
- **Follows** at a low rate (bot → random real-or-bot user; dedup/blocks handled by the real use-case).
- **Tournaments**: a slow cadence (`tournaments_per_day`) — picks a city/country + a pigeon count from **{1,3,5,7,9,11,15,20}** + a cover image, creates it and adds a handful of participants.

Credit "jars" are capped small so a drought never banks into a burst. The engine never throws out of a tick (`safeTick`).

## 5. Config (DB-backed `bot_config`, singleton id=1)
`enabled`, `tick_interval_sec`, `gap_window_sec`, `posts_per_min`, `bot_post_cooldown_min`, `likes_per_min`, `newest_bias_pct`, `max_bot_likes_per_post`, `views_per_min`, `view_batch_size`, `follows_per_min`, `tournaments_per_day`. Editable live from the admin — the engine reads it fresh each tick, no redeploy.

## 6. Redis state (not DB)
`bots:active_source` (`schedule|manual`), `bots:manual_selection` (set), `bots:cooldown:{id}`, `bots:likes:{postId}` (per-post cap window), `bots:rate:{stream}:{botId}` (per-minute cap).

## 7. Admin dashboard (Next.js, `@Roles('superadmin')`)
Four tabs → API in [`api/11-bots-admin.md`](../api/11-bots-admin.md):
- **Overview** — enabled toggle, awake-now count, today's post/like/view/follow/tournament totals, Schedule/Manual switch.
- **Roster** — the bot list (country, city, window, awake?), Manual-mode selection.
- **Config** — the knobs above (live-editable).
- **Content** — the caption/image/tournament pools the content provider draws from.

## 8. Safety guards
`is_bot` excludes bots from moderation lists + "real user" counts. Kill-switch halts all streams at near-zero cost. Bots never self-like/self-follow. Admin routes are `superadmin`-only.
