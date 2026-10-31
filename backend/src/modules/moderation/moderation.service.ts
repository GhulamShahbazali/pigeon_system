import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { EmitService } from '../../shared/socket/emit.service';
import { RedisService } from '../../shared/redis/redis.service';
import { NotFoundError } from '../../shared/errors/common-errors';

@Injectable()
export class ModerationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly emit: EmitService,
    private readonly redis: RedisService,
  ) {}

  createReport(reporterId: string, targetType: string, targetId: string, reason: string, note?: string) {
    return this.prisma.report.create({
      data: { reporterId, targetType: targetType as any, targetId, reason: reason as any, note },
    });
  }

  async listReports(status: string | undefined, offset: number, limit: number) {
    const where = status ? { status: status as any } : {};
    const [data, total] = await Promise.all([
      this.prisma.report.findMany({ where, orderBy: { createdAt: 'desc' }, skip: offset, take: limit }),
      this.prisma.report.count({ where }),
    ]);
    return { data, total };
  }

  private log(adminId: string, action: any, targetType: string, targetId: string, note?: string) {
    return this.prisma.adminActionLog.create({ data: { adminId, action, targetType, targetId, note } });
  }

  async actionReport(adminId: string, reportId: string, action: 'dismiss' | 'hide' | 'remove' | 'block', note?: string) {
    const report = await this.prisma.report.update({
      where: { id: reportId },
      data: { status: action === 'dismiss' ? 'dismissed' : 'actioned' },
    });
    if (action === 'hide' || action === 'remove') {
      const hidden = action === 'hide' ? { hiddenUntil: new Date(Date.now() + 24 * 3600 * 1000) } : { deletedAt: new Date() };
      if (report.targetType === 'post') await this.prisma.post.updateMany({ where: { id: report.targetId }, data: hidden as any });
      if (report.targetType === 'tournament' && action === 'remove')
        await this.prisma.tournament.updateMany({ where: { id: report.targetId }, data: { deletedAt: new Date() } });
    }
    if (action === 'block' && report.targetType === 'user') await this.suspend(adminId, report.targetId, note);
    await this.log(adminId, action === 'dismiss' ? 'unblock' : (action as any), report.targetType, report.targetId, note);
  }

  async listUsers(q: string | undefined, offset: number, limit: number) {
    const where = q
      ? { OR: [{ username: { contains: q.toLowerCase() } }, { displayName: { contains: q, mode: 'insensitive' as const } }] }
      : {};
    const [data, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: offset,
        take: limit,
        select: { id: true, displayName: true, username: true, email: true, isSuspended: true, createdAt: true },
      }),
      this.prisma.user.count({ where }),
    ]);
    return { data, total };
  }

  async suspend(adminId: string, userId: string, reason?: string, until?: Date) {
    await this.prisma.$transaction([
      this.prisma.userSuspension.create({ data: { userId, moderatorId: adminId, reason, suspendedUntil: until } }),
      this.prisma.user.update({ where: { id: userId }, data: { isSuspended: true } }),
    ]);
    // invalidate session caches so the suspension takes effect
    const jtis = await this.redis.client.smembers(`user_sessions:${userId}`).catch(() => [] as string[]);
    if (jtis.length) await this.redis.client.del(...jtis.map((j) => `session:${j}`)).catch(() => null);
    this.emit.toUser(userId, 'user.suspended', { suspended_until: until ?? null });
    await this.log(adminId, 'suspend', 'user', userId, reason);
  }

  async unsuspend(adminId: string, userId: string) {
    await this.prisma.$transaction([
      this.prisma.userSuspension.updateMany({ where: { userId, liftedAt: null }, data: { liftedAt: new Date() } }),
      this.prisma.user.update({ where: { id: userId }, data: { isSuspended: false } }),
    ]);
    this.emit.toUser(userId, 'user.suspension_lifted', {});
    await this.log(adminId, 'unsuspend', 'user', userId);
  }

  /** SuperAdmin override: edit a tournament's cosmetic/contact fields only (T15).
   *  Schedule-defining fields stay locked — they regenerate days / would invalidate
   *  recorded flights. Only the fields present in `patch` change. */
  async editTournament(
    adminId: string,
    id: string,
    patch: {
      title?: string;
      description?: string | null;
      rules?: string | null;
      coverUrl?: string | null;
      organizerContact?: string | null;
    },
  ) {
    const exists = await this.prisma.tournament.findFirst({
      where: { id, deletedAt: null },
      select: { id: true },
    });
    if (!exists) throw new NotFoundError('tournament');

    const data: Record<string, unknown> = {};
    if (patch.title !== undefined) data.title = patch.title;
    if (patch.description !== undefined) data.description = patch.description;
    if (patch.rules !== undefined) data.rules = patch.rules;
    if (patch.coverUrl !== undefined) data.coverUrl = patch.coverUrl;
    if (patch.organizerContact !== undefined) data.organizerContact = patch.organizerContact;

    const r = await this.prisma.tournament.update({
      where: { id },
      data,
      select: { id: true, title: true, description: true, rules: true, coverUrl: true, organizerContact: true },
    });
    await this.log(adminId, 'edit', 'tournament', id);
    return r;
  }

  /** SuperAdmin override: soft-delete any tournament (T5). Never hard-deletes —
   *  sets deleted_at, so it drops out of every list but referenced rows survive. */
  async deleteTournament(adminId: string, id: string, note?: string) {
    const t = await this.prisma.tournament.findFirst({
      where: { id, deletedAt: null },
      select: { id: true, organizerId: true },
    });
    if (!t) throw new NotFoundError('tournament');
    await this.prisma.tournament.update({ where: { id }, data: { deletedAt: new Date() } });
    await this.log(adminId, 'remove', 'tournament', id, note);
  }
}
