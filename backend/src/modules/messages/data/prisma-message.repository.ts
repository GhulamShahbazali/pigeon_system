import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { BlockedError, NotFoundError, ForbiddenError } from '../../../shared/errors/common-errors';
import { MessageRequestPendingError } from '../message.errors';

type SendInput = {
  senderId: string;
  toUserId?: string;
  conversationId?: string;
  type: 'text' | 'voice' | 'image' | 'video';
  body?: string;
  mediaUrl?: string;
  mediaDurationSeconds?: number;
};

function pairKey(a: string, b: string): string {
  return [a, b].sort().join('_');
}

@Injectable()
export class PrismaMessageRepository {
  constructor(private readonly prisma: PrismaService) {}

  private async blocked(a: string, b: string): Promise<boolean> {
    const n = await this.prisma.block.count({
      where: { OR: [{ blockerId: a, blockedId: b }, { blockerId: b, blockedId: a }] },
    });
    return n > 0;
  }

  async send(
    input: SendInput,
  ): Promise<{ message: any; recipientId: string; conversationId: string; isNewRequest: boolean }> {
    return this.prisma.$transaction(
      async (tx) => {
      let convo: any;
      let recipientId: string;
      let isNewRequest = false;

      if (input.conversationId) {
        convo = await tx.conversation.findFirst({
          where: { id: input.conversationId, deletedAt: null },
          include: { participants: true },
        });
        if (!convo) throw new NotFoundError('conversation');
        const other = convo.participants.find((p: any) => p.userId !== input.senderId);
        if (!other) throw new ForbiddenError('Not a participant');
        recipientId = other.userId;
      } else {
        if (!input.toUserId) throw new NotFoundError('recipient');
        recipientId = input.toUserId;
        const key = pairKey(input.senderId, recipientId);
        convo = await tx.conversation.findUnique({ where: { pairKey: key }, include: { participants: true } });
        if (!convo) {
          convo = await tx.conversation.create({
            data: {
              pairKey: key,
              initiatorId: input.senderId,
              status: 'pending',
              participants: {
                create: [{ userId: input.senderId }, { userId: recipientId }],
              },
            },
            include: { participants: true },
          });
        }
      }

      if (await this.blocked(input.senderId, recipientId)) throw new BlockedError();

      if (convo.status === 'pending') {
        if (convo.initiatorId === input.senderId) {
          const cnt = await tx.message.count({ where: { conversationId: convo.id, senderId: input.senderId } });
          if (cnt >= 1) throw new MessageRequestPendingError();
          isNewRequest = true;
        } else {
          await tx.conversation.update({ where: { id: convo.id }, data: { status: 'accepted' } });
        }
      }

      let mediaId: string | undefined;
      if (input.mediaUrl && input.type !== 'text') {
        const media = await tx.messageMedia.create({
          data: {
            kind: input.type as any,
            r2Key: input.mediaUrl,
            url: input.mediaUrl,
            durationSeconds: input.mediaDurationSeconds ?? null,
          },
        });
        mediaId = media.id;
      }

      const message = await tx.message.create({
        data: { conversationId: convo.id, senderId: input.senderId, type: input.type, body: input.body, mediaId },
      });
      await tx.conversation.update({
        where: { id: convo.id },
        data: { lastMessageId: message.id, lastMessageAt: message.createdAt },
      });
      if (mediaId) await tx.messageMedia.update({ where: { id: mediaId }, data: { messageId: message.id } });

        return { message, recipientId, conversationId: convo.id, isNewRequest };
      },
      { timeout: 20000, maxWait: 15000 },
    );
  }

  async accept(conversationId: string, userId: string): Promise<void> {
    const convo = await this.prisma.conversation.findFirst({
      where: { id: conversationId, deletedAt: null },
      include: { participants: true },
    });
    if (!convo) throw new NotFoundError('conversation');
    if (convo.initiatorId === userId) throw new ForbiddenError('Only the recipient can accept');
    if (!convo.participants.some((p) => p.userId === userId)) throw new ForbiddenError();
    await this.prisma.conversation.update({ where: { id: conversationId }, data: { status: 'accepted' } });
  }

  async inbox(userId: string, limit: number) {
    return this.prisma.conversation.findMany({
      where: { status: 'accepted', deletedAt: null, participants: { some: { userId } } },
      orderBy: { lastMessageAt: 'desc' },
      take: limit,
      include: { participants: true },
    });
  }

  /** Batch-fetch user cards (avoids N+1 when enriching the inbox). */
  usersByIds(ids: string[]) {
    if (ids.length === 0) return Promise.resolve([] as any[]);
    return this.prisma.user.findMany({
      where: { id: { in: ids } },
      select: { id: true, displayName: true, username: true, photoUrl: true },
    });
  }

  /** Batch-fetch messages by id (for inbox last-message previews). */
  messagesByIds(ids: string[]) {
    if (ids.length === 0) return Promise.resolve([] as any[]);
    return this.prisma.message.findMany({
      where: { id: { in: ids } },
      select: { id: true, type: true, body: true },
    });
  }

  async requests(userId: string) {
    return this.prisma.conversation.findMany({
      where: { status: 'pending', deletedAt: null, initiatorId: { not: userId }, participants: { some: { userId } } },
      orderBy: { createdAt: 'desc' },
      include: { participants: true },
    });
  }

  async messages(conversationId: string, userId: string, limit: number) {
    const member = await this.prisma.conversationParticipant.findFirst({ where: { conversationId, userId } });
    if (!member) throw new ForbiddenError('Not a participant');
    return this.prisma.message.findMany({
      where: { conversationId, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: { media: true },
    });
  }

  async markRead(conversationId: string, userId: string, uptoMessageId: string): Promise<void> {
    await this.prisma.conversationParticipant.updateMany({
      where: { conversationId, userId },
      data: { lastReadMessageId: uptoMessageId, lastReadAt: new Date() },
    });
  }

  async markDelivered(conversationId: string, userId: string, uptoMessageId: string): Promise<void> {
    await this.prisma.conversationParticipant.updateMany({
      where: { conversationId, userId },
      data: { lastDeliveredMessageId: uptoMessageId },
    });
  }

  /** The OTHER participant's read/delivered pointers — for rendering my sent-ticks. */
  async otherPointers(conversationId: string, userId: string) {
    const other = await this.prisma.conversationParticipant.findFirst({
      where: { conversationId, userId: { not: userId } },
      select: { lastReadMessageId: true, lastDeliveredMessageId: true },
    });
    return {
      lastReadMessageId: other?.lastReadMessageId ?? null,
      lastDeliveredMessageId: other?.lastDeliveredMessageId ?? null,
    };
  }

  async deleteMessage(id: string, userId: string): Promise<void> {
    await this.prisma.message.updateMany({ where: { id, senderId: userId }, data: { deletedAt: new Date() } });
  }

  deleteRequest(conversationId: string, userId: string) {
    return this.prisma.conversation.updateMany({
      where: { id: conversationId, status: 'pending', participants: { some: { userId } } },
      data: { deletedAt: new Date() },
    });
  }
}
