import { Inject, Injectable } from '@nestjs/common';
import { PostUseCases } from '../../posts/post.use-cases';
import { PrismaPostRepository } from '../../posts/data/prisma-post.repository';
import { SocialUseCases } from '../../social/domain/social.use-cases';
import { CreateTournamentUseCase, AddParticipantUseCase, RecordFlightUseCase } from '../../tournaments/domain/write.use-cases';
import { RecordUseCases } from '../../records/record.use-cases';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { IContentProvider } from '../domain/content-provider.port';
import { CONTENT_PROVIDER } from '../domain/tokens';

const pad = (n: number) => String(n).padStart(2, '0');
const rand = <T>(a: T[]): T => a[Math.floor(Math.random() * a.length)];

/**
 * The bot engine's actions, each a thin wrapper over the EXISTING use-cases —
 * no divergent path, so every counter / dedup / notification / socket emit is
 * the real one. Tournaments and live records carry real flight/landing data so
 * standings and averages populate (they never look empty / fake).
 */
@Injectable()
export class BotActivityService {
  constructor(
    private readonly posts: PostUseCases,
    private readonly postRepo: PrismaPostRepository,
    private readonly social: SocialUseCases,
    private readonly createTournament: CreateTournamentUseCase,
    private readonly addParticipant: AddParticipantUseCase,
    private readonly recordFlight: RecordFlightUseCase,
    private readonly records: RecordUseCases,
    private readonly prisma: PrismaService,
    @Inject(CONTENT_PROVIDER) private readonly content: IContentProvider,
  ) {}

  async doPost(botId: string): Promise<boolean> {
    const { caption, imageUrl } = this.content.pickPost();
    const r = await this.posts.create(botId, caption, imageUrl);
    return r.ok;
  }

  async doLike(postId: string, botId: string): Promise<boolean> {
    try {
      await this.posts.like(postId, botId);
      return true;
    } catch {
      return false;
    }
  }

  async doView(botId: string, postIds: string[]): Promise<void> {
    for (const id of postIds) await this.postRepo.view(id, botId).catch(() => null);
  }

  async doFollow(botId: string, followeeId: string): Promise<boolean> {
    const r = await this.social.follow(botId, followeeId);
    return r.ok;
  }

  /** Create a tournament started 2 days ago, add participants, and record real
   *  flights for the past days so standings + averages populate (not empty). */
  async doTournament(botId: string): Promise<string | null> {
    const t = this.content.pickTournament();
    const start = new Date();
    start.setUTCDate(start.getUTCDate() - 2); // already underway → has results
    const r = await this.createTournament.execute({
      organizerId: botId,
      title: t.title,
      description: `${t.pigeonCount}-pigeon race from ${t.city}. Clean sport, verified lofts.`,
      coverUrl: t.coverUrl,
      numDays: t.numDays,
      scheduleType: t.scheduleType,
      pigeonCount: t.pigeonCount,
      flyTime: t.flyTime,
      endTime: t.endTime,
      startDate: start.toISOString().slice(0, 10),
      organizerContact: t.organizerContact,
    } as any);
    if (!r.ok) return null;
    const id = (r.value as any).id as string;

    const participantIds: string[] = [];
    for (const name of t.participantNames) {
      const p = await this.addParticipant.execute(botId, { tournamentId: id, name } as any).catch(() => null);
      if (p && p.ok) participantIds.push((p.value as any).id);
    }

    // Record flights for the days already past (bounded). Best-effort: the
    // tournament + participants already exist, so a flaky flight step must not
    // fail the whole creation.
    try {
      const days = await this.prisma.tournamentDay.findMany({
        where: { tournamentId: id },
        orderBy: { dayNumber: 'asc' },
        select: { id: true, releaseAt: true },
      });
      const now = Date.now();
      const pastDays = days.filter((d) => d.releaseAt.getTime() < now).slice(0, 2);
      for (const d of pastDays) {
        for (const pid of participantIds) {
          const returnCount = Math.min(t.pigeonCount, 1 + Math.floor(Math.random() * Math.min(t.pigeonCount, 4)));
          for (const nm of this.content.pigeonNames(returnCount)) {
            const landing = new Date(d.releaseAt.getTime() + (30 + Math.random() * 150) * 60000);
            if (landing.getTime() > now) continue;
            await this.recordFlight
              .execute(botId, { tournamentId: id, participantId: pid, dayId: d.id, pigeonName: nm, landingTime: landing })
              .catch(() => null);
          }
        }
      }
    } catch {
      /* flights best-effort — tournament still created */
    }
    return id;
  }

  /** Create a live personal record with returned pigeons and go live, so it shows
   *  in followers' "Live now" and people can view/like it. */
  async doRecord(botId: string): Promise<string | null> {
    const now = new Date();
    const release = new Date(now.getTime() - 3 * 3600 * 1000); // flew ~3h ago
    const flyTime = `${pad(release.getUTCHours())}:${pad(release.getUTCMinutes())}`;
    const totalPigeons = rand([3, 5, 7, 9]);
    const rec: any = await this.records.create(botId, {
      recordDate: release.toISOString().slice(0, 10),
      flyTime,
      totalPigeons,
      privacy: 'live',
    });
    if (!rec?.id) return null;

    const returning = Math.max(1, Math.round(totalPigeons * (0.6 + Math.random() * 0.4)));
    for (const nm of this.content.pigeonNames(returning)) {
      const landing = new Date(release.getTime() + (20 + Math.random() * 150) * 60000);
      if (landing.getTime() > now.getTime()) continue;
      await this.records.addPigeon(botId, rec.id, nm, landing).catch(() => null);
    }
    const live = await this.records.goLive(botId, rec.id);
    return live.ok ? rec.id : null;
  }
}
