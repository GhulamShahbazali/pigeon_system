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

/** Pick one label from [label, weight] pairs, proportional to weight. */
function pickWeighted<T extends string>(pairs: readonly (readonly [T, number])[]): T {
  const total = pairs.reduce((s, [, w]) => s + w, 0);
  let roll = Math.random() * total;
  for (const [label, w] of pairs) {
    roll -= w;
    if (roll < 0) return label;
  }
  return pairs[pairs.length - 1][0];
}

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
    const r = await this.posts.create(botId, caption, imageUrl ?? undefined);
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

  /**
   * Create a tournament in one of several LIFECYCLE STATES so the list looks real
   * instead of every tournament being "already finished":
   *   • upcoming    — starts in 1–3 days; participants registering; no flights yet
   *   • registering — starts today; participants still joining; little/no data
   *   • running     — underway; partial flights, varied landing times, live standings
   *   • finished    — fully past; complete flights; marked completed (winner ready)
   */
  async doTournament(botId: string): Promise<string | null> {
    const t = this.content.pickTournament();
    const scenario = pickWeighted([
      ['upcoming', 30],
      ['registering', 20],
      ['running', 30],
      ['finished', 20],
    ] as const);

    const step = t.scheduleType === 'alternate_days' ? 2 : 1;
    const spanDays = (t.numDays - 1) * step; // calendar length of the schedule
    let startOffset: number; // days from today; negative = in the past
    switch (scenario) {
      case 'upcoming':    startOffset = 1 + Math.floor(Math.random() * 3); break;           // +1..+3
      case 'registering': startOffset = 0; break;                                            // today
      case 'running':     startOffset = -Math.max(1, Math.min(spanDays, 1 + Math.floor(Math.random() * Math.max(1, spanDays)))); break;
      case 'finished':    startOffset = -(spanDays + 1 + Math.floor(Math.random() * 2)); break; // all days done
    }
    const start = new Date();
    start.setUTCDate(start.getUTCDate() + startOffset);

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

    // Participants — a registering race is only partly filled; others are full.
    const names = scenario === 'registering'
      ? t.participantNames.slice(0, Math.max(2, Math.ceil(t.participantNames.length * 0.5)))
      : t.participantNames;
    const participantIds: string[] = [];
    for (const name of names) {
      const p = await this.addParticipant.execute(botId, { tournamentId: id, name } as any).catch(() => null);
      if (p && p.ok) participantIds.push((p.value as any).id);
    }

    // No flights for upcoming/registering — the race hasn't flown yet.
    if (scenario === 'upcoming' || scenario === 'registering') return id;

    // Fill flights for the days already released. "running" leaves the newest day
    // partial (some lofts still out); "finished" completes every day.
    try {
      const days = await this.prisma.tournamentDay.findMany({
        where: { tournamentId: id },
        orderBy: { dayNumber: 'asc' },
        select: { id: true, releaseAt: true },
      });
      const now = Date.now();
      const pastDays = days.filter((d) => d.releaseAt.getTime() < now);
      for (let di = 0; di < pastDays.length; di++) {
        const d = pastDays[di];
        const isNewestPast = di === pastDays.length - 1;
        // running + newest day → only some participants have landed birds yet.
        const activePids = scenario === 'running' && isNewestPast
          ? participantIds.filter(() => Math.random() < 0.6)
          : participantIds;
        for (const pid of participantIds) {
          if (!activePids.includes(pid)) continue;
          // finished races home more birds; running days are lighter.
          const base = scenario === 'finished' ? 0.6 : 0.4;
          const returnCount = Math.max(1, Math.round(t.pigeonCount * (base + Math.random() * 0.35)));
          for (const nm of this.content.pigeonNames(Math.min(returnCount, t.pigeonCount))) {
            const landing = new Date(d.releaseAt.getTime() + (25 + Math.random() * 170) * 60000);
            if (landing.getTime() > now) continue; // can't land in the future
            await this.recordFlight
              .execute(botId, { tournamentId: id, participantId: pid, dayId: d.id, pigeonName: nm, landingTime: landing })
              .catch(() => null);
          }
        }
      }
    } catch {
      /* flights best-effort — tournament still created */
    }

    // A finished race is closed so the winner/result view can show.
    if (scenario === 'finished') {
      await this.prisma.tournament.update({ where: { id }, data: { status: 'completed' } }).catch(() => null);
    }
    return id;
  }

  /** Create a live personal record with returned pigeons and go live, so it shows
   *  in followers' "Live now" and people can view/like it. */
  async doRecord(botId: string): Promise<string | null> {
    const user = await this.prisma.user.findUnique({ where: { id: botId }, select: { timezone: true } });
    const tz = user?.timezone ?? 'Asia/Karachi';
    const now = new Date();

    // Morning fly time: 05:30 to 06:45 local time
    const flyHour = rand([5, 6]);
    const flyMin = rand([0, 15, 30, 45]);
    const flyTime = `${pad(flyHour)}:${pad(flyMin)}`;
    const today = new Intl.DateTimeFormat('en-CA', { timeZone: tz }).format(now);

    const totalPigeons = rand([3, 5, 7, 9]);
    const rec: any = await this.records.create(botId, {
      recordDate: today,
      flyTime,
      totalPigeons,
      privacy: 'live',
    });
    if (!rec?.id) return null;

    // Fetch the persisted releaseAt to base landing times accurately on it
    const summary = await this.prisma.personalRecord.findUnique({
      where: { id: rec.id },
      select: { releaseAt: true },
    });
    const releaseAt = summary?.releaseAt ?? new Date();

    const returning = Math.max(1, Math.round(totalPigeons * (0.6 + Math.random() * 0.4)));
    for (const nm of this.content.pigeonNames(returning)) {
      // Pigeons fly 4 to 8 hours (240 - 480 mins)
      const flightMinutes = 240 + Math.floor(Math.random() * 240);
      const landing = new Date(releaseAt.getTime() + flightMinutes * 60000);
      if (landing.getTime() > now.getTime()) continue;
      await this.records.addPigeon(botId, rec.id, nm, landing).catch(() => null);
    }
    const live = await this.records.goLive(botId, rec.id);
    return live.ok ? rec.id : null;
  }
}
