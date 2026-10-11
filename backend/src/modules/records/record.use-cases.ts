import { Injectable } from '@nestjs/common';
import { PrismaRecordRepository } from './data/prisma-record.repository';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { EmitService } from '../../shared/socket/emit.service';
import { QueueService } from '../../shared/queue/queue.service';
import { QUEUES } from '../../shared/queue/queue.constants';
import { NotificationsService } from '../notifications/notifications.service';
import { Err, Ok, Result } from '../../shared/result/result';
import { ConflictError, ForbiddenError, NotFoundError } from '../../shared/errors/common-errors';

@Injectable()
export class RecordUseCases {
  constructor(
    private readonly repo: PrismaRecordRepository,
    private readonly prisma: PrismaService,
    private readonly emit: EmitService,
    private readonly queue: QueueService,
    private readonly notifs: NotificationsService,
  ) {}

  create(userId: string, input: any) {
    return this.repo.create(userId, input);
  }
  listMine = (userId: string, limit: number) => this.repo.listMine(userId, limit);
  liveNow = (viewerId: string, limit: number) => this.repo.liveNow(viewerId, limit);

  async detail(id: string, viewerId: string): Promise<Result<any>> {
    const r = await this.repo.detail(id);
    if (r.privacy === 'private' && r.userId !== viewerId) return Err(new NotFoundError('record'));
    if (r.userId !== viewerId) await this.repo.recordView(id, viewerId);
    return Ok(r);
  }

  async addPigeon(actorId: string, recordId: string, pigeonName: string, landingTime: Date): Promise<Result<any>> {
    const rec = await this.repo.findSummary(recordId);
    if (!rec) return Err(new NotFoundError('record'));
    if (rec.userId !== actorId) return Err(new ForbiddenError('Only the owner can add pigeons'));
    const pigeon = await this.repo.addPigeon(recordId, rec.releaseAt, pigeonName, landingTime);
    if (rec.privacy === 'live' && rec.status === 'open') {
      const updated = await this.prisma.personalRecord.findUnique({
        where: { id: recordId },
        select: { totalAvgSeconds: true, returnedCount: true, totalPigeons: true },
      });
      this.emit.toRoom(`record:${recordId}`, 'record.update', {
        record_id: recordId,
        pigeon_name: pigeonName,
        landing_time: landingTime.toISOString(),
        duration_seconds: pigeon.durationSeconds,
        total_avg_seconds: updated?.totalAvgSeconds ?? null,
        landed_count: updated?.returnedCount ?? 0,
        total_count: updated?.totalPigeons ?? 0,
      });
    }
    return Ok(pigeon);
  }

  async goLive(actorId: string, recordId: string): Promise<Result<any>> {
    const rec = await this.repo.findSummary(recordId);
    if (!rec) return Err(new NotFoundError('record'));
    if (rec.userId !== actorId) return Err(new ForbiddenError('Only the owner can go live'));
    // A record lives for 24h then auto-ends; once ended it can never go live again.
    if (rec.status === 'completed') return Err(new ConflictError('This record has ended and cannot go live again'));
    const user = await this.prisma.user.findUnique({ where: { id: actorId }, select: { timezone: true } });
    const r = await this.repo.goLive(recordId, user?.timezone ?? 'Asia/Karachi');

    const delay = Math.max(0, (r.autoEndAt?.getTime() ?? Date.now()) - Date.now());
    // BullMQ custom job ids may not contain ':'. Stable id keeps auto-end idempotent.
    await this.queue.add(QUEUES.liveRecordAutoEnd, 'end', { recordId }, { delay, jobId: `record-end-${recordId}` });

    const followers = await this.repo.followerIds(actorId);
    for (const f of followers) {
      this.emit.toUser(f, 'record.live_started', { record_id: recordId, owner_id: actorId });
      await this.notifs.notify({ recipientId: f, type: 'record_live_started', entityType: 'record', entityId: recordId, actorId });
    }
    return Ok(r);
  }

  async end(actorId: string, recordId: string): Promise<Result<any>> {
    const rec = await this.repo.findSummary(recordId);
    if (!rec) return Err(new NotFoundError('record'));
    if (rec.userId !== actorId) return Err(new ForbiddenError('Only the owner can end'));
    await this.repo.end(recordId);
    this.emit.toRoom(`record:${recordId}`, 'record.live_ended', { record_id: recordId });
    return Ok({ id: recordId, status: 'completed' });
  }

  like = (id: string, uid: string) => this.repo.toggleLike(id, uid, true);
  unlike = (id: string, uid: string) => this.repo.toggleLike(id, uid, false);
}
