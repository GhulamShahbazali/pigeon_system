import { Inject, Injectable } from '@nestjs/common';
import { ITournamentRepository, TOURNAMENT_REPOSITORY } from './tournament.repository';
import { NotFoundError } from '../../../shared/errors/common-errors';

@Injectable()
export class TournamentQueries {
  constructor(@Inject(TOURNAMENT_REPOSITORY) private readonly repo: ITournamentRepository) {}

  list(tab: 'all' | 'following' | 'mine', userId: string, cursor: string | null, limit: number) {
    return this.repo.list(tab, userId, cursor, limit);
  }

  async detail(id: string, viewerId: string) {
    const t = await this.repo.findDetail(id);
    if (!t) throw new NotFoundError('tournament');
    await this.repo.recordView(id, viewerId);
    return t;
  }

  standings(id: string) {
    return this.repo.standings(id);
  }

  participantDays(tournamentId: string, participantId: string) {
    return this.repo.participantDays(tournamentId, participantId);
  }
}
