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

/** Soft cap for how many participants a not-yet-started bot tournament grows to
 *  as the gradual "registration filling up" ticks add more over time. */
const PARTICIPANT_SOFT_CAP = 12;

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

    // Participants — seeded to match the lifecycle, then grown gradually by
    // doTournamentTick so a race visibly "fills up" over time instead of
    // appearing fully populated the instant it's created:
    //   • upcoming    — only 2–3 early sign-ups; the tick adds the rest
    //   • registering — about half; the tick tops it up
    //   • running/finished — full roster (realistic for an underway/closed race)
    const names =
      scenario === 'upcoming'
        ? t.participantNames.slice(0, Math.min(t.participantNames.length, 2 + Math.floor(Math.random() * 2)))
        : scenario === 'registering'
          ? t.participantNames.slice(0, Math.max(2, Math.ceil(t.participantNames.length * 0.5)))
          : t.participantNames;
    const participantIds: string[] = [];
    for (const name of names) {
      const p = await this.addParticipant
        .execute(botId, { tournamentId: id, name } as any, { allowAfterStart: true })
        .catch(() => null);
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

  /** Create a live personal record and go live with (at most) a single early
   *  bird home. The remaining pigeons land one at a time over real time via
   *  doLiveRecordTick, so a watcher sees the count tick up gradually instead of
   *  every pigeon appearing the instant the record goes live. */
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

    const live = await this.records.goLive(botId, rec.id);
    if (!live.ok) return null;

    // Fetch the persisted releaseAt and, if the birds have already had enough
    // time to start coming home (release was > 45 min ago), seed ONE early bird
    // so the record doesn't look stuck at zero. Everything else trickles in.
    const summary = await this.prisma.personalRecord.findUnique({
      where: { id: rec.id },
      select: { releaseAt: true },
    });
    const releaseAt = summary?.releaseAt ?? now;
    if (now.getTime() - releaseAt.getTime() > 45 * 60000) {
      const nm = this.content.pigeonNames(1)[0] ?? 'Pigeon 1';
      const landing = new Date(releaseAt.getTime() + (30 + Math.floor(Math.random() * 120)) * 60000);
      if (landing.getTime() <= now.getTime()) {
        await this.records.addPigeon(botId, rec.id, nm, landing).catch(() => null);
      }
    }
    return rec.id;
  }

  /**
   * One gradual landing: pick a still-open live bot record that hasn't had all
   * its pigeons return and add exactly ONE more landing (landing = now, so the
   * duration reflects the real elapsed flight time). Returns true if a landing
   * was recorded. Best-effort — never throws.
   */
  async doLiveRecordTick(botIds: string[]): Promise<boolean> {
    if (botIds.length === 0) return false;
    const now = new Date();
    try {
      const candidates = await this.prisma.personalRecord.findMany({
        where: {
          userId: { in: botIds },
          privacy: 'live',
          status: 'open',
          deletedAt: null,
          releaseAt: { lt: now },
        },
        select: {
          id: true,
          userId: true,
          totalPigeons: true,
          _count: { select: { pigeons: true } },
          pigeons: { select: { pigeonName: true } },
        },
        take: 80,
      });
      const incomplete = candidates.filter((r) => r._count.pigeons < r.totalPigeons);
      if (incomplete.length === 0) return false;

      const rec = rand(incomplete);
      const used = new Set(rec.pigeons.map((p) => p.pigeonName));
      const name =
        this.content.pigeonNames(rec.totalPigeons + 6).find((n) => !used.has(n)) ??
        `Pigeon ${rec._count.pigeons + 1}`;
      const r = await this.records.addPigeon(rec.userId, rec.id, name, now).catch(() => null);
      return !!(r && r.ok);
    } catch {
      return false;
    }
  }

  /**
   * One gradual tournament update on a random active bot tournament:
   *   • not started yet → one more participant registers (up to a soft cap)
   *   • already running → one more pigeon lands on a released day (a day with
   *     room left for the chosen participant)
   * Returns true if something was added. Best-effort — never throws.
   */
  async doTournamentTick(botIds: string[]): Promise<boolean> {
    if (botIds.length === 0) return false;
    const now = new Date();
    const startOfUtcDay = (d: Date) => Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
    try {
      const tours = await this.prisma.tournament.findMany({
        where: { organizerId: { in: botIds }, status: 'active', deletedAt: null },
        select: {
          id: true,
          organizerId: true,
          startDate: true,
          pigeonCount: true,
          _count: { select: { participants: true } },
        },
        take: 100,
      });
      if (tours.length === 0) return false;

      const t = rand(tours);
      const started = startOfUtcDay(now) >= startOfUtcDay(new Date(t.startDate));

      // ── not started: a new participant registers (registration filling up) ──
      if (!started) {
        if (t._count.participants >= PARTICIPANT_SOFT_CAP) return false;
        const existing = await this.prisma.tournamentParticipant.findMany({
          where: { tournamentId: t.id },
          select: { name: true },
        });
        const used = new Set(existing.map((p) => p.name));
        const name = this.freshParticipantName(used);
        const p = await this.addParticipant
          .execute(t.organizerId, { tournamentId: t.id, name } as any, { allowAfterStart: true })
          .catch(() => null);
        return !!(p && p.ok);
      }

      // ── running: one more pigeon lands on a released day with room left ──
      const days = await this.prisma.tournamentDay.findMany({
        where: { tournamentId: t.id, releaseAt: { lt: now } },
        orderBy: { dayNumber: 'desc' },
        select: { id: true, releaseAt: true },
      });
      if (days.length === 0) return false;
      const participants = await this.prisma.tournamentParticipant.findMany({
        where: { tournamentId: t.id, deletedAt: null },
        select: { id: true },
      });
      if (participants.length === 0) return false;

      // Count existing flights per (participant, day) so we only target a slot
      // that still has room under the pigeon cap.
      const flights = await this.prisma.pigeonFlight.groupBy({
        by: ['participantId', 'dayId'],
        where: { tournamentId: t.id },
        _count: { _all: true },
      });
      const countOf = new Map<string, number>();
      for (const f of flights) countOf.set(`${f.participantId}|${f.dayId}`, f._count._all);

      // Prefer newest released days; try a handful of random participants per day.
      for (const d of days) {
        const pool = [...participants].sort(() => Math.random() - 0.5);
        for (const p of pool.slice(0, 8)) {
          const landed = countOf.get(`${p.id}|${d.id}`) ?? 0;
          if (landed >= t.pigeonCount) continue;
          // Land within a believable window after release, never in the future.
          const earliest = d.releaseAt.getTime() + 5 * 60000;
          const latest = Math.min(now.getTime(), d.releaseAt.getTime() + 195 * 60000);
          if (latest <= earliest) continue; // not enough time has passed yet
          const landing = new Date(earliest + Math.random() * (latest - earliest));
          const name = this.content.pigeonNames(1)[0] ?? `Pigeon ${landed + 1}`;
          const r = await this.recordFlight
            .execute(t.organizerId, {
              tournamentId: t.id,
              participantId: p.id,
              dayId: d.id,
              pigeonName: name,
              landingTime: landing,
              bypassDateCheck: true,
            })
            .catch(() => null);
          if (r && r.ok) return true;
        }
      }
      return false;
    } catch {
      return false;
    }
  }

  /** A participant name not already used in this tournament, drawn from the
   *  content pools (falls back to a generic loft label if the pool is exhausted). */
  private freshParticipantName(used: Set<string>): string {
    for (let i = 0; i < 8; i++) {
      for (const n of this.content.pickTournament().participantNames) {
        if (!used.has(n)) return n;
      }
    }
    return `Loft ${used.size + 1}`;
  }
}
