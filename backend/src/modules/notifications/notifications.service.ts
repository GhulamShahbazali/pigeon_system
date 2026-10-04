import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { EmitService } from '../../shared/socket/emit.service';
import { QueueService } from '../../shared/queue/queue.service';
import { QUEUES } from '../../shared/queue/queue.constants';

export interface EmitNotificationInput {
  recipientId: string;
  type: string;
  entityType: 'tournament' | 'post' | 'record' | 'user' | 'conversation';
  entityId: string;
  actorId?: string;
}

@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly emit: EmitService,
    private readonly queue: QueueService,
  ) {}

  /** Single entry point every module calls to raise a notification. */
  async notify(input: EmitNotificationInput): Promise<void> {
    if (input.actorId && input.actorId === input.recipientId) return; // no self-notifications
    const n = await this.prisma.notification.create({
      data: {
        recipientId: input.recipientId,
        type: input.type,
        entityType: input.entityType,
        entityId: input.entityId,
      },
    });
    if (input.actorId) {
      await this.prisma.notificationActor
        .create({ data: { notificationId: n.id, actorId: input.actorId } })
        .catch(() => null);
    }
    const unread = await this.prisma.notification.count({
      where: { recipientId: input.recipientId, isRead: false },
    });
    this.emit.toUser(input.recipientId, 'notification.new', {
      notification_id: n.id,
      type: input.type,
      entity_type: input.entityType,
      entity_id: input.entityId,
      created_at: n.createdAt.toISOString(),
    });
    this.emit.toUser(input.recipientId, 'notification.bell_count', { unread_count: unread });
    await this.queue.add(QUEUES.pushSend, 'push', { notificationId: n.id });
  }

  // ---- reads ----
  async feed(recipientId: string, limit: number) {
    return this.prisma.notification.findMany({
      where: { recipientId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: { actors: true },
    });
  }

  unreadCount(recipientId: string) {
    return this.prisma.notification.count({ where: { recipientId, isRead: false } });
  }

  async markAllRead(recipientId: string): Promise<void> {
    await this.prisma.notification.updateMany({
      where: { recipientId, isRead: false },
      data: { isRead: true },
    });
  }

  async markRead(recipientId: string, id: string): Promise<void> {
    await this.prisma.notification.updateMany({ where: { id, recipientId }, data: { isRead: true } });
  }
}
