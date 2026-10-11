import { Inject, Injectable } from '@nestjs/common';
import { ITournamentRepository, TOURNAMENT_REPOSITORY } from './tournament.repository';
import { NotFoundError } from '../../../shared/errors/common-errors';
import { CacheService } from '../../../shared/cache/cache.service';

/** Cache key for a tournament's standings (shared across all viewers). */
export const standingsKey = (id: string) => `t:standings:${id}`;

@Injectable()
export class TournamentQueries {
  constructor(
    @Inject(TOURNAMENT_REPOSITORY) private readonly repo: ITournamentRepository,
    private readonly cache: CacheService,
  ) {}

  list(tab: 'all' | 'following' | 'mine', userId: string, cursor: string | null, limit: number) {
    return this.repo.list(tab, userId, cursor, limit);
  }

  async detail(id: string, viewerId: string) {
    const t = await this.repo.findDetail(id);
    if (!t) throw new NotFoundError('tournament');
    await this.repo.recordView(id, viewerId);
    return t;
  }

  /** Hot path during live events — cache-aside, 20s TTL. Sockets carry live deltas. */
  standings(id: string) {
    return this.cache.getOrSet(standingsKey(id), 20, () => this.repo.standings(id));
  }

  participantDays(tournamentId: string, participantId: string) {
    return this.repo.participantDays(tournamentId, participantId);
  }
}
