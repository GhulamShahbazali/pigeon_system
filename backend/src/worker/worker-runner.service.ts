import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Job, Worker } from 'bullmq';
import { Server } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { RedisService } from '../shared/redis/redis.service';
import { EmitService } from '../shared/socket/emit.service';
import { QUEUES, QueueName } from '../shared/queue/queue.constants';
import { PushSendProcessor } from '../modules/notifications/push-send.processor';
import { FollowerFanoutProcessor } from '../modules/notifications/follower-fanout.processor';
import { DmPushProcessor } from '../modules/messages/dm-push.processor';
import { LiveRecordAutoEndProcessor } from '../modules/records/live-record-auto-end.processor';

type Handler = (job: Job) => Promise<void>;

/**
 * Registers every BullMQ Worker in the worker process (PROCESS_ROLE=worker|scheduler).
 * In the API process this provider stays dormant so the API never competes for jobs.
 *
 * Socket emits raised from jobs (e.g. live auto-end) need a Socket.io server. The
 * worker has no HTTP gateway, so we attach a server-less Socket.io instance to the
 * same Redis adapter the API nodes use; emits publish to the adapter and the API
 * nodes deliver them to connected clients. (Standard multi-node emitter pattern.)
 */
@Injectable()
export class WorkerRunner implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger('WorkerRunner');
  private readonly workers: Worker[] = [];
  private emitterServer?: Server;

  constructor(
    private readonly redis: RedisService,
    private readonly emit: EmitService,
    private readonly pushSend: PushSendProcessor,
    private readonly fanout: FollowerFanoutProcessor,
    private readonly dmPush: DmPushProcessor,
    private readonly autoEnd: LiveRecordAutoEndProcessor,
  ) {}

  onModuleInit(): void {
    const role = process.env.PROCESS_ROLE ?? 'api';
    if (role !== 'worker' && role !== 'scheduler') return;

    this.wireEmitter();

    const concurrency = Number(process.env.WORKER_CONCURRENCY ?? 10);
    this.spawn(QUEUES.pushSend, (j) => this.pushSend.handle(j as any), concurrency);
    this.spawn(QUEUES.dmPush, (j) => this.dmPush.handle(j as any), concurrency);
    this.spawn(QUEUES.followerFanout, (j) => this.fanout.handle(j as any), 3);
    this.spawn(QUEUES.liveRecordAutoEnd, (j) => this.autoEnd.handle(j as any), concurrency);

    this.logger.log(`Workers online for: ${this.workers.map((w) => w.name).join(', ')}`);
  }

  /** Server-less Socket.io instance on the Redis adapter, used only as an emitter. */
  private wireEmitter(): void {
    const server = new Server({ cors: { origin: '*' } });
    server.adapter(createAdapter(this.redis.duplicate(), this.redis.duplicate()));
    this.emit.setServer(server);
    this.emitterServer = server;
  }

  private spawn(queue: QueueName, handler: Handler, concurrency: number): void {
    const worker = new Worker(
      queue,
      async (job) => {
        await handler(job);
      },
      { connection: this.redis.duplicate(), concurrency },
    );
    worker.on('failed', (job, err) =>
      this.logger.error(`[${queue}] job ${job?.id} failed: ${err.message}`),
    );
    this.workers.push(worker);
  }

  async onModuleDestroy(): Promise<void> {
    await Promise.all(this.workers.map((w) => w.close()));
    await this.emitterServer?.close();
  }
}
