[← API index](index.md) · design [bots/index.md](../bots/index.md) · schema §1 (`is_bot`) + `bot_config`

# Section 11: Bots / Liveness (admin)

SuperAdmin-only controls for the content-seeding bot engine (see [bots/index.md](../bots/index.md)). The engine runs in the **scheduler** process and reads `bot_config` + Redis live; the API only reads/writes those, so toggling here takes effect within one tick — no redeploy.

All routes `@Roles('superadmin')`, prefixed `/v1/admin/bots`.

| Method · Path | Body → Response | Notes |
|---------------|-----------------|-------|
| `GET /overview` | → `{ enabled, active_source, total_bots, awake_now, today:{posts,likes,views,follows,tournaments,records}, live_records_now }` | dashboard header. `today.records` = live records created today; `live_records_now` = bot records currently live. Admin UI shows **Posts/Likes/Views/Follows** then **Tournaments/Records/Live now** cards |
| `GET /config` | → `{ data: BotConfig }` | the live knobs |
| `PATCH /config` | partial `BotConfig` → `{ data }` | kill-switch (`enabled`), rates, cooldowns, caps — editable live |
| `GET /roster` | `?offset=&limit=` → `{ data:[bot], meta }` | bot list + `awake_now` per row |
| `GET /active-source` · `POST /active-source` | `{ source: 'schedule'|'manual' }` → `204` | Schedule (UTC windows) vs Manual (picked set) |
| `GET /manual-selection` · `POST /manual-selection` | `{ ids: uuid[] }` → `204` | the Manual-mode awake set |
| `GET /content` | → `{ data: pools }` | caption/image/tournament pool sizes (Content tab). Image pools are weighted by breed: **desi (height / high-flyer) kabootar dominate** (the product's main breed), **racing ~2–4%**, plus a medicine pool for health posts. Desi photos come from `DESI_PHOTO_URLS` (own/R2 URLs); empty → safe fallback to the racing pool |

**`BotConfig`:** `enabled, tickIntervalSec, gapWindowSec, postsPerMin, botPostCooldownMin, likesPerMin, newestBiasPct, maxBotLikesPerPost, viewsPerMin, viewBatchSize, followsPerMin, tournamentsPerDay, recordsPerDay`. (`postsPerMin` default `1` ≈ one post every 1–2 min — a calm, readable feed; admin-tunable.)

**Gradual pacing (realism):** bot content evolves over real time instead of appearing fully-formed:
- **Live records** go live with at most one early bird; the remaining pigeons land one at a time (`doLiveRecordTick`, ~2 landings/min across all live bot records) so watchers see the count tick up.
- **Tournaments** are created in a lifecycle state (upcoming/registering/running/finished); *upcoming* seeds only 2–3 sign-ups. Then `doTournamentTick` (~2–3 updates / 5 min) picks a random active bot tournament and either adds **one participant** (if not started, up to a soft cap of 12) or records **one more pigeon-flight** on a released day (if running). Participant adds stop once the start date is reached (T3b) — bots pass `allowAfterStart` only when backfilling historical/running tournaments at creation.

**Touches:** `bot_config` table; Redis `bots:*` (active_source, manual_selection, cooldowns, rate caps, daily tournament counter). No sockets. Bots act through the real feed/social/tournament/record use-cases, so their activity raises the same `content_like` / `new_follower` / `participant_added` / `tournament_day_results` notifications + counters as real users.
