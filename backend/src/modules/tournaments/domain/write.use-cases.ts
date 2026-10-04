import { Inject, Injectable } from '@nestjs/common';
import {
  AddParticipantInput,
  CreateTournamentInput,
  ITournamentRepository,
  RecordFlightInput,
  TOURNAMENT_REPOSITORY,
} from './tournament.repository';
import { Err, Ok, Result } from '../../../shared/result/result';
import { DomainError } from '../../../shared/errors/domain-error';
import { ForbiddenError, NotFoundError } from '../../../shared/errors/common-errors';
import { EmitService } from '../../../shared/socket/emit.service';
import { QueueService } from '../../../shared/queue/queue.service';
import { QUEUES } from '../../../shared/queue/queue.constants';

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
  constructor(@Inject(TOURNAMENT_REPOSITORY) private readonly repo: ITournamentRepository) {}
  async execute(actorId: string, input: AddParticipantInput): Promise<Result<any>> {
    const t = await this.repo.findSummary(input.tournamentId);
    if (!t) return Err(new NotFoundError('tournament'));
    if (t.organizerId !== actorId) return Err(new ForbiddenError('Only the organizer can add participants'));
    return Ok(await this.repo.addParticipant(input));
  }
}

@Injectable()
export class RecordFlightUseCase {
  constructor(
    @Inject(TOURNAMENT_REPOSITORY) private readonly repo: ITournamentRepository,
    private readonly emit: EmitService,
  ) {}
  async execute(actorId: string, input: RecordFlightInput): Promise<Result<any>> {
    const t = await this.repo.findSummary(input.tournamentId);
    if (!t) return Err(new NotFoundError('tournament'));
    if (t.organizerId !== actorId) return Err(new ForbiddenError('Only the organizer can record flights'));
    try {
      const flight = await this.repo.recordFlight(input);
      // Push the refreshed leaderboard to everyone watching this tournament live.
      const standings = await this.repo.standings(input.tournamentId);
      this.emit.toRoom(`tournament:${input.tournamentId}`, 'tournament.update', {
        tournament_id: input.tournamentId,
        day_id: input.dayId,
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
export class TournamentSocialUseCase {
  constructor(@Inject(TOURNAMENT_REPOSITORY) private readonly repo: ITournamentRepository) {}
  follow = (tid: string, uid: string) => this.repo.toggleFollow(tid, uid, true);
  unfollow = (tid: string, uid: string) => this.repo.toggleFollow(tid, uid, false);
  like = (tid: string, uid: string) => this.repo.toggleLike(tid, uid, true);
  unlike = (tid: string, uid: string) => this.repo.toggleLike(tid, uid, false);
}
