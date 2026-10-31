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
  /** Raw specifics the use-case already holds; the processor resolves the rest
   *  (tournament title, participant name/contact) and builds the stored `data`. */
  participantId?: string;
  participantName?: string; // participant_added — already known at enqueue time
  pigeonName?: string; // tournament_day_results
  landingTime?: string; // tournament_day_results (ISO)
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
    const { tournamentId, organizerId, type, entityId, participantId, participantName, pigeonName, landingTime } =
      job.data;

    const [orgFollowers, tourFollowers, tournament, participant] = await Promise.all([
      this.prisma.follow.findMany({ where: { followeeId: organizerId }, select: { followerId: true } }),
      this.prisma.tournamentFollow.findMany({ where: { tournamentId }, select: { userId: true } }),
      this.prisma.tournament.findUnique({ where: { id: tournamentId }, select: { title: true } }),
      participantId
        ? this.prisma.tournamentParticipant.findUnique({
            where: { id: participantId },
            select: { name: true, contactNo: true, phone: true },
          })
        : Promise.resolve(null),
    ]);

    // Build the granular detail once (same for every recipient of this event).
    const data: Record<string, any> = {};
    if (tournament?.title) data.tournament_title = tournament.title;
    const pName = participant?.name ?? participantName;
    if (pName) data.participant_name = pName;
    if (type === 'tournament_day_results') {
      if (pigeonName) data.pigeon_name = pigeonName;
      if (landingTime) data.landing_time = landingTime;
      const contact = participant?.contactNo ?? participant?.phone;
      if (contact) data.contact_no = contact;
    }
    const payload = Object.keys(data).length ? data : undefined;

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
        data: payload,
      });
      total++;
    }
    this.logger.log(`Fanned "${type}" (tournament:${entityId}) to ${total} recipient(s)`);
  }
}
