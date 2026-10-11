import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { BotConfig, IBotConfigRepository } from '../domain/bot.repositories';

const toDomain = (r: any): BotConfig => ({
  enabled: r.enabled,
  tickIntervalSec: r.tickIntervalSec,
  gapWindowSec: r.gapWindowSec,
  postsPerMin: r.postsPerMin,
  botPostCooldownMin: r.botPostCooldownMin,
  likesPerMin: r.likesPerMin,
  newestBiasPct: r.newestBiasPct,
  maxBotLikesPerPost: r.maxBotLikesPerPost,
  viewsPerMin: r.viewsPerMin,
  viewBatchSize: r.viewBatchSize,
  followsPerMin: r.followsPerMin,
  tournamentsPerDay: r.tournamentsPerDay,
  recordsPerDay: r.recordsPerDay,
});

@Injectable()
export class PrismaBotConfigRepository implements IBotConfigRepository {
  constructor(private readonly prisma: PrismaService) {}

  /** Read the singleton (id = 1), creating defaults on first access. */
  async get(): Promise<BotConfig> {
    const row = await this.prisma.botConfig.upsert({
      where: { id: 1 },
      create: { id: 1 },
      update: {},
    });
    return toDomain(row);
  }

  async update(patch: Partial<BotConfig>): Promise<BotConfig> {
    const row = await this.prisma.botConfig.upsert({
      where: { id: 1 },
      create: { id: 1, ...patch },
      update: patch,
    });
    return toDomain(row);
  }
}
