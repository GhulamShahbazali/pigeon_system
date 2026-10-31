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
  /** Optional granular detail (participant_name, pigeon_name, landing_time,
   *  contact_no, tournament_title, …) that entity_id alone can't convey. */
  data?: Record<string, any>;
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
        data: input.data ?? undefined,
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
      data: input.data ?? null,
      created_at: n.createdAt.toISOString(),
    });
    this.emit.toUser(input.recipientId, 'notification.bell_count', { unread_count: unread });
    await this.queue.add(QUEUES.pushSend, 'push', { notificationId: n.id });
  }

  // ---- reads ----
  /**
   * Feed hydrated for display: each row carries its actors (name + photo) and a
   * short entity preview (tournament title, post snippet, record date, or the
   * followed user's name). Batched lookups — no N+1.
   */
  async feed(recipientId: string, limit: number) {
    const rows = await this.prisma.notification.findMany({
      where: { recipientId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: { actors: true },
    });

    // Actors (and any 'user' entity) in one batched user lookup.
    const userIds = new Set<string>();
    for (const r of rows) {
      for (const a of r.actors) userIds.add(a.actorId);
      if (r.entityType === 'user') userIds.add(r.entityId);
    }
    const users = userIds.size
      ? await this.prisma.user.findMany({
          where: { id: { in: [...userIds] } },
          select: { id: true, displayName: true, username: true, photoUrl: true },
        })
      : [];
    const userMap = new Map(users.map((u) => [u.id, u]));

    const idsOf = (t: string) => [
      ...new Set(rows.filter((r) => r.entityType === t).map((r) => r.entityId)),
    ];
    const tIds = idsOf('tournament');
    const pIds = idsOf('post');
    const rIds = idsOf('record');
    const [tours, posts, recs] = await Promise.all([
      tIds.length
        ? this.prisma.tournament.findMany({ where: { id: { in: tIds } }, select: { id: true, title: true } })
        : Promise.resolve([] as { id: string; title: string }[]),
      pIds.length
        ? this.prisma.post.findMany({ where: { id: { in: pIds } }, select: { id: true, content: true } })
        : Promise.resolve([] as { id: string; content: string | null }[]),
      rIds.length
        ? this.prisma.personalRecord.findMany({ where: { id: { in: rIds } }, select: { id: true, recordDate: true } })
        : Promise.resolve([] as { id: string; recordDate: Date }[]),
    ]);
    const tMap = new Map(tours.map((t) => [t.id, t.title]));
    const pMap = new Map(posts.map((p) => [p.id, (p.content ?? '').slice(0, 60)]));
    const rMap = new Map(recs.map((r) => [r.id, r.recordDate]));

    return rows.map((r) => {
      const actors = r.actors
        .map((a) => userMap.get(a.actorId))
        .filter((u): u is NonNullable<typeof u> => !!u);
      let entityTitle: string | null = null;
      if (r.entityType === 'tournament') entityTitle = tMap.get(r.entityId) ?? null;
      else if (r.entityType === 'post') entityTitle = pMap.get(r.entityId) || null;
      else if (r.entityType === 'record') {
        const d = rMap.get(r.entityId);
        entityTitle = d ? d.toISOString().slice(0, 10) : null;
      } else if (r.entityType === 'user') {
        entityTitle = userMap.get(r.entityId)?.displayName ?? null;
      }
      return {
        id: r.id,
        type: r.type,
        entityType: r.entityType,
        entityId: r.entityId,
        isRead: r.isRead,
        createdAt: r.createdAt,
        actors,
        entityTitle,
        data: (r.data as Record<string, any> | null) ?? null,
      };
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
