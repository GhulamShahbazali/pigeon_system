import { Module } from '@nestjs/common';
import { ThrottlerModule } from '@nestjs/throttler';
import { ThrottlerStorageRedisService } from '@nest-lab/throttler-storage-redis';
import { RedisService } from '../redis/redis.service';

/**
 * Global rate limiting backed by Redis so the limit is shared across every API
 * instance (a per-process in-memory limiter would let N instances serve N×limit).
 * Default bucket = 100 req / 60s per client; per-route caps via @Throttle(),
 * exemptions via @SkipThrottle(). Behind Nginx, enable trust-proxy so the real
 * client IP (not the proxy's) is the key.
 */
@Module({
  imports: [
    ThrottlerModule.forRootAsync({
      inject: [RedisService],
      useFactory: (redis: RedisService) => ({
        throttlers: [{ ttl: 60_000, limit: 100 }],
        storage: new ThrottlerStorageRedisService(redis.duplicate()),
      }),
    }),
  ],
  exports: [ThrottlerModule],
})
export class AppThrottlerModule {}
