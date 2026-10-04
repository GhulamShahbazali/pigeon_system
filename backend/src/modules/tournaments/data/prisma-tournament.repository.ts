import { Injectable } from '@nestjs/common';
import { randomBytes } from 'crypto';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import {
  AddParticipantInput,
  CreateTournamentInput,
  ITournamentRepository,
  RecordFlightInput,
  TournamentSummary,
} from '../domain/tournament.repository';
import {
  FlightBeforeReleaseError,
  PigeonCapExceededError,
} from '../domain/tournament.errors';
import { NotFoundError } from '../../../shared/errors/common-errors';

/** Minutes the IANA tz is ahead of UTC at the given instant. */
function offsetMinutes(tz: string, at: Date): number {
  const dtf = new Intl.DateTimeFormat('en-US', {
    timeZone: tz,
    hour12: false,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
  const m: Record<string, string> = {};
  for (const p of dtf.formatToParts(at)) m[p.type] = p.value;
  const asUTC = Date.UTC(+m.year, +m.month - 1, +m.day, +m.hour, +m.minute, +m.second);
  return (asUTC - at.getTime()) / 60000;
}

/** UTC instant for a wall-clock date+time in a given timezone. */
function zonedToUtc(dateStr: string, timeStr: string, tz: string): Date {
  const guess = new Date(`${dateStr}T${timeStr.length === 5 ? timeStr : timeStr.slice(0, 5)}:00Z`);
  const off = offsetMinutes(tz, guess);
  return new Date(guess.getTime() - off * 60000);
}

function addDays(dateStr: string, days: number): string {
  const d = new Date(`${dateStr}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

function slugify(title: string): string {
  const base = title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 40);
  return `${base || 'tournament'}-${randomBytes(3).toString('hex')}`;
}

@Injectable()
export class PrismaTournamentRepository implements ITournamentRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(input: CreateTournamentInput): Promise<string> {
    const organizer = await this.prisma.user.findUnique({
      where: { id: input.organizerId },
      select: { timezone: true },
    });
    const tz = organizer?.timezone ?? 'Asia/Karachi';
    const step = input.scheduleType === 'alternate_days' ? 2 : 1;

    const days = Array.from({ length: input.numDays }, (_, i) => {
      const date = addDays(input.startDate, i * step);
      return {
        dayNumber: i + 1,
        date: new Date(`${date}T00:00:00Z`),
        releaseAt: zonedToUtc(date, input.flyTime, tz),
      };
    });

    const t = await this.prisma.tournament.create({
      data: {
        organizerId: input.organizerId,
        title: input.title,
        rules: input.rules,
        description: input.description,
        coverUrl: input.coverUrl,
        numDays: input.numDays,
        scheduleType: input.scheduleType,
        pigeonCount: input.pigeonCount,
        flyTime: input.flyTime,
        endTime: input.endTime,
        startDate: new Date(`${input.startDate}T00:00:00Z`),
        organizerContact: input.organizerContact,
        linkSlug: slugify(input.title),
        days: { create: days },
      },
      select: { id: true },
    });
    return t.id;
  }

  async findSummary(id: string): Promise<TournamentSummary | null> {
    return this.prisma.tournament.findFirst({
      where: { id, deletedAt: null },
      select: { id: true, organizerId: true, pigeonCount: true, status: true },
    });
  }

  async findDetail(id: string): Promise<any | null> {
    return this.prisma.tournament.findFirst({
      where: { id, deletedAt: null },
      include: {
        organizer: { select: { id: true, displayName: true, username: true, photoUrl: true } },
        days: { orderBy: { dayNumber: 'asc' } },
      },
    });
  }

  async list(
    tab: 'all' | 'following' | 'mine',
    userId: string,
    _cursor: string | null,
    limit: number,
  ): Promise<any[]> {
    const where: any = { deletedAt: null };
    if (tab === 'mine') where.organizerId = userId;
    if (tab === 'following') {
      const follows = await this.prisma.tournamentFollow.findMany({
        where: { userId },
        select: { tournamentId: true },
      });
      where.id = { in: follows.map((f) => f.tournamentId) };
    }
    return this.prisma.tournament.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: {
        organizer: { select: { id: true, displayName: true, username: true, photoUrl: true } },
      },
    });
  }

  addParticipant(input: AddParticipantInput): Promise<any> {
    return this.prisma.tournamentParticipant.create({
      data: {
        tournamentId: input.tournamentId,
        name: input.name,
        photoUrl: input.photoUrl,
        contactNo: input.contactNo,
        phone: input.phone,
        address: input.address,
      },
    });
  }

  async recordFlight(input: RecordFlightInput): Promise<any> {
    return this.prisma.$transaction(
      async (tx) => {
      const day = await tx.tournamentDay.findUnique({
        where: { id: input.dayId },
        select: { releaseAt: true, tournamentId: true },
      });
      if (!day || day.tournamentId !== input.tournamentId) throw new NotFoundError('day');

      const tournament = await tx.tournament.findUnique({
        where: { id: input.tournamentId },
        select: { pigeonCount: true },
      });
      if (!tournament) throw new NotFoundError('tournament');

      const count = await tx.pigeonFlight.count({
        where: { participantId: input.participantId, dayId: input.dayId },
      });
      if (count >= tournament.pigeonCount) throw new PigeonCapExceededError(tournament.pigeonCount);

      const durationSeconds = Math.floor(
        (input.landingTime.getTime() - day.releaseAt.getTime()) / 1000,
      );
      if (durationSeconds <= 0) throw new FlightBeforeReleaseError();

      const flight = await tx.pigeonFlight.create({
        data: {
          tournamentId: input.tournamentId,
          participantId: input.participantId,
          dayId: input.dayId,
          pigeonName: input.pigeonName,
          landingTime: input.landingTime,
          durationSeconds,
        },
      });

        await this.recompute(tx, input.tournamentId, input.participantId, input.dayId);
        return flight;
      },
      { timeout: 20000, maxWait: 15000 },
    );
  }

  /** Recompute day stats + participant overall + positions + tournament overall. */
  private async recompute(tx: any, tournamentId: string, participantId: string, dayId: string) {
    const dayAgg = await tx.pigeonFlight.aggregate({
      where: { participantId, dayId },
      _avg: { durationSeconds: true },
      _count: { _all: true },
    });
    await tx.participantDayStats.upsert({
      where: { participantId_dayId: { participantId, dayId } },
      create: {
        participantId,
        dayId,
        avgSeconds: dayAgg._avg.durationSeconds ? Math.round(dayAgg._avg.durationSeconds) : null,
        returnedCount: dayAgg._count._all,
      },
      update: {
        avgSeconds: dayAgg._avg.durationSeconds ? Math.round(dayAgg._avg.durationSeconds) : null,
        returnedCount: dayAgg._count._all,
      },
    });

    const overall = await tx.pigeonFlight.aggregate({
      where: { participantId },
      _avg: { durationSeconds: true },
      _count: { _all: true },
    });
    await tx.tournamentParticipant.update({
      where: { id: participantId },
      data: {
        overallAvgSeconds: overall._avg.durationSeconds
          ? Math.round(overall._avg.durationSeconds)
          : null,
        overallReturnedCount: overall._count._all,
      },
    });

    // Re-rank: higher avg = better (descending). Nulls last.
    const parts = await tx.tournamentParticipant.findMany({
      where: { tournamentId, deletedAt: null },
      select: { id: true, overallAvgSeconds: true },
    });
    parts.sort(
      (a: any, b: any) => (b.overallAvgSeconds ?? -1) - (a.overallAvgSeconds ?? -1),
    );
    let pos = 1;
    for (const p of parts) {
      await tx.tournamentParticipant.update({ where: { id: p.id }, data: { position: pos++ } });
    }

    const tAgg = await tx.pigeonFlight.aggregate({
      where: { tournamentId },
      _avg: { durationSeconds: true },
    });
    await tx.tournament.update({
      where: { id: tournamentId },
      data: {
        overallAvgSeconds: tAgg._avg.durationSeconds ? Math.round(tAgg._avg.durationSeconds) : null,
      },
    });
  }

  standings(tournamentId: string): Promise<any[]> {
    return this.prisma.tournamentParticipant.findMany({
      where: { tournamentId, deletedAt: null },
      orderBy: [{ overallAvgSeconds: 'desc' }, { name: 'asc' }],
    });
  }

  async participantDays(tournamentId: string, participantId: string): Promise<any> {
    const participant = await this.prisma.tournamentParticipant.findFirst({
      where: { id: participantId, tournamentId, deletedAt: null },
    });
    if (!participant) throw new NotFoundError('participant');
    const days = await this.prisma.tournamentDay.findMany({
      where: { tournamentId },
      orderBy: { dayNumber: 'asc' },
      include: {
        stats: { where: { participantId } },
        flights: { where: { participantId }, orderBy: { durationSeconds: 'desc' } },
      },
    });
    return { participant, days };
  }

  async toggleFollow(tournamentId: string, userId: string, follow: boolean): Promise<void> {
    if (follow) {
      await this.prisma.$transaction(async (tx) => {
        const created = await tx.tournamentFollow
          .create({ data: { tournamentId, userId } })
          .catch(() => null);
        if (created)
          await tx.tournament.update({
            where: { id: tournamentId },
            data: { followerCount: { increment: 1 } },
          });
      });
    } else {
      await this.prisma.$transaction(async (tx) => {
        const del = await tx.tournamentFollow.deleteMany({ where: { tournamentId, userId } });
        if (del.count)
          await tx.tournament.update({
            where: { id: tournamentId },
            data: { followerCount: { decrement: 1 } },
          });
      });
    }
  }

  async toggleLike(tournamentId: string, userId: string, like: boolean): Promise<void> {
    if (like) {
      await this.prisma.$transaction(async (tx) => {
        const created = await tx.tournamentLike
          .create({ data: { tournamentId, userId } })
          .catch(() => null);
        if (created)
          await tx.tournament.update({
            where: { id: tournamentId },
            data: { likeCount: { increment: 1 } },
          });
      });
    } else {
      await this.prisma.$transaction(async (tx) => {
        const del = await tx.tournamentLike.deleteMany({ where: { tournamentId, userId } });
        if (del.count)
          await tx.tournament.update({
            where: { id: tournamentId },
            data: { likeCount: { decrement: 1 } },
          });
      });
    }
  }

  async recordView(tournamentId: string, userId: string): Promise<void> {
    const created = await this.prisma.tournamentView
      .create({ data: { tournamentId, userId } })
      .catch(() => null);
    if (created)
      await this.prisma.tournament.update({
        where: { id: tournamentId },
        data: { viewCount: { increment: 1 } },
      });
  }
}
