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

  accept = (cid: string, uid: string) => this.repo.accept(cid, uid);
  deleteRequest = (cid: string, uid: string) => this.repo.deleteRequest(cid, uid);

  async inbox(userId: string, limit: number) {
    const rows = await this.repo.inbox(userId, limit);
    return rows.map((c: any) => ({
      id: c.id,
      status: c.status,
      last_message_at: c.lastMessageAt ? c.lastMessageAt.toISOString() : null,
      other_user_id: c.participants.find((p: any) => p.userId !== userId)?.userId ?? null,
    }));
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
    const rows = await this.repo.messages(conversationId, userId, limit);
    return rows.map(toMessage);
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
