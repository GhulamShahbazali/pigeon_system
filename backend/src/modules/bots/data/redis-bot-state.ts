import { Injectable } from '@nestjs/common';
import { RedisService } from '../../../shared/redis/redis.service';
import { ActiveSource, IBotState } from '../domain/bot.repositories';

const KEY_ACTIVE_SOURCE = 'bots:active_source';
const KEY_MANUAL_SELECTION = 'bots:manual_selection';
const cooldownKey = (botId: string) => `bots:cooldown:${botId}`;
const dayKey = () => `bots:tournaments:${new Date().toISOString().slice(0, 10)}`;
const recDayKey = () => `bots:records:${new Date().toISOString().slice(0, 10)}`;

@Injectable()
export class RedisBotState implements IBotState {
  constructor(private readonly redis: RedisService) {}

  async getActiveSource(): Promise<ActiveSource> {
    return (await this.redis.client.get(KEY_ACTIVE_SOURCE)) === 'manual' ? 'manual' : 'schedule';
  }
  async setActiveSource(source: ActiveSource): Promise<void> {
    await this.redis.client.set(KEY_ACTIVE_SOURCE, source);
  }
  getManualSelection(): Promise<string[]> {
    return this.redis.client.smembers(KEY_MANUAL_SELECTION);
  }
  async setManualSelection(ids: string[]): Promise<void> {
    const m = this.redis.client.multi();
    m.del(KEY_MANUAL_SELECTION);
    if (ids.length) m.sadd(KEY_MANUAL_SELECTION, ...ids);
    await m.exec();
  }
  async isOnPostCooldown(botId: string): Promise<boolean> {
    return (await this.redis.client.exists(cooldownKey(botId))) === 1;
  }
  async startPostCooldown(botId: string, seconds: number): Promise<void> {
    await this.redis.client.set(cooldownKey(botId), '1', 'EX', Math.max(1, seconds));
  }
  async bumpBotLikeCount(postId: string, ttlSeconds: number): Promise<number> {
    const key = `bots:likes:${postId}`;
    const n = await this.redis.client.incr(key);
    if (n === 1) await this.redis.client.expire(key, Math.max(1, ttlSeconds));
    return n;
  }
  async bumpBotStreamCount(botId: string, stream: 'like' | 'view' | 'follow'): Promise<number> {
    const key = `bots:rate:${stream}:${botId}`;
    const n = await this.redis.client.incr(key);
    if (n === 1) await this.redis.client.expire(key, 60);
    return n;
  }
  async bumpTournamentDayCount(): Promise<number> {
    const key = dayKey();
    const n = await this.redis.client.incr(key);
    if (n === 1) await this.redis.client.expire(key, 36 * 3600);
    return n;
  }
  async bumpRecordDayCount(): Promise<number> {
    const key = recDayKey();
    const n = await this.redis.client.incr(key);
    if (n === 1) await this.redis.client.expire(key, 36 * 3600);
    return n;
  }

  async creationDue(kind: 'tournament' | 'record', intervalSec: number): Promise<boolean> {
    const key = `bots:lastcreate:${kind}`;
    const last = await this.redis.client.get(key);
    const now = Date.now();
    if (last && now - Number(last) < intervalSec * 1000) return false;
    // Stamp now so the next one waits a full interval; keep it comfortably longer.
    await this.redis.client.set(key, String(now), 'EX', Math.max(Math.ceil(intervalSec * 3), 3600));
    return true;
  }
}
