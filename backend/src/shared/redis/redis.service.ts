import { Injectable, OnModuleDestroy, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import IORedis, { Redis } from 'ioredis';

/**
 * Shared ioredis client (Aiven Valkey, TLS). BullMQ-friendly options.
 * Use `duplicate()` for the Socket.io adapter's separate pub/sub connections.
 */
@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  readonly client: Redis;

  constructor(private readonly config: ConfigService) {
    const url = this.config.getOrThrow<string>('REDIS_URL');
    this.client = new IORedis(url, {
      maxRetriesPerRequest: null, // required by BullMQ
      enableReadyCheck: false,
      tls: url.startsWith('rediss://') ? {} : undefined,
    });
    this.client.on('error', (e) => this.logger.error(`Redis error: ${e.message}`));
    this.client.on('connect', () => this.logger.log('Redis connected'));
  }

  /**
   * Separate connection (Socket.io adapter pub/sub, BullMQ workers). Always attach
   * an error handler — an unhandled ioredis 'error' event would otherwise crash the
   * process on a transient network blip.
   */
  duplicate(): Redis {
    const conn = this.client.duplicate();
    conn.on('error', (e) => this.logger.error(`Redis (dup) error: ${e.message}`));
    return conn;
  }

  async onModuleDestroy(): Promise<void> {
    await this.client.quit();
  }
}
