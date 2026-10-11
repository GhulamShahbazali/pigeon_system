import { Controller, Get } from '@nestjs/common';
import { HealthCheck, HealthCheckService, HealthCheckError, HealthIndicatorResult } from '@nestjs/terminus';
import { SkipThrottle } from '@nestjs/throttler';
import { Public } from '../auth/decorators';
import { PrismaHealthIndicator, RedisHealthIndicator, ShutdownService } from './indicators';

@Controller('health')
@Public()
@SkipThrottle()
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    private readonly prisma: PrismaHealthIndicator,
    private readonly redis: RedisHealthIndicator,
    private readonly shutdown: ShutdownService,
  ) {}

  /** Liveness — is the process up? (restart signal for the LB/orchestrator). */
  @Get()
  @HealthCheck()
  live() {
    return this.health.check([]);
  }

  /** Readiness — can we serve traffic? DB + Redis up AND not draining. */
  @Get('ready')
  @HealthCheck()
  ready() {
    return this.health.check([
      () => this.prisma.ping('database'),
      () => this.redis.ping('redis'),
      () => this.notDraining(),
    ]);
  }

  private async notDraining(): Promise<HealthIndicatorResult> {
    if (this.shutdown.draining) {
      throw new HealthCheckError('draining', { draining: { status: 'down' } });
    }
    return { draining: { status: 'up' } };
  }
}
