import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { RedisService } from '../../../shared/redis/redis.service';
import { zonedToUtc, nextLocalMidnightUtc } from '../../../shared/date/tz';
import { NotFoundError } from '../../../shared/errors/common-errors';

const LIVE_SET = 'live_records:active';

@Injectable()
export class PrismaRecordRepository {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async create(userId: string, input: { recordDate: string; flyTime: string; totalPigeons: number; privacy: 'private' | 'live' }) {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { timezone: true } });
    const tz = user?.timezone ?? 'Asia/Karachi';
    return this.prisma.personalRecord.create({
      data: {
        userId,
        recordDate: new Date(`${input.recordDate}T00:00:00Z`),
        flyTime: input.flyTime,
        releaseAt: zonedToUtc(input.recordDate, input.flyTime, tz),
        totalPigeons: input.totalPigeons,
        privacy: input.privacy,
      },
    });
  }

  findSummary(id: string) {
    return this.prisma.personalRecord.findFirst({
      where: { id, deletedAt: null },
      select: { id: true, userId: true, privacy: true, status: true, totalPigeons: true, releaseAt: true },
    });
  }

  listMine(userId: string, limit: number) {
    return this.prisma.personalRecord.findMany({
      where: { userId, deletedAt: null },
      orderBy: { recordDate: 'desc' },
      take: limit,
    });
  }

  async liveNow(viewerId: string, limit: number) {
    const follows = await this.prisma.follow.findMany({
      where: { followerId: viewerId },
      select: { followeeId: true },
    });
    const followedIds = follows.map((f) => f.followeeId);
    const base = { privacy: 'live' as const, status: 'open' as const, deletedAt: null };
    const include = { user: { select: { id: true, displayName: true, username: true, photoUrl: true } } };

    // Live records of people the viewer follows come first.
    const followed = followedIds.length
      ? await this.prisma.personalRecord.findMany({
          where: { ...base, userId: { in: followedIds } },
          orderBy: { wentLiveAt: 'desc' },
          take: limit,
          include,
        })
      : [];

    if (followed.length >= limit) return followed;

    // Fill the rest with other live records (discovery) so a new user — who may
    // follow no one yet — still sees who is live right now. Never the viewer's own.
    const exclude = [viewerId, ...followed.map((r) => r.userId)];
    const discovery = await this.prisma.personalRecord.findMany({
      where: { ...base, userId: { notIn: exclude } },
      orderBy: { wentLiveAt: 'desc' },
      take: limit - followed.length,
      include,
    });
    return [...followed, ...discovery];
  }

  async detail(id: string, viewerId?: string) {
    const r = await this.prisma.personalRecord.findFirst({
      where: { id, deletedAt: null },
      include: {
        user: { select: { id: true, displayName: true, username: true, photoUrl: true } },
        pigeons: { orderBy: { landingTime: 'desc' } },
      },
    });
    if (!r) throw new NotFoundError('record');
    const like = viewerId
      ? await this.prisma.recordLike.findUnique({
          where: { recordId_userId: { recordId: id, userId: viewerId } },
          select: { id: true },
        })
      : null;
    return { ...r, isLiked: !!like, isOwner: r.userId === viewerId };
  }

  async addPigeon(recordId: string, releaseAt: Date, pigeonName: string, landingTime: Date) {
    const durationSeconds = Math.floor((landingTime.getTime() - releaseAt.getTime()) / 1000);
    return this.prisma.$transaction(
      async (tx) => {
        const pigeon = await tx.recordPigeon.create({
          data: { recordId, pigeonName, landingTime, durationSeconds },
        });
        const agg = await tx.recordPigeon.aggregate({
          where: { recordId },
          _sum: { durationSeconds: true },
          _count: { _all: true },
        });
        await tx.personalRecord.update({
          where: { id: recordId },
          data: {
            totalAvgSeconds: agg._sum.durationSeconds ?? null,
            returnedCount: agg._count._all,
          },
        });
        return pigeon;
      },
      { timeout: 20000, maxWait: 15000 },
    );
  }

  async goLive(recordId: string, _tz: string) {
    // Live for exactly 24 hours from go-live, then auto-ends (and can't re-live).
    const wentLiveAt = new Date();
    const autoEndAt = new Date(wentLiveAt.getTime() + 24 * 60 * 60 * 1000);
    const r = await this.prisma.personalRecord.update({
      where: { id: recordId },
      data: { privacy: 'live', status: 'open', wentLiveAt, autoEndAt },
    });
    await this.redis.client.sadd(LIVE_SET, recordId).catch(() => null);
    return r;
  }

  async end(recordId: string) {
    const updated = await this.prisma.personalRecord.updateMany({
      where: { id: recordId, status: 'open' },
      data: { status: 'completed', endedAt: new Date() },
    });
    await this.redis.client.srem(LIVE_SET, recordId).catch(() => null);
    return updated.count > 0;
  }

  async toggleLike(recordId: string, userId: string, like: boolean) {
    if (like) {
      await this.prisma.$transaction(async (tx) => {
        const c = await tx.recordLike.create({ data: { recordId, userId } }).catch(() => null);
        if (c) await tx.personalRecord.update({ where: { id: recordId }, data: { likeCount: { increment: 1 } } });
      });
    } else {
      await this.prisma.$transaction(async (tx) => {
        const d = await tx.recordLike.deleteMany({ where: { recordId, userId } });
        if (d.count) await tx.personalRecord.update({ where: { id: recordId }, data: { likeCount: { decrement: 1 } } });
      });
    }
  }

  async recordView(recordId: string, userId: string) {
    const c = await this.prisma.recordView.create({ data: { recordId, userId } }).catch(() => null);
    if (c) await this.prisma.personalRecord.update({ where: { id: recordId }, data: { viewCount: { increment: 1 } } });
  }

  followerIds(userId: string): Promise<string[]> {
    return this.prisma.follow
      .findMany({ where: { followeeId: userId }, select: { followerId: true } })
      .then((rows) => rows.map((r) => r.followerId));
  }
}
