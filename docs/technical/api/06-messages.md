[← API index](index.md) · schema [§6](../schema/06-messages.md)

# Section 6: Messages & Chat

1-to-1. First message = request (one message until accepted). Block stops delivery (single ✓). Ticks derived.

| Method · Path | Auth | Body → | Notes |
|---------------|------|--------|-------|
| `GET /v1/conversations` | session | cursor → `{ data:[inbox rows] }` | `status='accepted'` convos, by `last_message_at` |
| `GET /v1/conversations/requests` | session | → `{ data:[…] }` | where I'm recipient & `status='pending'` |
| `GET /v1/conversations/{id}/messages` | session | cursor → `{ data:[message] }` | scrollback; block-checked |
| `POST /v1/messages` | session | `{ to_user_id? \| conversation_id?, type, body?, media_upload_id? }` → `201 {message}` | creates conversation on first message (`status=pending`). **Block check every send**; **request gate**: initiator may send only 1 until accepted (`422 message_request_pending`). Emits `message.new`; enqueue `dm-push-send`. Idempotency-Key |
| `POST /v1/conversations/{id}/accept` | session | `204` | recipient accepts → `status=accepted`; both can now send |
| `DELETE /v1/conversations/{id}/request` | session | `204` | decline/delete request |
| `POST /v1/messages/{id}/read` | session | `{ up_to_message_id }` → `204` | advances `last_read_message_id` → `chat.read` (ticks → blue) |
| `DELETE /v1/messages/{id}` | session | `204` | delete-for-both; `message.deleted` |

**Ticks:** ✓ = created; ✓✓ = recipient's `last_delivered_message_id`; blue = `last_read_message_id`. Blocked → delivered never advances → stays single ✓.
**Media:** upload first (`POST /v1/uploads` purpose `chat_image`/`chat_video`/`voice_note`) → pass `media_upload_id`.
**Touches:** sockets `message.new/.deleted`, `message.request_new`, `chat.typing/.recording/.read`. Queues `dm-push-send`, `message-request-push`, `media-process`. Redis `typing:*`, `recording:*`, `rate_limit:messages`.
