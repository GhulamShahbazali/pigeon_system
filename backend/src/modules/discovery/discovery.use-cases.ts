import { Injectable } from '@nestjs/common';
import { PrismaDiscoveryRepository } from './data/prisma-discovery.repository';
import { CacheService } from '../../shared/cache/cache.service';
import {
  conversationResult,
  discoveryUserCard,
  liveRecordResult,
  tournamentResult,
} from './discovery.presentation';

@Injectable()
export class DiscoveryUseCases {
  constructor(
    private readonly repo: PrismaDiscoveryRepository,
    private readonly cache: CacheService,
  ) {}

  /** Suggested users are never already-followed, so is_following is always false.
   *  Approximate list → cache-aside 60s per viewer (no invalidation needed). */
  async suggestions(viewerId: string, limit: number) {
    return this.cache.getOrSet(`disc:sugg:${viewerId}:${limit}`, 60, async () => {
      const users = await this.repo.suggestedUsers(viewerId, limit);
      return users.map((u) => discoveryUserCard(u, false));
    });
  }

  async searchUsers(viewerId: string, q: string, limit: number) {
    const users = await this.repo.searchUsers(viewerId, q, limit);
    const following = await this.repo.followingAmong(viewerId, users.map((u) => u.id));
    return users.map((u) => discoveryUserCard(u, following.has(u.id)));
  }

  async searchTournaments(q: string, limit: number) {
    return (await this.repo.searchTournaments(q, limit)).map(tournamentResult);
  }

  async searchRecords(viewerId: string, q: string, limit: number) {
    return (await this.repo.searchLiveRecords(viewerId, q, limit)).map(liveRecordResult);
  }

  async searchConversations(viewerId: string, q: string, limit: number) {
    const pairs = await this.repo.searchConversations(viewerId, q, limit);
    return pairs.map(([c, other]) => conversationResult(c, other));
  }
}
