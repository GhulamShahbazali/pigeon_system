import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';

const pub = {
  id: true,
  displayName: true,
  username: true,
  photoUrl: true,
  city: true,
  countryCode: true,
  followerCount: true,
} as const;

const owner = { id: true, displayName: true, username: true, photoUrl: true } as const;

@Injectable()
export class PrismaDiscoveryRepository {
  constructor(private readonly prisma: PrismaService) {}

  /** Every user id the viewer blocked or was blocked by (excluded from all discovery). */
  async blockedIds(viewerId: string): Promise<string[]> {
    const rows = await this.prisma.block.findMany({
      where: { OR: [{ blockerId: viewerId }, { blockedId: viewerId }] },
      select: { blockerId: true, blockedId: true },
    });
    const set = new Set<string>();
    for (const r of rows) set.add(r.blockerId === viewerId ? r.blockedId : r.blockerId);
    return [...set];
  }

  /** Ids the viewer already follows, intersected with `within` (for is_following flags). */
  async followingAmong(viewerId: string, within: string[]): Promise<Set<string>> {
    if (within.length === 0) return new Set();
    const rows = await this.prisma.follow.findMany({
      where: { followerId: viewerId, followeeId: { in: within } },
      select: { followeeId: true },
    });
    return new Set(rows.map((r) => r.followeeId));
  }

  /** "Find friends": popular users the viewer does not follow yet, blocked/self excluded. */
  async suggestedUsers(viewerId: string, limit: number): Promise<any[]> {
    const [blocked, following] = await Promise.all([
      this.blockedIds(viewerId),
      this.prisma.follow.findMany({ where: { followerId: viewerId }, select: { followeeId: true } }),
    ]);
    const exclude = new Set<string>([viewerId, ...blocked, ...following.map((f) => f.followeeId)]);
    return this.prisma.user.findMany({
      where: { deletedAt: null, isSuspended: false, id: { notIn: [...exclude] } },
      orderBy: [{ followerCount: 'desc' }, { lastActiveAt: 'desc' }],
      take: limit,
      select: pub,
    });
  }

  async searchUsers(viewerId: string, q: string, limit: number): Promise<any[]> {
    const blocked = await this.blockedIds(viewerId);
    return this.prisma.user.findMany({
      where: {
        deletedAt: null,
        isSuspended: false,
        id: { notIn: [viewerId, ...blocked] },
        OR: [
          { username: { contains: q.toLowerCase() } },
          { displayName: { contains: q, mode: 'insensitive' } },
        ],
      },
      orderBy: [{ followerCount: 'desc' }],
      take: limit,
      select: pub,
    });
  }

  searchTournaments(q: string, limit: number): Promise<any[]> {
    return this.prisma.tournament.findMany({
      where: { deletedAt: null, title: { contains: q, mode: 'insensitive' } },
      orderBy: [{ status: 'asc' }, { followerCount: 'desc' }, { createdAt: 'desc' }],
      take: limit,
      include: { organizer: { select: owner } },
    });
  }

  async searchLiveRecords(viewerId: string, q: string, limit: number): Promise<any[]> {
    const blocked = await this.blockedIds(viewerId);
    return this.prisma.personalRecord.findMany({
      where: {
        deletedAt: null,
        privacy: 'live',
        status: 'open',
        userId: { notIn: blocked },
        user: {
          deletedAt: null,
          OR: [
            { username: { contains: q.toLowerCase() } },
            { displayName: { contains: q, mode: 'insensitive' } },
          ],
        },
      },
      orderBy: { wentLiveAt: 'desc' },
      take: limit,
      include: { user: { select: owner } },
    });
  }

  /** Accepted conversations whose OTHER participant matches `q`. Returns [conversation, otherUser]. */
  async searchConversations(viewerId: string, q: string, limit: number): Promise<Array<[any, any]>> {
    const convos = await this.prisma.conversation.findMany({
      where: { status: 'accepted', deletedAt: null, participants: { some: { userId: viewerId } } },
      orderBy: { lastMessageAt: 'desc' },
      take: 200,
      include: { participants: { select: { userId: true } } },
    });
    const otherOf = new Map<string, string>();
    for (const c of convos) {
      const other = c.participants.find((p) => p.userId !== viewerId)?.userId;
      if (other) otherOf.set(c.id, other);
    }
    const otherIds = [...new Set(otherOf.values())];
    if (otherIds.length === 0) return [];

    const matched = await this.prisma.user.findMany({
      where: {
        id: { in: otherIds },
        deletedAt: null,
        OR: [
          { username: { contains: q.toLowerCase() } },
          { displayName: { contains: q, mode: 'insensitive' } },
        ],
      },
      select: owner,
    });
    const byId = new Map(matched.map((u) => [u.id, u]));
    const out: Array<[any, any]> = [];
    for (const c of convos) {
      const u = byId.get(otherOf.get(c.id) ?? '');
      if (u) out.push([c, u]);
      if (out.length >= limit) break;
    }
    return out;
  }
}
