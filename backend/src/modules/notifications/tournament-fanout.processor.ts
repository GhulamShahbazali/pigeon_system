import { Injectable, Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { NotificationsService } from './notifications.service';

export interface TournamentFanoutJob {
  tournamentId: string;
  organizerId: string;
  /** participant_added | tournament_day_results */
  type: string;
  /** the tournament id (entity the notification points at) */
  entityId: string;
}

/**
 * Fans a tournament update out to everyone who should hear about it:
 * the organizer's followers AND the people who follow the tournament itself
 * (deduped). Someone who follows only the tournament still gets its updates;
 * someone who follows only the organizer gets them too — each person once.
 * Runs in the worker.
 */
@Injectable()
export class TournamentFanoutProcessor {
  private readonly logger = new Logger('TournamentFanout');

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  async handle(job: Job<TournamentFanoutJob>): Promise<void> {
    const { tournamentId, organizerId, type, entityId } = job.data;

    const [orgFollowers, tourFollowers] = await Promise.all([
      this.prisma.follow.findMany({ where: { followeeId: organizerId }, select: { followerId: true } }),
      this.prisma.tournamentFollow.findMany({ where: { tournamentId }, select: { userId: true } }),
    ]);

    const recipients = new Set<string>();
    for (const f of orgFollowers) recipients.add(f.followerId);
    for (const f of tourFollowers) recipients.add(f.userId);
    recipients.delete(organizerId); // never notify the organizer about their own action

    let total = 0;
    for (const recipientId of recipients) {
      await this.notifications.notify({
        recipientId,
        type,
        entityType: 'tournament',
        entityId,
        actorId: organizerId,
      });
      total++;
    }
    this.logger.log(`Fanned "${type}" (tournament:${entityId}) to ${total} recipient(s)`);
  }
}
