[← API index](index.md) · schema [§3](../schema/03-tournaments.md)

# Section 3: Tournaments

Public viewing; **owner-only** writes. Averages = flight duration (seconds), **higher = better**, ranking descending. Pigeon cap per participant per day.

## Browse (any user)
| Method · Path | Auth | → Response | Notes |
|---------------|------|------------|-------|
| `GET /v1/tournaments?tab=all\|upcoming\|ongoing\|past\|mine\|following` | session | cursor → `{ data:[cards] }` | card = `{ id, title, organizer, cover_url, schedule_type, num_days, pigeon_count, status, like_count, view_count, follower_count, is_live, link_slug }`. `is_live` is `true` **ONLY** if tournament is `active` and today matches one of its scheduled flight days (`day.date == today`). `status` ∈ `active`\|`completed`. Default tab: `ongoing`. |

**Filter tabs** (mobile Tournaments screen shows **All · Upcoming · Ongoing · Past**):
- **all** — every non-deleted tournament.
- **upcoming** ("coming soon") — `active` and not started yet: every scheduled day is in the future.
- **ongoing** — `active` and underway: has a day today-or-earlier **and** a day today-or-later (so a race that hasn't started, or is fully past, is excluded). These are the only ones that can carry the **LIVE** tag.
- **past** — `completed`, **or** `active` with all days in the past.
- **mine** / **following** — organizer = me / followed tournaments or organizers.

The mobile card shows the **LIVE** tag only when `is_live`, and a green ✓ "completed" badge next to the share button when `status == 'completed'`.
| `GET /v1/tournaments/by-user/{userId}` | session | `?limit` → `{ data:[card] }` | a given organizer's tournaments, newest first (same card shape + `is_live` as the list). Powers the profile "Tournaments" list |
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
| `POST /v1/tournaments/{id}/participants` | session | `{ name, photo_upload_id?, contact_no?, phone?, address? }` → `201` | owner-only; **locked once started** → `422 tournament_started` when the start date is reached (T3b); → `tournament-fanout` (participant_added, carries `participant_name`) |
| `PATCH` / `DELETE /v1/tournaments/{id}/participants/{pid}` | session | — | owner-only; soft delete |
| `POST /v1/tournaments/{id}/participants/{pid}/flights` | session | `{ day_id, pigeon_name, landing_time }` → `201 {flight}` | **the core write** — owner-only, **today only** (`day.date == today`). See date gating below |
| `PATCH /v1/tournaments/{id}/participants/{pid}/flights/{fid}` | session | `{ pigeon_name?, landing_time? }` → `200 {flight}` | owner-only; allowed on **today and past days**; recomputes day & overall stats |
| `DELETE /v1/tournaments/{id}/participants/{pid}/flights/{fid}` | session | — → `204` | owner-only; allowed on **today and past days**; removes flight and recomputes stats |

### Flight Date Gating & Validation (`POST / PATCH / DELETE …/flights`)
1. **Owner check:** `t.organizer_id == req.user.id` → else `403 forbidden`.
2. **Date gating (T28c):**
   - **Today (`day.date == today`):** Organizer can **Add** (`POST`), **Edit** (`PATCH`), and **Delete** (`DELETE`).
   - **Past Days (`day.date < today`):** Organizer can **Edit** (`PATCH`) and **Delete** (`DELETE`) already entered landings. New flight additions are rejected with `422 past_day_cannot_add`.
   - **Future Days (`day.date > today`):** Deactivated / inactive. Any write is rejected with `422 future_day_inactive`.
3. **Cap check (`POST` only):** recorded flights for `(pid, day_id)` `< pigeon_count` → else `422 pigeon_cap_exceeded`.
4. `duration_seconds = landing_time − tournament_days.release_at` (server-computed).
5. Insert/update/delete `pigeon_flights` + **recompute `participant_day_stats` + `tournament_participants.overall_avg_seconds`/`position`** — all in one `$transaction`.
6. After commit: emit `tournament.update` (room `tournament:{id}`) + enqueue `follower-fanout` (day_results notification).
> A pigeon that didn't return is **never sent** (no row) — it simply isn't recorded (schema §3, T27b).

## Export (share a participant's record)
| `POST /v1/tournaments/{id}/participants/{pid}/export` | session | `{ format: excel\|pdf\|image }` → `202 { job_id }` | runs in `export-generate` worker → file to R2 → link via response poll / push |

**Touches:** sockets `tournament.update`, `tournament.counts`. Queues `follower-fanout`, `export-generate`. Redis `throttle:tournament_counts:{id}`.
