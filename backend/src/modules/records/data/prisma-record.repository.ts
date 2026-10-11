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
    return this.prisma.personalRecord.findMany({
      where: {
        privacy: 'live',
        status: 'open',
        deletedAt: null,
        userId: { in: follows.map((f) => f.followeeId) },
      },
      orderBy: { wentLiveAt: 'desc' },
      take: limit,
      include: { user: { select: { id: true, displayName: true, username: true, photoUrl: true } } },
    });
  }

  async detail(id: string) {
    const r = await this.prisma.personalRecord.findFirst({
      where: { id, deletedAt: null },
      include: {
        user: { select: { id: true, displayName: true, username: true, photoUrl: true } },
        pigeons: { orderBy: { durationSeconds: 'desc' } },
      },
    });
    if (!r) throw new NotFoundError('record');
    return r;
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
          _avg: { durationSeconds: true },
          _count: { _all: true },
        });
        await tx.personalRecord.update({
          where: { id: recordId },
          data: {
            totalAvgSeconds: agg._avg.durationSeconds ? Math.round(agg._avg.durationSeconds) : null,
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
