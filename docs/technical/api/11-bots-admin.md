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
| `GET /content` | → `{ data: pools }` | caption/image/tournament pool sizes (Content tab) |

**`BotConfig`:** `enabled, tickIntervalSec, gapWindowSec, postsPerMin, botPostCooldownMin, likesPerMin, newestBiasPct, maxBotLikesPerPost, viewsPerMin, viewBatchSize, followsPerMin, tournamentsPerDay, recordsPerDay`. (`postsPerMin` default `1` ≈ one post every 1–2 min — a calm, readable feed; admin-tunable.)

**Touches:** `bot_config` table; Redis `bots:*` (active_source, manual_selection, cooldowns, rate caps, daily tournament counter). No sockets. Bots act through the real feed/social/tournament use-cases, so their activity raises the same `content_like` / `new_follower` notifications + counters as real users.
