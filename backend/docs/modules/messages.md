[← backend docs](../index.md) · api [§6](../../../docs/technical/api/06-messages.md) · schema [§6](../../../docs/technical/schema/06-messages.md)

# Module: `messages` (1-to-1 chat)

**Scope:** Direct conversations with a TikTok-style request gate, WhatsApp-style ticks, block-aware delivery, text/voice/image/video.
**Layers:** `data` (`prisma-message.repository` — request gate, pairKey, block check) · use cases · presentation (controller) · worker (`dm-push.processor`) · `message.errors`.

**Routes**
| Method · Path | Notes |
|---|---|
| `GET /v1/conversations` · `/conversations/requests` | accepted inbox · pending requests |
| `GET /v1/conversations/:id/messages` | thread |
| `POST /v1/media` | upload chat media (multipart `file`) → `{ url, kind, size }`; see [`media`](media.md) |
| `POST /v1/messages` | send (by `to_user_id` or `conversation_id`); `text` needs `body`, media needs `media_url` (+ optional `media_duration_seconds`) |
| `POST /v1/conversations/:id/accept` · `DELETE …/request` | accept / decline request |
| `POST /v1/conversations/:id/read` | read receipt up to a message |
| `DELETE /v1/messages/:id` | delete own message |

**Request gate:** first message to a new person creates a `pending` conversation; sender may send **only one** until the recipient accepts → else `message_request_pending (422)`. Recipient's first reply auto-accepts.
**Delivery:** send wrapped in `$transaction` (`{timeout:20000}` for Aiven); block → `blocked`.
**Queues:** `dmPush` (push to recipient). **Sockets:** `message.new`, `message.request_new`, `chat.read`, `chat.delivered`, `message.deleted` (rooms `chat:{id}` + `user:{id}`).
**Receipts (ticks):** `GET …/messages` marks the caller read + delivered up to the newest message, emits `chat.read` + `chat.delivered`, and returns the other participant's `last_read_message_id` / `last_delivered_message_id`. The mobile renders single ✓ (sent), double grey ✓✓ (delivered), double green ✓✓ (seen).
**Media:** voice/image/video messages carry a `media_url` pointing at a file uploaded via `POST /v1/media` (stored in the project `uploads/` folder, served at `/uploads/…` — see the [`media`](media.md) module). `media_duration_seconds` is stored on `MessageMedia` for voice notes.
**Mobile:** inbox + chat are wired to this API (no static data). Voice recorded with `record`, played with `just_audio`; video played with `video_player`; new messages arrive over `message.new` after `chat.subscribe`.
**Sync status:** ✅ implemented & verified — request→422 on 2nd→accept→inbox→read receipt all green; media upload + voice/image/video send wired end-to-end.
**Invariants:** one message per pending request; blocked sender's messages never delivered (single tick).
