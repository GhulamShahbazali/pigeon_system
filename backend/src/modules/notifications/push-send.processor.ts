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

/** "2026-10-29T13:05:00.000Z" → "13:05" (UTC HH:MM); null-safe. */
function hhmm(iso?: string): string | null {
  if (!iso) return null;
  const d = new Date(iso);
  return Number.isNaN(d.getTime())
    ? null
    : `${String(d.getUTCHours()).padStart(2, '0')}:${String(d.getUTCMinutes()).padStart(2, '0')}`;
}

function quote(s?: string | null): string | null {
  return s ? `"${s}"` : null;
}

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
    if (tokens.length === 0) return;

    const title = TITLES[n.type] ?? 'PigeonFly';
    const body = await this.buildBody(n);
    await this.push.send(tokens, title, body, {
      type: n.type,
      entity_type: n.entityType,
      entity_id: n.entityId,
    });
  }

  /** A specific, human one-liner for the push body — uses the stored granular
   *  `data`, the triggering actor's name, and resolves a title when needed. */
  private async buildBody(n: {
    id: string;
    type: string;
    entityType: string;
    entityId: string;
    data: unknown;
  }): Promise<string> {
    const d = (n.data as Record<string, any> | null) ?? null;

    // Triggering actor (first one) — best-effort, for a personal "X did Y".
    const actor = await this.prisma.notificationActor.findFirst({
      where: { notificationId: n.id },
      orderBy: { createdAt: 'asc' },
      select: { actorId: true },
    });
    let who = 'Someone';
    if (actor) {
      const u = await this.prisma.user.findUnique({
        where: { id: actor.actorId },
        select: { displayName: true },
      });
      if (u?.displayName) who = u.displayName;
    }

    // Tournament title: from data, else a light lookup for the follower-fanout
    // path (tournament_created carries no data).
    let tournamentTitle: string | undefined = d?.tournament_title;
    if (!tournamentTitle && n.entityType === 'tournament') {
      const t = await this.prisma.tournament.findUnique({
        where: { id: n.entityId },
        select: { title: true },
      });
      tournamentTitle = t?.title ?? undefined;
    }
    const where = quote(tournamentTitle) ?? 'a tournament you follow';

    switch (n.type) {
      case 'tournament_created':
        return `${who} created the tournament ${where}`;
      case 'participant_added': {
        const name = d?.participant_name as string | undefined;
        return name ? `${name} joined ${where}` : `A new participant joined ${where}`;
      }
      case 'tournament_day_results': {
        const name = (d?.participant_name as string | undefined) ?? 'A loft';
        const pigeon = d?.pigeon_name as string | undefined;
        const at = hhmm(d?.landing_time as string | undefined);
        const contact = d?.contact_no as string | undefined;
        const parts = [`${name}'s pigeon`];
        if (pigeon) parts.push(quote(pigeon)!);
        parts.push(at ? `landed at ${at}` : 'landed');
        parts.push(`in ${where}`);
        let line = parts.join(' ');
        if (contact) line += ` · ${contact}`;
        return line;
      }
      case 'post_created':
        return `${who} shared a new post`;
      case 'content_like':
        return `${who} liked your ${n.entityType === 'record' ? 'record' : 'post'}`;
      case 'record_live_started':
        return `${who} is flying live now`;
      case 'new_follower':
        return `${who} started following you`;
      case 'message_request':
        return `${who} sent you a message request`;
      default:
        return TITLES[n.type] ?? 'You have a new notification';
    }
  }
}
