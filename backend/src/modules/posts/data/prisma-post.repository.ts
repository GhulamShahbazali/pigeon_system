import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { NotFoundError } from '../../../shared/errors/common-errors';

@Injectable()
export class PrismaPostRepository {
  constructor(private readonly prisma: PrismaService) {}

  private async blockedIds(userId: string): Promise<string[]> {
    const blocks = await this.prisma.block.findMany({
      where: { OR: [{ blockerId: userId }, { blockedId: userId }] },
      select: { blockerId: true, blockedId: true },
    });
    const set = new Set<string>();
    for (const b of blocks) set.add(b.blockerId === userId ? b.blockedId : b.blockerId);
    return [...set];
  }

  async feed(tab: 'for_you' | 'following', viewerId: string, limit: number) {
    const [blocked, hidden] = await Promise.all([
      this.blockedIds(viewerId),
      this.prisma.postHide.findMany({ where: { userId: viewerId }, select: { postId: true } }),
    ]);
    const where: any = {
      deletedAt: null,
      authorId: { notIn: blocked.length ? blocked : ['00000000-0000-0000-0000-000000000000'] },
      id: { notIn: hidden.map((h) => h.postId).concat('00000000-0000-0000-0000-000000000000') },
      OR: [{ hiddenUntil: null }, { hiddenUntil: { lt: new Date() } }],
    };
    if (tab === 'following') {
      const f = await this.prisma.follow.findMany({ where: { followerId: viewerId }, select: { followeeId: true } });
      where.authorId = { in: f.map((x) => x.followeeId), notIn: blocked };
    }
    return this.prisma.post.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: { author: { select: { id: true, displayName: true, username: true, photoUrl: true } } },
    });
  }

  async getById(id: string) {
    const p = await this.prisma.post.findFirst({
      where: { id, deletedAt: null },
      include: { author: { select: { id: true, displayName: true, username: true, photoUrl: true } } },
    });
    if (!p) throw new NotFoundError('post');
    return p;
  }

  create(authorId: string, content: string | undefined, imageUrl: string | undefined) {
    return this.prisma.post.create({
      data: { authorId, content, imageUrl },
      include: { author: { select: { id: true, displayName: true, username: true, photoUrl: true } } },
    });
  }

  async authorOf(id: string): Promise<string | null> {
    const p = await this.prisma.post.findFirst({ where: { id, deletedAt: null }, select: { authorId: true } });
    return p?.authorId ?? null;
  }

  update(id: string, content?: string, imageUrl?: string) {
    return this.prisma.post.update({ where: { id }, data: { content, imageUrl } });
  }
  async softDelete(id: string) {
    await this.prisma.post.update({ where: { id }, data: { deletedAt: new Date() } });
  }

  /** Returns author id if a new like was created (for notification), else null. */
  async like(postId: string, userId: string): Promise<string | null> {
    return this.prisma.$transaction(async (tx) => {
      const created = await tx.postLike.create({ data: { postId, userId } }).catch(() => null);
      if (!created) return null;
      const p = await tx.post.update({
        where: { id: postId },
        data: { likeCount: { increment: 1 } },
        select: { authorId: true },
      });
      return p.authorId;
    });
  }
  async unlike(postId: string, userId: string) {
    await this.prisma.$transaction(async (tx) => {
      const d = await tx.postLike.deleteMany({ where: { postId, userId } });
      if (d.count) await tx.post.update({ where: { id: postId }, data: { likeCount: { decrement: 1 } } });
    });
  }
  async share(postId: string, userId: string) {
    await this.prisma.$transaction(async (tx) => {
      await tx.postShare.create({ data: { postId, userId } });
      await tx.post.update({ where: { id: postId }, data: { shareCount: { increment: 1 } } });
    });
  }
  async view(postId: string, userId: string) {
    const c = await this.prisma.postView.create({ data: { postId, userId } }).catch(() => null);
    if (c) await this.prisma.post.update({ where: { id: postId }, data: { viewCount: { increment: 1 } } });
  }
  async hide(postId: string, userId: string) {
    await this.prisma.postHide.create({ data: { postId, userId } }).catch(() => null);
  }
  async unhide(postId: string, userId: string) {
    await this.prisma.postHide.deleteMany({ where: { postId, userId } });
  }
  async report(reporterId: string, postId: string, reason: string, note?: string) {
    await this.prisma.report.create({
      data: { reporterId, targetType: 'post', targetId: postId, reason: reason as any, note },
    });
  }
  counts(postId: string) {
    return this.prisma.post.findUnique({
      where: { id: postId },
      select: { likeCount: true, shareCount: true, viewCount: true },
    });
  }
}
