import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { BotRow, IBotRosterRepository } from '../domain/bot.repositories';

@Injectable()
export class PrismaBotRosterRepository implements IBotRosterRepository {
  constructor(private readonly prisma: PrismaService) {}

  async allActiveBots(): Promise<BotRow[]> {
    const rows = await this.prisma.user.findMany({
      where: { isBot: true, deletedAt: null, isSuspended: false },
      select: { id: true, activeStartHour: true, activeEndHour: true },
    });
    return rows;
  }

  /** A random non-self, non-suspended user for a bot to follow (bot or real). */
  async randomFolloweeId(exceptId: string): Promise<string | null> {
    const total = await this.prisma.user.count({
      where: { deletedAt: null, isSuspended: false, id: { not: exceptId } },
    });
    if (total === 0) return null;
    const skip = Math.floor(Math.random() * total);
    const row = await this.prisma.user.findFirst({
      where: { deletedAt: null, isSuspended: false, id: { not: exceptId } },
      skip,
      select: { id: true },
    });
    return row?.id ?? null;
  }
}
