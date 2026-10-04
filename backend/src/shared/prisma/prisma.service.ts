import { Injectable, OnModuleDestroy, OnModuleInit, Logger } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);

  constructor() {
    // Managed Postgres (Aiven) adds round-trip latency, and cold connections make
    // the first queries slow. Raise the interactive-transaction defaults so multi-step
    // writes don't trip Prisma's 5s cap. Hot paths may still override per-call.
    super({ transactionOptions: { timeout: 20000, maxWait: 15000 } });
  }

  async onModuleInit(): Promise<void> {
    await this.$connect();
    this.logger.log('Prisma connected');
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
