import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { BotEngine } from './bot-engine';

/**
 * Starts the bot engine in the SCHEDULER process only (PROCESS_ROLE=scheduler or
 * SCHEDULER_ENABLED=true) — the same single-instance guarantee that governs cron.
 * In the api/worker processes this stays idle, so exactly one engine ever runs.
 */
@Injectable()
export class BotEngineBootstrap implements OnModuleInit {
  private readonly logger = new Logger('BotEngineBootstrap');
  constructor(private readonly engine: BotEngine) {}

  async onModuleInit(): Promise<void> {
    const role = process.env.PROCESS_ROLE ?? 'api';
    const isScheduler = role === 'scheduler' || process.env.SCHEDULER_ENABLED === 'true';
    if (!isScheduler) return;
    await this.engine.start();
    this.logger.log('Bot engine attached to the scheduler process');
  }
}
