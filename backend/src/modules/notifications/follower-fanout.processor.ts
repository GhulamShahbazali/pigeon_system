import { Injectable, Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { NotificationsService } from './notifications.service';
import { EmitNotificationInput } from './notifications.service';

export interface FollowerFanoutJob {
  /** The user whose followers should be notified. */
  actorId: string;
  type: string;
  entityType: EmitNotificationInput['entityType'];
  entityId: string;
}

/**
 * Fans a single event out to every follower of `actorId`.
 * Runs in the worker. Paginates follower ids so large audiences stay bounded,
 * and delegates each notification to NotificationsService (idempotent-friendly:
 * BullMQ retries re-run notify(), which only appends — acceptable for MVP).
 */
@Injectable()
export class FollowerFanoutProcessor {
  private readonly logger = new Logger('FollowerFanout');
  private static readonly PAGE = 500;

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  async handle(job: Job<FollowerFanoutJob>): Promise<void> {
    const { actorId, type, entityType, entityId } = job.data;
    let cursor: string | undefined;
    let total = 0;

    for (;;) {
      const page = await this.prisma.follow.findMany({
        where: { followeeId: actorId },
        select: { followerId: true },
        orderBy: { followerId: 'asc' },
        take: FollowerFanoutProcessor.PAGE,
        ...(cursor ? { skip: 1, cursor: { followerId_followeeId: { followerId: cursor, followeeId: actorId } } } : {}),
      });
      if (page.length === 0) break;

      for (const { followerId } of page) {
        await this.notifications.notify({ recipientId: followerId, type, entityType, entityId, actorId });
        total++;
      }
      if (page.length < FollowerFanoutProcessor.PAGE) break;
      cursor = page[page.length - 1].followerId;
    }
    this.logger.log(`Fanned "${type}" (${entityType}:${entityId}) to ${total} follower(s) of ${actorId}`);
  }
}
