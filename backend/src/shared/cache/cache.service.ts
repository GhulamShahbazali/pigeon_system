import { Injectable, Logger } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';

/**
 * Cache-aside helper over Redis/Valkey. Every method is fail-open: if Redis is
 * unreachable the request still succeeds against the DB (cache is an optimization,
 * never a dependency). Always set a TTL — Valkey is in-memory.
 */
@Injectable()
export class CacheService {
  private readonly logger = new Logger('Cache');

  constructor(private readonly redis: RedisService) {}

  async get<T>(key: string): Promise<T | null> {
    try {
      const v = await this.redis.client.get(key);
      return v ? (JSON.parse(v) as T) : null;
    } catch {
      return null;
    }
  }

  async set(key: string, value: unknown, ttlSeconds: number): Promise<void> {
    try {
      await this.redis.client.set(key, JSON.stringify(value), 'EX', ttlSeconds);
    } catch {
      /* fail-open */
    }
  }

  async del(...keys: string[]): Promise<void> {
    try {
      if (keys.length) await this.redis.client.del(...keys);
    } catch {
      /* fail-open */
    }
  }

  /** Cache-aside: return cached value, else run loader, cache it, return it. */
  async getOrSet<T>(key: string, ttlSeconds: number, loader: () => Promise<T>): Promise<T> {
    const hit = await this.get<T>(key);
    if (hit !== null) return hit;
    const fresh = await loader();
    await this.set(key, fresh, ttlSeconds);
    return fresh;
  }

  /** Delete every key under a prefix using SCAN (never KEYS — non-blocking in prod). */
  async delByPrefix(prefix: string): Promise<void> {
    try {
      let cursor = '0';
      do {
        const [next, keys] = await this.redis.client.scan(cursor, 'MATCH', `${prefix}*`, 'COUNT', 200);
        cursor = next;
        if (keys.length) await this.redis.client.del(...keys);
      } while (cursor !== '0');
    } catch {
      /* fail-open */
    }
  }
}
