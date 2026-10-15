import { Injectable, Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { PushService } from '../../shared/push/push.service';

const TITLES: Record<string, string> = {
  tournament_created: 'New tournament',
  participant_added: 'New participant',
  tournament_day_results: 'Day results posted',
  post_created: 'New post',
  new_follower: 'New follower',
  content_like: 'New like',
  record_live_started: 'Live now',
  message_request: 'Message request',
};

/** Processes push-send jobs: load notification + recipient prefs + devices → FCM. */
@Injectable()
export class PushSendProcessor {
  private readonly logger = new Logger('PushSend');

  constructor(
    private readonly prisma: PrismaService,
    private readonly push: PushService,
  ) {}

  async handle(job: Job<{ notificationId: string }>): Promise<void> {
    const n = await this.prisma.notification.findUnique({ where: { id: job.data.notificationId } });
    if (!n) return;

    const prefs = await this.prisma.userNotificationPreferences.findUnique({
      where: { userId: n.recipientId },
    });
    if (prefs && !prefs.pushEnabled) return;

    const devices = await this.prisma.userDevice.findMany({
      where: { userId: n.recipientId, fcmToken: { not: null } },
      select: { fcmToken: true },
    });
    const tokens = devices.map((d) => d.fcmToken!).filter(Boolean);

    const title = TITLES[n.type] ?? 'PigeonFly';
    await this.push.send(tokens, title, title, {
      type: n.type,
      entity_type: n.entityType,
      entity_id: n.entityId,
    });
  }
}
