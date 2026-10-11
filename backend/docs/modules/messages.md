[← backend docs](../index.md) · api [§6](../../../docs/technical/api/06-messages.md) · schema [§6](../../../docs/technical/schema/06-messages.md)

# Module: `messages` (1-to-1 chat)

**Scope:** Direct conversations with a TikTok-style request gate, WhatsApp-style ticks, block-aware delivery, text/voice/image/video.
**Layers:** `data` (`prisma-message.repository` — request gate, pairKey, block check) · use cases · presentation (controller) · worker (`dm-push.processor`) · `message.errors`.

**Routes**
| Method · Path | Notes |
|---|---|
| `GET /v1/conversations` · `/conversations/requests` | accepted inbox · pending requests |
| `GET /v1/conversations/:id/messages` | thread |
| `POST /v1/messages` | send (by `to_user_id` or `conversation_id`); idempotency-key |
| `POST /v1/conversations/:id/accept` · `DELETE …/request` | accept / decline request |
| `POST /v1/conversations/:id/read` | read receipt up to a message |
| `DELETE /v1/messages/:id` | delete own message |

**Request gate:** first message to a new person creates a `pending` conversation; sender may send **only one** until the recipient accepts → else `message_request_pending (422)`. Recipient's first reply auto-accepts.
**Delivery:** send wrapped in `$transaction` (`{timeout:20000}` for Aiven); block → `blocked`.
**Queues:** `dmPush` (push to recipient). **Sockets:** `message.new`, `message.request_new`, `chat.read`, `message.deleted` (rooms `chat:{id}` + `user:{id}`).
**Sync status:** ✅ implemented & verified — request→422 on 2nd→accept→inbox→read receipt all green.
**Invariants:** one message per pending request; blocked sender's messages never delivered (single tick).
