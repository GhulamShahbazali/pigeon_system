import { Injectable, Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaRecordRepository } from './data/prisma-record.repository';
import { EmitService } from '../../shared/socket/emit.service';

/** Midnight (owner-local) auto-end: live → completed, kept in history. Idempotent. */
@Injectable()
export class LiveRecordAutoEndProcessor {
  private readonly logger = new Logger('LiveRecordAutoEnd');

  constructor(
    private readonly repo: PrismaRecordRepository,
    private readonly emit: EmitService,
  ) {}

  async handle(job: Job<{ recordId: string }>): Promise<void> {
    const ended = await this.repo.end(job.data.recordId);
    if (ended) {
      this.emit.toRoom(`record:${job.data.recordId}`, 'record.live_ended', {
        record_id: job.data.recordId,
        reason: 'auto_midnight',
      });
      this.logger.log(`Auto-ended live record ${job.data.recordId}`);
    }
  }
}
