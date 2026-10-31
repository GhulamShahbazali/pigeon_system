import { Injectable, OnModuleDestroy, OnModuleInit, Logger } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);

  constructor() {
    let dbUrl = process.env.DATABASE_URL;
    if (dbUrl && !dbUrl.includes('connection_limit=')) {
      const sep = dbUrl.includes('?') ? '&' : '?';
      dbUrl = `${dbUrl}${sep}connection_limit=5&pool_timeout=20`;
    }
    super({
      ...(dbUrl ? { datasources: { db: { url: dbUrl } } } : {}),
      transactionOptions: { timeout: 20000, maxWait: 15000 },
    });
  }

  async onModuleInit(): Promise<void> {
    // Don't crash-loop if the DB is briefly unreachable at boot — start anyway and
    // let the readiness probe gate traffic; Prisma lazy-connects on the first query.
    try {
      await this.$connect();
      this.logger.log('Prisma connected');
    } catch (e) {
      this.logger.error(`Prisma connect failed at boot (will retry lazily): ${(e as Error).message}`);
    }
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
