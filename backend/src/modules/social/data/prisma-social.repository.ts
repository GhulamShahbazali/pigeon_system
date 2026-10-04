import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import {
  ISocialRepository,
  ProfileView,
  UpdateProfileInput,
} from '../domain/social.repository';

const pub = {
  id: true,
  displayName: true,
  username: true,
  photoUrl: true,
  bio: true,
  city: true,
  countryCode: true,
  followerCount: true,
  followingCount: true,
  createdAt: true,
} as const;

@Injectable()
export class PrismaSocialRepository implements ISocialRepository {
  constructor(private readonly prisma: PrismaService) {}

  private async toView(user: any, viewerId: string): Promise<ProfileView | null> {
    if (!user) return null;
    const [follow, block, tournamentCount] = await Promise.all([
      this.prisma.follow.findUnique({
        where: { followerId_followeeId: { followerId: viewerId, followeeId: user.id } },
        select: { id: true },
      }),
      this.blockExistsEitherWay(viewerId, user.id),
      this.prisma.tournament.count({ where: { organizerId: user.id, deletedAt: null } }),
    ]);
    return { user, isFollowing: !!follow, isBlocked: block, tournamentCount };
  }

  async findProfileById(id: string, viewerId: string): Promise<ProfileView | null> {
    const u = await this.prisma.user.findFirst({ where: { id, deletedAt: null }, select: pub });
    return this.toView(u, viewerId);
  }

  async findProfileByUsername(username: string, viewerId: string): Promise<ProfileView | null> {
    const u = await this.prisma.user.findFirst({
      where: { username: username.toLowerCase(), deletedAt: null },
      select: pub,
    });
    return this.toView(u, viewerId);
  }

  updateProfile(userId: string, input: UpdateProfileInput): Promise<any> {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        displayName: input.displayName,
        bio: input.bio,
        city: input.city,
        photoUrl: input.photoUrl,
      },
      select: pub,
    });
  }

  async blockExistsEitherWay(a: string, b: string): Promise<boolean> {
    const n = await this.prisma.block.count({
      where: {
        OR: [
          { blockerId: a, blockedId: b },
          { blockerId: b, blockedId: a },
        ],
      },
    });
    return n > 0;
  }

  async follow(followerId: string, followeeId: string): Promise<boolean> {
    return this.prisma
      .$transaction(async (tx) => {
        await tx.follow.create({ data: { followerId, followeeId } });
        await tx.user.update({
          where: { id: followerId },
          data: { followingCount: { increment: 1 } },
        });
        await tx.user.update({
          where: { id: followeeId },
          data: { followerCount: { increment: 1 } },
        });
        return true;
      })
      .catch(() => false); // unique violation = already following
  }

  async unfollow(followerId: string, followeeId: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const del = await tx.follow.deleteMany({ where: { followerId, followeeId } });
      if (!del.count) return;
      await tx.user.update({
        where: { id: followerId },
        data: { followingCount: { decrement: 1 } },
      });
      await tx.user.update({
        where: { id: followeeId },
        data: { followerCount: { decrement: 1 } },
      });
    });
  }

  async block(blockerId: string, blockedId: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      await tx.block.create({ data: { blockerId, blockedId } }).catch(() => null);
      // remove follows both ways + fix counts
      const f1 = await tx.follow.deleteMany({ where: { followerId: blockerId, followeeId: blockedId } });
      const f2 = await tx.follow.deleteMany({ where: { followerId: blockedId, followeeId: blockerId } });
      if (f1.count) {
        await tx.user.update({ where: { id: blockerId }, data: { followingCount: { decrement: 1 } } });
        await tx.user.update({ where: { id: blockedId }, data: { followerCount: { decrement: 1 } } });
      }
      if (f2.count) {
        await tx.user.update({ where: { id: blockedId }, data: { followingCount: { decrement: 1 } } });
        await tx.user.update({ where: { id: blockerId }, data: { followerCount: { decrement: 1 } } });
      }
    });
  }

  async unblock(blockerId: string, blockedId: string): Promise<void> {
    await this.prisma.block.deleteMany({ where: { blockerId, blockedId } });
  }

  private hydrateUsers(ids: string[]): Promise<any[]> {
    return this.prisma.user.findMany({ where: { id: { in: ids }, deletedAt: null }, select: pub });
  }

  async listFollowers(userId: string, limit: number): Promise<any[]> {
    const rows = await this.prisma.follow.findMany({
      where: { followeeId: userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      select: { followerId: true },
    });
    return this.hydrateUsers(rows.map((r) => r.followerId));
  }

  async listFollowing(userId: string, limit: number): Promise<any[]> {
    const rows = await this.prisma.follow.findMany({
      where: { followerId: userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      select: { followeeId: true },
    });
    return this.hydrateUsers(rows.map((r) => r.followeeId));
  }

  async listBlocks(userId: string, limit: number): Promise<any[]> {
    const rows = await this.prisma.block.findMany({
      where: { blockerId: userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      select: { blockedId: true },
    });
    return this.hydrateUsers(rows.map((r) => r.blockedId));
  }
}
