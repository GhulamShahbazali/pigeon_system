[← API index](index.md) · schema [§6](../schema/06-messages.md)

# Section 6: Messages & Chat

1-to-1. First message = request (one message until accepted). Block stops delivery (single ✓). Ticks derived.

| Method · Path | Auth | Body → | Notes |
|---------------|------|--------|-------|
| `GET /v1/conversations` | session | cursor → `{ data:[inbox rows] }` | `status='accepted'` convos, by `last_message_at`. Each row is **enriched server-side** (2 batched queries, no N+1): `{ id, status, last_message_at, other_user_id, other_user:{id,display_name,username,photo_url}, last_message:{type,body} }` so the client renders the inbox in **one** call |
| `GET /v1/conversations/requests` | session | → `{ data:[…] }` | where I'm recipient & `status='pending'` |
| `GET /v1/conversations/{id}/messages` | session | → `{ data:{ messages:[newest-first], other_last_read_message_id, other_last_delivered_message_id } }` | scrollback; block-checked. **Opening = reading**: marks the caller read + delivered up to the newest message and emits `chat.read` + `chat.delivered` to the room, and returns the **other** participant's read/delivered pointers so the client can render WhatsApp-style sent-ticks |
| `POST /v1/media` | session | multipart `file` → `{ data:{ url, kind, size } }` | uploads chat media (voice/image/video) to the project `uploads/media/` folder; returns an absolute URL. `kind` derived from mimetype (audio→voice, image→image, video→video). Max 25 MB. Served statically at `/uploads/…` (outside the `/v1` prefix) |
| `POST /v1/messages` | session | `{ to_user_id? \| conversation_id?, type, body?, media_url?, media_duration_seconds? }` → `201 {message}` | `text` needs `body`; `voice`/`image`/`video` need `media_url` (from `POST /v1/media`). `media_duration_seconds` stored for voice notes. Creates conversation on first message (`status=pending`). **Block check every send**; **request gate**: initiator may send only 1 until accepted (`422 message_request_pending`). Emits `message.new` (to `chat:{id}` room + recipient `user:{id}`); enqueue `dm-push-send` |
| `POST /v1/conversations/{id}/accept` | session | `204` | recipient accepts → `status=accepted`; both can now send |
| `DELETE /v1/conversations/{id}/request` | session | `204` | decline/delete request |
| `POST /v1/messages/{id}/read` | session | `{ up_to_message_id }` → `204` | advances `last_read_message_id` → `chat.read` (ticks → blue) |
| `DELETE /v1/messages/{id}` | session | `204` | delete-for-both; `message.deleted` |

**Ticks (WhatsApp-style, implemented):** single grey ✓ = sent; double grey ✓✓ = the recipient's `last_delivered_message_id` reached this message; double **green** ✓✓ = their `last_read_message_id` reached it (seen). The client renders these by comparing each of its own messages' position against the other participant's pointers (from the messages response on load, then live via `chat.read` / `chat.delivered` sockets). Blocked → delivered never advances → stays single ✓.
**Smooth scroll:** the mobile chat uses a `reverse` list so it opens pinned to the newest message (no scroll jump), and new messages slot in at the bottom — like WhatsApp.
**Media (current MVP — local disk):** client uploads the file to `POST /v1/media` (multipart), gets back an absolute `url`, then sends a message with `type` = voice/image/video and `media_url` set. Files live in the project `uploads/media/` folder and are served statically from `/uploads/…`. Base host comes from the request (LAN IP in dev, public host behind the proxy in prod); override with `PUBLIC_BASE_URL`. `uploads/` is gitignored. A future phase can swap the `POST /media` storage for object storage (e.g. DigitalOcean Spaces) without changing the message contract.
**Mobile client:** `POST /media` via `ApiClient.upload()` (multipart); voice recorded with the `record` package, played with `just_audio`; video played with `video_player`. The chat + inbox are wired to the live API (no static data) and receive new messages over the `message.new` socket event after `chat.subscribe`.
**Touches:** sockets `message.new/.deleted`, `message.request_new`, `chat.read`, `chat.subscribe/.unsubscribe`. Queues `dm-push-send`.
