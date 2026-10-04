[← API index](index.md) · schema [§3](../schema/03-tournaments.md)

# Section 3: Tournaments

Public viewing; **owner-only** writes. Averages = flight duration (seconds), **higher = better**, ranking descending. Pigeon cap per participant per day.

## Browse (any user)
| Method · Path | Auth | → Response | Notes |
|---------------|------|------------|-------|
| `GET /v1/tournaments?tab=all\|following\|mine` | session | cursor → `{ data:[cards] }` | card = `{ id, title, organizer, schedule, pigeon_count, like_count, view_count, is_live, is_following }` (no avg badge on card) |
| `GET /v1/tournaments/{id}` | session | → `{ tournament, overall_avg_seconds, counts, is_following, organizer }` | records a dedup view (`view_count`) |
| `GET /v1/tournaments/{id}/participants` | session | → `{ data:[participant+overall_avg_seconds+position] }` | **standings**, `ORDER BY overall_avg_seconds DESC` |
| `GET /v1/tournaments/{id}/participants/{pid}?day_id=` | session | → `{ participant, days:[{day, avg_seconds, flights:[{pigeon_name, landing_time, duration_seconds}]}], overall_avg_seconds }` | per-day detail (viewer) |
| `GET /v1/t/{link_slug}` | none | → `{ tournament_preview }` | **deep-link resolve** (smart-link landing) |

## Social
| Method · Path | Auth | → | Notes |
|---------------|------|---|-------|
| `POST /v1/tournaments/{id}/follow` / `DELETE` | session | `204` | `follower_count` atomic; follow → notifications on updates |
| `POST /v1/tournaments/{id}/like` / `DELETE` | session | `204` | `like_count` atomic; `tournament.counts` debounced emit |
| `POST /v1/tournaments/{id}/share` | session | `204` | `share_count`++ (returns the `link_slug` URL) |

## Owner — manage (all require `organizer_id == req.user.id`, else `403 forbidden`)
| Method · Path | Auth | Body → | Notes |
|---------------|------|--------|-------|
| `POST /v1/tournaments` | session | `{ title, rules?, cover_upload_id?, num_days, schedule_type, pigeon_count, fly_time, end_time, start_date, organizer_contact? }` → `201 {tournament}` | one txn: insert tournament + `tournament_days` (dates from schedule) + unique `link_slug`. Idempotency-Key |
| `PATCH /v1/tournaments/{id}` | session | partial → `{tournament}` | owner-only |
| `DELETE /v1/tournaments/{id}` | session | `204` | soft delete |
| `POST /v1/tournaments/{id}/participants` | session | `{ name, photo_upload_id?, contact_no?, phone?, address? }` → `201` | owner-only; → `follower-fanout` (participant_added) |
| `PATCH` / `DELETE /v1/tournaments/{id}/participants/{pid}` | session | — | owner-only; soft delete |
| `POST /v1/tournaments/{id}/participants/{pid}/flights` | session | `{ day_id, pigeon_name, landing_time }` → `201 {flight}` | **the core write** — see below |
| `PATCH` / `DELETE /v1/…/flights/{fid}` | session | — | edit/delete a flight → recompute |

### The flight write (`POST …/flights`)
1. owner check → else `403`.
2. **cap check:** recorded flights for `(pid, day_id)` `< pigeon_count` → else `422 pigeon_cap_exceeded`.
3. `duration_seconds = landing_time − tournament_days.release_at` (server-computed).
4. insert `pigeon_flights` + **recompute `participant_day_stats` + `tournament_participants.overall_avg_seconds`/`position`** — all in one `$transaction`.
5. after commit: emit `tournament.update` (room `tournament:{id}`) + enqueue `follower-fanout` (day_results notification).
> A pigeon that didn't return is **never sent** (no row) — it simply isn't recorded (schema §3, T27b).

## Export (share a participant's record)
| `POST /v1/tournaments/{id}/participants/{pid}/export` | session | `{ format: excel\|pdf\|image }` → `202 { job_id }` | runs in `export-generate` worker → file to R2 → link via response poll / push |

**Touches:** sockets `tournament.update`, `tournament.counts`. Queues `follower-fanout`, `export-generate`. Redis `throttle:tournament_counts:{id}`.
