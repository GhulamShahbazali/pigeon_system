import { Inject, Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { isAwakeInWindow } from '../domain/awake';
import {
  ActiveSource,
  BotConfig,
  IBotConfigRepository,
  IBotState,
} from '../domain/bot.repositories';
import { IContentProvider } from '../domain/content-provider.port';
import { BOT_CONFIG_REPOSITORY, BOT_STATE, CONTENT_PROVIDER } from '../domain/tokens';

/** Start of the current UTC day (for "today" analytics). */
function startOfUtcDay(): Date {
  const d = new Date();
  d.setUTCHours(0, 0, 0, 0);
  return d;
}

@Injectable()
export class BotsAdminService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(BOT_CONFIG_REPOSITORY) private readonly config: IBotConfigRepository,
    @Inject(BOT_STATE) private readonly state: IBotState,
    @Inject(CONTENT_PROVIDER) private readonly content: IContentProvider,
  ) {}

  getConfig() {
    return this.config.get();
  }
  updateConfig(patch: Partial<BotConfig>) {
    return this.config.update(patch);
  }

  async overview() {
    const hour = new Date().getUTCHours();
    const since = startOfUtcDay();
    const [config, source, bots, botIdsRows] = await Promise.all([
      this.config.get(),
      this.state.getActiveSource(),
      this.prisma.user.findMany({
        where: { isBot: true, deletedAt: null },
        select: { activeStartHour: true, activeEndHour: true },
      }),
      this.prisma.user.findMany({ where: { isBot: true }, select: { id: true } }),
    ]);
    const botIds = botIdsRows.map((b) => b.id);
    const awakeNow = bots.filter((b) => isAwakeInWindow(b.activeStartHour, b.activeEndHour, hour)).length;

    const [posts, likes, views, follows, tournaments] = await Promise.all([
      this.prisma.post.count({ where: { authorId: { in: botIds }, createdAt: { gte: since } } }),
      this.prisma.postLike.count({ where: { userId: { in: botIds }, createdAt: { gte: since } } }),
      this.prisma.postView.count({ where: { userId: { in: botIds }, createdAt: { gte: since } } }),
      this.prisma.follow.count({ where: { followerId: { in: botIds }, createdAt: { gte: since } } }),
      this.prisma.tournament.count({ where: { organizerId: { in: botIds }, createdAt: { gte: since } } }),
    ]);

    return {
      enabled: config.enabled,
      active_source: source,
      total_bots: botIds.length,
      awake_now: awakeNow,
      today: { posts, likes, views, follows, tournaments },
    };
  }

  async roster(offset: number, limit: number) {
    const hour = new Date().getUTCHours();
    const [rows, total] = await Promise.all([
      this.prisma.user.findMany({
        where: { isBot: true, deletedAt: null },
        orderBy: { createdAt: 'asc' },
        skip: offset,
        take: limit,
        select: {
          id: true, displayName: true, username: true, photoUrl: true,
          countryCode: true, city: true, activeStartHour: true, activeEndHour: true,
          followerCount: true,
        },
      }),
      this.prisma.user.count({ where: { isBot: true, deletedAt: null } }),
    ]);
    const data = rows.map((b) => ({
      id: b.id,
      display_name: b.displayName,
      username: b.username,
      photo_url: b.photoUrl,
      country_code: b.countryCode,
      city: b.city,
      active_start_hour: b.activeStartHour,
      active_end_hour: b.activeEndHour,
      follower_count: b.followerCount,
      awake_now: isAwakeInWindow(b.activeStartHour, b.activeEndHour, hour),
    }));
    return { data, total };
  }

  getActiveSource() {
    return this.state.getActiveSource();
  }
  setActiveSource(source: ActiveSource) {
    return this.state.setActiveSource(source);
  }
  getManualSelection() {
    return this.state.getManualSelection();
  }
  setManualSelection(ids: string[]) {
    return this.state.setManualSelection(ids);
  }

  contentPools() {
    return this.content.pools();
  }
}
