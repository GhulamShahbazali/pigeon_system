import { Injectable } from '@nestjs/common';
import { PrismaMessageRepository } from './data/prisma-message.repository';
import { EmitService } from '../../shared/socket/emit.service';
import { QueueService } from '../../shared/queue/queue.service';
import { QUEUES } from '../../shared/queue/queue.constants';

function toMessage(m: any) {
  return {
    id: m.id,
    conversation_id: m.conversationId,
    sender_id: m.senderId,
    type: m.type,
    body: m.body,
    media: m.media
      ? { url: m.media.url, kind: m.media.kind, duration_seconds: m.media.durationSeconds, thumb_url: m.media.thumbUrl }
      : null,
    created_at: m.createdAt.toISOString(),
  };
}

@Injectable()
export class MessageUseCases {
  constructor(
    private readonly repo: PrismaMessageRepository,
    private readonly emit: EmitService,
    private readonly queue: QueueService,
  ) {}

  async send(senderId: string, input: any) {
    const { message, recipientId, conversationId, isNewRequest } = await this.repo.send({
      senderId,
      toUserId: input.to_user_id,
      conversationId: input.conversation_id,
      type: input.type,
      body: input.body,
      mediaUrl: input.media_url,
      mediaDurationSeconds: input.media_duration_seconds,
    });
    const payload = toMessage(message);
    this.emit.toRoom(`chat:${conversationId}`, 'message.new', payload);
    this.emit.toUser(recipientId, 'message.new', payload);
    if (isNewRequest) {
      this.emit.toUser(recipientId, 'message.request_new', {
        conversation_id: conversationId,
        sender_id: senderId,
      });
    }
    await this.queue.add(QUEUES.dmPush, 'dm', { messageId: message.id, recipientId });
    return payload;
  }

  findWith = (uid: string, otherId: string) => this.repo.findWith(uid, otherId);
  accept = (cid: string, uid: string) => this.repo.accept(cid, uid);
  deleteRequest = (cid: string, uid: string) => this.repo.deleteRequest(cid, uid);

  async inbox(userId: string, limit: number) {
    const rows = await this.repo.inbox(userId, limit);
    // Enrich in TWO batched queries (not N+1) so the mobile makes a single call —
    // important on a high-latency DB where every round-trip costs ~100-200ms.
    const otherIds = [
      ...new Set(
        rows
          .map((c: any) => c.participants.find((p: any) => p.userId !== userId)?.userId)
          .filter(Boolean) as string[],
      ),
    ];
    const lastMsgIds = rows.map((c: any) => c.lastMessageId).filter(Boolean) as string[];
    const [users, lastMsgs] = await Promise.all([
      this.repo.usersByIds(otherIds),
      this.repo.messagesByIds(lastMsgIds),
    ]);
    const userMap = new Map(users.map((u: any) => [u.id, u]));
    const msgMap = new Map(lastMsgs.map((m: any) => [m.id, m]));

    return rows.map((c: any) => {
      const otherId = c.participants.find((p: any) => p.userId !== userId)?.userId ?? null;
      const u = otherId ? userMap.get(otherId) : null;
      const lm = c.lastMessageId ? msgMap.get(c.lastMessageId) : null;
      return {
        id: c.id,
        status: c.status,
        last_message_at: c.lastMessageAt ? c.lastMessageAt.toISOString() : null,
        other_user_id: otherId,
        other_user: u
          ? { id: u.id, display_name: u.displayName, username: u.username, photo_url: u.photoUrl }
          : null,
        last_message: lm ? { type: lm.type, body: lm.body } : null,
      };
    });
  }

  async requests(userId: string) {
    const rows = await this.repo.requests(userId);
    return rows.map((c: any) => ({
      id: c.id,
      initiator_id: c.initiatorId,
      created_at: c.createdAt.toISOString(),
    }));
  }

  async messages(conversationId: string, userId: string, limit: number) {
    const rows = await this.repo.messages(conversationId, userId, limit); // newest first
    // Opening a chat = reading it. Mark the viewer delivered + read up to the newest
    // message and tell the other side so their sent-ticks turn (grey→grey✓✓→green✓✓).
    const newest = rows[0];
    if (newest) {
      await Promise.all([
        this.repo.markRead(conversationId, userId, newest.id),
        this.repo.markDelivered(conversationId, userId, newest.id),
      ]);
      this.emit.toRoom(`chat:${conversationId}`, 'chat.delivered', {
        user_id: userId,
        last_delivered_message_id: newest.id,
      });
      this.emit.toRoom(`chat:${conversationId}`, 'chat.read', {
        user_id: userId,
        last_read_message_id: newest.id,
        last_read_at: new Date().toISOString(),
      });
    }
    const other = await this.repo.otherPointers(conversationId, userId);
    return {
      messages: rows.map(toMessage),
      other_last_read_message_id: other.lastReadMessageId,
      other_last_delivered_message_id: other.lastDeliveredMessageId,
    };
  }

  async read(conversationId: string, userId: string, uptoMessageId: string) {
    await this.repo.markRead(conversationId, userId, uptoMessageId);
    this.emit.toRoom(`chat:${conversationId}`, 'chat.read', {
      user_id: userId,
      last_read_message_id: uptoMessageId,
      last_read_at: new Date().toISOString(),
    });
  }

  async deleteMessage(id: string, userId: string, conversationId: string) {
    await this.repo.deleteMessage(id, userId);
    this.emit.toRoom(`chat:${conversationId}`, 'message.deleted', { message_id: id });
  }
}
