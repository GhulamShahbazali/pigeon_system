import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { JobsOptions, Queue } from 'bullmq';
import { RedisService } from '../redis/redis.service';
import { QueueName } from './queue.constants';

/** Enqueues BullMQ jobs. The API uses this to add jobs; workers process them (worker.module). */
@Injectable()
export class QueueService implements OnModuleDestroy {
  private readonly queues = new Map<string, Queue>();

  constructor(private readonly redis: RedisService) {}

  private get(name: QueueName): Queue {
    let q = this.queues.get(name);
    if (!q) {
      q = new Queue(name, { connection: this.redis.client });
      this.queues.set(name, q);
    }
    return q;
  }

  add(queue: QueueName, jobName: string, data: unknown, opts?: JobsOptions) {
    return this.get(queue).add(jobName, data, {
      removeOnComplete: 1000,
      removeOnFail: 5000,
      attempts: 3,
      backoff: { type: 'exponential', delay: 2000 },
      ...opts,
    });
  }

  async onModuleDestroy(): Promise<void> {
    await Promise.all([...this.queues.values()].map((q) => q.close()));
  }
}
