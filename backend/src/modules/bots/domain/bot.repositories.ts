/**
 * Bot-system repository + state ports. Pure interfaces — no Prisma/Redis types
 * leak here. Concrete impls live in ../data.
 */

/** The singleton `bot_config` knobs the engine reads live each tick. */
export interface BotConfig {
  enabled: boolean;
  tickIntervalSec: number;
  gapWindowSec: number;
  postsPerMin: number;
  botPostCooldownMin: number;
  likesPerMin: number;
  newestBiasPct: number;
  maxBotLikesPerPost: number;
  viewsPerMin: number;
  viewBatchSize: number;
  followsPerMin: number;
  tournamentsPerDay: number;
  recordsPerDay: number;
}

/** One bot as the engine needs it: identity + its UTC active window. */
export interface BotRow {
  id: string;
  activeStartHour: number | null;
  activeEndHour: number | null;
}

export interface IBotConfigRepository {
  get(): Promise<BotConfig>;
  update(patch: Partial<BotConfig>): Promise<BotConfig>;
}

export interface IBotRosterRepository {
  /** Every live bot (is_bot, not soft-deleted) with its window. */
  allActiveBots(): Promise<BotRow[]>;
  /** A random user id (bot or real, not `exceptId`, not blocked-irrelevant) for a bot to follow. */
  randomFolloweeId(exceptId: string): Promise<string | null>;
  /** Participant-name pool for a country (for tournament seeding). */
  // (names come from the content provider; roster only reads users)
}

export type ActiveSource = 'schedule' | 'manual';

export interface IBotState {
  getActiveSource(): Promise<ActiveSource>;
  setActiveSource(source: ActiveSource): Promise<void>;
  getManualSelection(): Promise<string[]>;
  setManualSelection(ids: string[]): Promise<void>;
  isOnPostCooldown(botId: string): Promise<boolean>;
  startPostCooldown(botId: string, seconds: number): Promise<void>;
  bumpBotLikeCount(postId: string, ttlSeconds: number): Promise<number>;
  bumpBotStreamCount(botId: string, stream: 'like' | 'view' | 'follow'): Promise<number>;
  /** Daily tournament counter (so tournaments_per_day is respected across ticks). */
  bumpTournamentDayCount(): Promise<number>;
  /** Daily live-record counter (records_per_day). */
  bumpRecordDayCount(): Promise<number>;
  /**
   * True (and stamps "now") when at least `intervalSec` has passed since the last
   * creation of `kind`. Time-based pacing so rare events (tournaments/records) fire
   * reliably even when the scheduler runs only intermittently — unlike per-tick odds,
   * which need ~24/7 running to ever hit.
   */
  creationDue(kind: 'tournament' | 'record', intervalSec: number): Promise<boolean>;
}
