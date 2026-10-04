import { Injectable } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { PushService } from '../../shared/push/push.service';

@Injectable()
export class DmPushProcessor {
  constructor(
    private readonly prisma: PrismaService,
    private readonly push: PushService,
  ) {}

  async handle(job: Job<{ messageId: string; recipientId: string }>): Promise<void> {
    const prefs = await this.prisma.userNotificationPreferences.findUnique({
      where: { userId: job.data.recipientId },
    });
    if (prefs && (!prefs.pushEnabled || !prefs.notifyMessages)) return;

    const [msg, devices] = await Promise.all([
      this.prisma.message.findUnique({ where: { id: job.data.messageId }, select: { type: true, body: true } }),
      this.prisma.userDevice.findMany({
        where: { userId: job.data.recipientId, fcmToken: { not: null } },
        select: { fcmToken: true },
      }),
    ]);
    if (!msg) return;
    const body = msg.type === 'text' ? (msg.body ?? 'New message') : `Sent a ${msg.type}`;
    await this.push.send(
      devices.map((d) => d.fcmToken!).filter(Boolean),
      'New message',
      body,
      { type: 'message' },
    );
  }
}
