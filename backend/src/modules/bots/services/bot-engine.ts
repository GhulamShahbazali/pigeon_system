import { Inject, Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { PrismaPostRepository } from '../../posts/data/prisma-post.repository';
import { BotActivityService } from './bot-activity.service';
import { isAwakeInWindow } from '../domain/awake';
import { BotConfig, BotRow, IBotConfigRepository, IBotRosterRepository, IBotState } from '../domain/bot.repositories';
import { BOT_CONFIG_REPOSITORY, BOT_ROSTER_REPOSITORY, BOT_STATE } from '../domain/tokens';

interface RecentPost { id: string; authorId: string; createdAt: Date }

const ROSTER_REFRESH_MS = 5 * 60 * 1000;
const RECENT_REFRESH_MS = 5 * 1000;
const RECENT_LIMIT = 150;
const FRONT_SIZE = 20;
const LIKE_CAP_TTL_SEC = 24 * 60 * 60;
const MAX_COOLDOWN_SCAN = 40;
const NON_AUTHOR_TRIES = 6;
const MAX_LIKES_PER_BOT_MIN = 15;
const MAX_VIEWS_PER_BOT_MIN = 30;
const MAX_FOLLOWS_PER_BOT_MIN = 3;

/**
 * Content-seeding engine. One tick every `tick_interval_sec`, in the scheduler
 * process only (started by BotEngineBootstrap — the single-instance guarantee).
 * Reads `bot_config` live each tick, computes the awake set (Schedule windows or
 * the Manual Redis selection), then runs rate-driven streams: posts (gap-fill),
 * likes, views, follows, and an occasional tournament. Never throws out of a tick.
 */
@Injectable()
export class BotEngine implements OnModuleDestroy {
  private readonly logger = new Logger('BotEngine');
  private timer: NodeJS.Timeout | null = null;
  private currentTickSec = 0;
  private ticking = false;

  private postCredit = 0;
  private likeCredit = 0;
  private viewCredit = 0;
  private followCredit = 0;

  private rosterCache: BotRow[] = [];
  private rosterAt = 0;
  private recentCache: RecentPost[] = [];
  private recentAt = 0;

  constructor(
    private readonly activity: BotActivityService,
    private readonly postRepo: PrismaPostRepository,
    @Inject(BOT_CONFIG_REPOSITORY) private readonly config: IBotConfigRepository,
    @Inject(BOT_ROSTER_REPOSITORY) private readonly roster: IBotRosterRepository,
    @Inject(BOT_STATE) private readonly state: IBotState,
  ) {}

  async start(): Promise<void> {
    if (this.timer) return;
    const config = await this.config.get();
    await this.refreshCaches(true);
    this.schedule(config.tickIntervalSec);
    this.logger.log(`Bot engine started (tick=${config.tickIntervalSec}s, enabled=${config.enabled})`);
  }

  stop(): void {
    if (this.timer) { clearInterval(this.timer); this.timer = null; }
  }
  onModuleDestroy(): void { this.stop(); }

  private schedule(tickSec: number): void {
    if (this.timer) clearInterval(this.timer);
    this.currentTickSec = tickSec;
    this.timer = setInterval(() => void this.safeTick(), tickSec * 1000);
  }

  private async safeTick(): Promise<void> {
    if (this.ticking) return;
    this.ticking = true;
    try { await this.tick(); }
    catch (e) { this.logger.error(`tick failed: ${(e as Error).message}`); }
    finally { this.ticking = false; }
  }

  private async tick(): Promise<void> {
    const config = await this.config.get();
    if (config.tickIntervalSec !== this.currentTickSec) this.schedule(config.tickIntervalSec);
    if (!config.enabled) return; // kill-switch

    await this.refreshCaches(false);
    const awake = await this.computeAwake();
    if (awake.length === 0) return;

    await this.runPosts(config, awake);
    await this.runLikes(config, awake);
    await this.runViews(config, awake);
    await this.runFollows(config, awake);
    await this.maybeTournament(config, awake);
    await this.maybeRecord(config, awake);
    await this.maybeRecordLanding(config);
    await this.maybeTournamentUpdate(config);
  }

  // ── streams ────────────────────────────────────────────────────────────────
  private async runPosts(config: BotConfig, awake: BotRow[]): Promise<void> {
    const due = this.due(config.postsPerMin, config.tickIntervalSec);
    this.postCredit = this.capJar(this.postCredit + due, due);

    const windowMs = config.gapWindowSec * 1000;
    const since = Date.now() - windowMs;
    const actualInWindow = this.recentCache.filter((p) => p.createdAt.getTime() >= since).length;
    const targetInWindow = config.postsPerMin * (config.gapWindowSec / 60);

    let posted = 0;
    while (this.postCredit >= 1 && targetInWindow - actualInWindow - posted > 0) {
      const bot = await this.pickPostableBot(awake);
      if (!bot) break;
      this.postCredit -= 1;
      if (await this.activity.doPost(bot.id)) {
        await this.state.startPostCooldown(bot.id, config.botPostCooldownMin * 60);
        posted += 1;
      }
    }
  }

  private async runLikes(config: BotConfig, awake: BotRow[]): Promise<void> {
    const due = this.due(config.likesPerMin, config.tickIntervalSec);
    this.likeCredit = this.capJar(this.likeCredit + due, due);
    while (this.likeCredit >= 1) {
      this.likeCredit -= 1;
      const target = this.pickLikeTarget(config.newestBiasPct);
      if (!target) break;
      const bot = this.pickNonAuthorBot(awake, target.authorId);
      if (!bot) continue;
      if ((await this.state.bumpBotLikeCount(target.id, LIKE_CAP_TTL_SEC)) > config.maxBotLikesPerPost) continue;
      if ((await this.state.bumpBotStreamCount(bot.id, 'like')) > MAX_LIKES_PER_BOT_MIN) continue;
      await this.activity.doLike(target.id, bot.id);
    }
  }

  private async runViews(config: BotConfig, awake: BotRow[]): Promise<void> {
    const due = this.due(config.viewsPerMin, config.tickIntervalSec);
    this.viewCredit = this.capJar(this.viewCredit + due, due);
    const batch = this.recentCache.slice(0, config.viewBatchSize).map((p) => p.id);
    if (batch.length === 0) { this.viewCredit = 0; return; }
    while (this.viewCredit >= 1) {
      this.viewCredit -= 1;
      const bot = this.pickRandom(awake);
      if (!bot) break;
      if ((await this.state.bumpBotStreamCount(bot.id, 'view')) > MAX_VIEWS_PER_BOT_MIN) continue;
      await this.activity.doView(bot.id, batch);
    }
  }

  private async runFollows(config: BotConfig, awake: BotRow[]): Promise<void> {
    const due = this.due(config.followsPerMin, config.tickIntervalSec);
    this.followCredit = this.capJar(this.followCredit + due, due);
    while (this.followCredit >= 1) {
      this.followCredit -= 1;
      const bot = this.pickRandom(awake);
      if (!bot) break;
      if ((await this.state.bumpBotStreamCount(bot.id, 'follow')) > MAX_FOLLOWS_PER_BOT_MIN) continue;
      const followee = await this.roster.randomFolloweeId(bot.id);
      if (followee) await this.activity.doFollow(bot.id, followee);
    }
  }

  /**
   * Steady cadence: one tournament every `86400 / tournaments_per_day` seconds,
   * paced by a Redis "last created" stamp (not per-tick odds, which only work when
   * the scheduler runs ~24/7). Catches up: if due when the engine starts, it fires
   * on the next tick, so tournaments appear reliably even in short/dev runs. Daily
   * cap still enforced.
   */
  private async maybeTournament(config: BotConfig, awake: BotRow[]): Promise<void> {
    if (config.tournamentsPerDay <= 0) return;
    const intervalSec = Math.floor(86400 / config.tournamentsPerDay);
    if (!(await this.state.creationDue('tournament', intervalSec))) return;
    if ((await this.state.bumpTournamentDayCount()) > config.tournamentsPerDay) return;
    const bot = this.pickRandom(awake);
    if (bot) {
      const id = await this.activity.doTournament(bot.id);
      this.logger.log(id ? `Bot ${bot.id} created tournament ${id}` : `Bot ${bot.id} tournament create FAILED`);
    }
  }

  /** Steady cadence: one live record every `86400 / records_per_day` seconds. */
  private async maybeRecord(config: BotConfig, awake: BotRow[]): Promise<void> {
    if (config.recordsPerDay <= 0) return;
    const intervalSec = Math.floor(86400 / config.recordsPerDay);
    if (!(await this.state.creationDue('record', intervalSec))) return;
    if ((await this.state.bumpRecordDayCount()) > config.recordsPerDay) return;
    const bot = this.pickRandom(awake);
    if (bot) {
      const id = await this.activity.doRecord(bot.id);
      this.logger.log(id ? `Bot ${bot.id} went live with record ${id}` : `Bot ${bot.id} record create FAILED`);
    }
  }

  /**
   * Gradual landings: every so often, add ONE more pigeon to some already-live
   * bot record that isn't full yet, so the "Live now" counts tick up over time
   * instead of jumping to the final count at go-live. ~2 landings/min on average.
   * Operates on the whole bot roster (a live record keeps filling regardless of
   * whether its owner is inside an awake window right now).
   */
  private async maybeRecordLanding(config: BotConfig): Promise<void> {
    const ids = this.rosterCache.map((b) => b.id);
    if (ids.length === 0) return;
    const p = Math.min(1, 2 * (config.tickIntervalSec / 60));
    if (Math.random() >= p) return;
    await this.activity.doLiveRecordTick(ids);
  }

  /**
   * Gradual tournament updates: ~2–3 per 5 minutes (≈0.5/min) a random active
   * bot tournament gets one update — a new participant (if it hasn't started) or
   * one more landed pigeon on a running day — so standings and rosters evolve
   * live instead of being fully populated the moment the tournament is created.
   */
  private async maybeTournamentUpdate(config: BotConfig): Promise<void> {
    const ids = this.rosterCache.map((b) => b.id);
    if (ids.length === 0) return;
    const p = Math.min(1, 0.5 * (config.tickIntervalSec / 60));
    if (Math.random() >= p) return;
    await this.activity.doTournamentTick(ids);
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  private due(ratePerMin: number, tickSec: number): number {
    const jitter = 0.85 + Math.random() * 0.3;
    return ratePerMin * (tickSec / 60) * jitter;
  }
  private capJar(value: number, due: number): number {
    return Math.min(value, Math.max(2, Math.ceil(due) + 1));
  }
  private async refreshCaches(force: boolean): Promise<void> {
    const now = Date.now();
    if (force || now - this.rosterAt > ROSTER_REFRESH_MS) {
      this.rosterCache = await this.roster.allActiveBots();
      this.rosterAt = now;
    }
    if (force || now - this.recentAt > RECENT_REFRESH_MS) {
      this.recentCache = await this.postRepo.recentForBots(RECENT_LIMIT);
      this.recentAt = now;
    }
  }
  private async computeAwake(): Promise<BotRow[]> {
    if ((await this.state.getActiveSource()) === 'manual') {
      const sel = new Set(await this.state.getManualSelection());
      return this.rosterCache.filter((b) => sel.has(b.id));
    }
    const hour = new Date().getUTCHours();
    return this.rosterCache.filter((b) => isAwakeInWindow(b.activeStartHour, b.activeEndHour, hour));
  }
  private async pickPostableBot(awake: BotRow[]): Promise<BotRow | null> {
    const order = this.shuffle(awake);
    const scan = Math.min(order.length, MAX_COOLDOWN_SCAN);
    for (let i = 0; i < scan; i++) if (!(await this.state.isOnPostCooldown(order[i].id))) return order[i];
    return null;
  }
  private pickLikeTarget(newestBiasPct: number): RecentPost | null {
    if (this.recentCache.length === 0) return null;
    const front = Math.min(FRONT_SIZE, this.recentCache.length);
    const pool = Math.random() * 100 < newestBiasPct ? this.recentCache.slice(0, front) : this.recentCache;
    return pool[Math.floor(Math.random() * pool.length)];
  }
  private pickNonAuthorBot(awake: BotRow[], authorId: string): BotRow | null {
    for (let i = 0; i < NON_AUTHOR_TRIES; i++) {
      const bot = this.pickRandom(awake);
      if (bot && bot.id !== authorId) return bot;
    }
    return null;
  }
  private pickRandom(awake: BotRow[]): BotRow | null {
    return awake.length ? awake[Math.floor(Math.random() * awake.length)] : null;
  }
  private shuffle(rows: BotRow[]): BotRow[] {
    const a = [...rows];
    for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; }
    return a;
  }
}
