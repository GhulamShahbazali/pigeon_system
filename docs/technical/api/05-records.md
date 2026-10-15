[← API index](index.md) · schema [§5](../schema/05-records.md)

# Section 5: Personal Records

Own daily routine. Private (stored) or live (broadcast). Same duration/average model as tournaments. Auto-ends at the owner's local midnight.

| Method · Path | Auth | Body → | Notes |
|---------------|------|--------|-------|
| `GET /v1/me/records` | session | cursor → `{ data:[record] }` | "My records" (private + live) |
| `GET /v1/records/live` | session | → `{ data:[live record previews] }` | **"Live now"** — live records (`privacy=live`, `status=open`). Owners you **follow** come first; if that yields fewer than `limit`, the rest is filled with other users' live records (discovery) so a new user who follows no one still sees who is live. Never your own. Preview = `{ id, total_avg_seconds, returned_count, total_pigeons, like_count, view_count, owner:{id,display_name,username,photo_url} }` |
| `GET /v1/records/{id}` | session | → `{ record, pigeons:[…], total_avg_seconds, returned_count }` | owner sees private; others only if live |
| `POST /v1/me/records` | session | `{ record_date, fly_time, total_pigeons, privacy }` → `201 {record}` | `privacy` default `private` |
| `PATCH /v1/records/{id}` | session | partial → `{record}` | owner only |
| `POST /v1/records/{id}/go-live` | session | → `{record}` | set live; compute `auto_end_at` (owner tz); add to `live_records:active`; enqueue delayed `live-record-auto-end` (`jobId=record-end:{id}`); emit `record.live_started` + fanout |
| `POST /v1/records/{id}/end` | session | → `{record}` | manual end (`live→completed`), emit `record.live_ended` |
| `POST /v1/records/{id}/pigeons` | session | `{ pigeon_name, landing_time }` → `201` | compute `duration_seconds`; recompute `total_avg_seconds` in txn; if live → `record.update` emit; cap `returned_count < total_pigeons` |
| `PATCH` / `DELETE /v1/records/{id}/pigeons/{pid}` | session | — | owner; recompute |
| `POST /v1/records/{id}/like` / `DELETE` | session | `204` | live records; `record.counts` debounced |

**Touches:** sockets `record.update/.counts/.live_started/.live_ended`. Queues `live-record-auto-end`, `follower-fanout`. Redis `live_records:active`, `throttle:record_counts:{id}`.
