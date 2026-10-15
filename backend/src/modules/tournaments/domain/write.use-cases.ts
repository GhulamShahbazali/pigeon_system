import { Inject, Injectable } from '@nestjs/common';
import {
  AddParticipantInput,
  CreateTournamentInput,
  ITournamentRepository,
  RecordFlightInput,
  TOURNAMENT_REPOSITORY,
  UpdateFlightInput,
} from './tournament.repository';
import { Err, Ok, Result } from '../../../shared/result/result';
import { DomainError } from '../../../shared/errors/domain-error';
import { ForbiddenError, NotFoundError } from '../../../shared/errors/common-errors';
import { EmitService } from '../../../shared/socket/emit.service';
import { QueueService } from '../../../shared/queue/queue.service';
import { QUEUES } from '../../../shared/queue/queue.constants';
import { CacheService } from '../../../shared/cache/cache.service';
import { standingsKey } from './read.use-cases';

@Injectable()
export class CreateTournamentUseCase {
  constructor(
    @Inject(TOURNAMENT_REPOSITORY) private readonly repo: ITournamentRepository,
    private readonly queue: QueueService,
  ) {}
  async execute(input: CreateTournamentInput): Promise<Result<{ id: string }>> {
    const id = await this.repo.create(input);
    // Notify the organizer's social followers that a new tournament is up.
    await this.queue.add(QUEUES.followerFanout, 'fanout', {
      actorId: input.organizerId,
      type: 'tournament_created',
      entityType: 'tournament',
      entityId: id,
    });
    return Ok({ id });
  }
}

@Injectable()
export class AddParticipantUseCase {
  constructor(
    @Inject(TOURNAMENT_REPOSITORY) private readonly repo: ITournamentRepository,
    private readonly cache: CacheService,
    private readonly queue: QueueService,
  ) {}
  async execute(actorId: string, input: AddParticipantInput): Promise<Result<any>> {
    const t = await this.repo.findSummary(input.tournamentId);
    if (!t) return Err(new NotFoundError('tournament'));
    if (t.organizerId !== actorId) return Err(new ForbiddenError('Only the organizer can add participants'));
    const participant = await this.repo.addParticipant(input);
    await this.cache.del(standingsKey(input.tournamentId)); // new participant appears in standings

    await this.queue.add(QUEUES.followerFanout, 'fanout', {
      actorId,
      type: 'participant_added',
      entityType: 'tournament',
      entityId: input.tournamentId,
    });

    return Ok(participant);
  }
}

@Injectable()
export class RecordFlightUseCase {
  constructor(
    @Inject(TOURNAMENT_REPOSITORY) private readonly repo: ITournamentRepository,
    private readonly emit: EmitService,
    private readonly cache: CacheService,
    private readonly queue: QueueService,
  ) {}
  async execute(actorId: string, input: RecordFlightInput): Promise<Result<any>> {
    const t = await this.repo.findSummary(input.tournamentId);
    if (!t) return Err(new NotFoundError('tournament'));
    if (t.organizerId !== actorId) return Err(new ForbiddenError('Only the organizer can record flights'));
    try {
      const flight = await this.repo.recordFlight(input);
      // Fresh standings recomputed in the write txn → refresh cache + push to watchers.
      const standings = await this.repo.standings(input.tournamentId);
      await this.cache.set(standingsKey(input.tournamentId), standings, 20);
      this.emit.toRoom(`tournament:${input.tournamentId}`, 'tournament.update', {
        tournament_id: input.tournamentId,
        day_id: input.dayId,
        standings,
      });

      await this.queue.add(QUEUES.followerFanout, 'fanout', {
        actorId,
        type: 'tournament_day_results',
        entityType: 'tournament',
        entityId: input.tournamentId,
      });

      return Ok(flight);
    } catch (e) {
      if (e instanceof DomainError) return Err(e);
      throw e;
    }
  }
}

@Injectable()
export class UpdateFlightUseCase {
  constructor(
    @Inject(TOURNAMENT_REPOSITORY) private readonly repo: ITournamentRepository,
    private readonly emit: EmitService,
    private readonly cache: CacheService,
  ) {}
  async execute(actorId: string, input: UpdateFlightInput): Promise<Result<any>> {
    const t = await this.repo.findSummary(input.tournamentId);
    if (!t) return Err(new NotFoundError('tournament'));
    if (t.organizerId !== actorId) return Err(new ForbiddenError('Only the organizer can edit flights'));
    try {
      const flight = await this.repo.updateFlight(input);
      const standings = await this.repo.standings(input.tournamentId);
      await this.cache.set(standingsKey(input.tournamentId), standings, 20);
      this.emit.toRoom(`tournament:${input.tournamentId}`, 'tournament.update', {
        tournament_id: input.tournamentId,
        standings,
      });
      return Ok(flight);
    } catch (e) {
      if (e instanceof DomainError) return Err(e);
      throw e;
    }
  }
}

@Injectable()
export class DeleteFlightUseCase {
  constructor(
    @Inject(TOURNAMENT_REPOSITORY) private readonly repo: ITournamentRepository,
    private readonly emit: EmitService,
    private readonly cache: CacheService,
  ) {}
  async execute(actorId: string, tournamentId: string, participantId: string, flightId: string): Promise<Result<null>> {
    const t = await this.repo.findSummary(tournamentId);
    if (!t) return Err(new NotFoundError('tournament'));
    if (t.organizerId !== actorId) return Err(new ForbiddenError('Only the organizer can delete flights'));
    try {
      await this.repo.deleteFlight(tournamentId, participantId, flightId);
      const standings = await this.repo.standings(tournamentId);
      await this.cache.set(standingsKey(tournamentId), standings, 20);
      this.emit.toRoom(`tournament:${tournamentId}`, 'tournament.update', {
        tournament_id: tournamentId,
        standings,
      });
      return Ok(null);
    } catch (e) {
      if (e instanceof DomainError) return Err(e);
      throw e;
    }
  }
}

@Injectable()
export class TournamentSocialUseCase {
  constructor(@Inject(TOURNAMENT_REPOSITORY) private readonly repo: ITournamentRepository) {}
  follow = (tid: string, uid: string) => this.repo.toggleFollow(tid, uid, true);
  unfollow = (tid: string, uid: string) => this.repo.toggleFollow(tid, uid, false);
  like = (tid: string, uid: string) => this.repo.toggleLike(tid, uid, true);
  unlike = (tid: string, uid: string) => this.repo.toggleLike(tid, uid, false);
}
