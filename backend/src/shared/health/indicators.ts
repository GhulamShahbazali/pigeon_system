import { Injectable, BeforeApplicationShutdown, Logger } from '@nestjs/common';
import { HealthIndicator, HealthIndicatorResult, HealthCheckError } from '@nestjs/terminus';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';

@Injectable()
export class PrismaHealthIndicator extends HealthIndicator {
  constructor(private readonly prisma: PrismaService) {
    super();
  }
  async ping(key = 'database'): Promise<HealthIndicatorResult> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return this.getStatus(key, true);
    } catch (e) {
      throw new HealthCheckError('Prisma down', this.getStatus(key, false, { message: (e as Error).message }));
    }
  }
}

@Injectable()
export class RedisHealthIndicator extends HealthIndicator {
  constructor(private readonly redis: RedisService) {
    super();
  }
  async ping(key = 'redis'): Promise<HealthIndicatorResult> {
    try {
      const pong = await this.redis.client.ping();
      return this.getStatus(key, pong === 'PONG');
    } catch (e) {
      throw new HealthCheckError('Redis down', this.getStatus(key, false, { message: (e as Error).message }));
    }
  }
}

/**
 * Flips to "draining" on SIGTERM so the readiness probe fails first — the load
 * balancer stops routing new traffic, in-flight requests finish, THEN Nest's
 * shutdown hooks close Redis/Prisma/BullMQ. This is zero-downtime rollout.
 */
@Injectable()
export class ShutdownService implements BeforeApplicationShutdown {
  private readonly logger = new Logger('Shutdown');
  private _draining = false;
  get draining(): boolean {
    return this._draining;
  }
  async beforeApplicationShutdown(signal?: string): Promise<void> {
    this._draining = true;
    const ms = Number(process.env.SHUTDOWN_DRAIN_MS ?? 5000);
    this.logger.log(`Draining (signal=${signal}) — waiting ${ms}ms for LB + in-flight requests`);
    await new Promise((r) => setTimeout(r, ms));
  }
}
