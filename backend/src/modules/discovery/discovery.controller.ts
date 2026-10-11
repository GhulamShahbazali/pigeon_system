import { Controller, Get, Query } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../shared/auth/decorators';
import { ZodValidationPipe } from '../../shared/pipes/zod-validation.pipe';
import { DiscoveryUseCases } from './discovery.use-cases';
import { SearchQuerySchema, type SearchQueryDto } from './discovery.presentation';

function lim(v?: string): number {
  const n = Number(v);
  return Number.isFinite(n) && n > 0 && n <= 50 ? Math.floor(n) : 20;
}

@Controller()
export class DiscoveryController {
  constructor(private readonly uc: DiscoveryUseCases) {}

  /** TikTok-style "Find friends": suggested people to follow / message. */
  @Get('discovery/suggestions')
  async suggestions(@CurrentUser() u: AuthUser, @Query('limit') l?: string) {
    return { data: await this.uc.suggestions(u.id, lim(l)) };
  }

  /** User search — powers Find Friends and the chat screen's "new message" search. */
  @Get('search/users')
  async users(@CurrentUser() u: AuthUser, @Query(new ZodValidationPipe(SearchQuerySchema)) q: SearchQueryDto) {
    return { data: await this.uc.searchUsers(u.id, q.q, q.limit) };
  }

  /** Tournaments screen search. */
  @Get('search/tournaments')
  async tournaments(@Query(new ZodValidationPipe(SearchQuerySchema)) q: SearchQueryDto) {
    return { data: await this.uc.searchTournaments(q.q, q.limit) };
  }

  /** Records screen search (live records by owner). */
  @Get('search/records')
  async records(@CurrentUser() u: AuthUser, @Query(new ZodValidationPipe(SearchQuerySchema)) q: SearchQueryDto) {
    return { data: await this.uc.searchRecords(u.id, q.q, q.limit) };
  }

  /** Chat screen search over the viewer's existing conversations. */
  @Get('search/conversations')
  async conversations(@CurrentUser() u: AuthUser, @Query(new ZodValidationPipe(SearchQuerySchema)) q: SearchQueryDto) {
    return { data: await this.uc.searchConversations(u.id, q.q, q.limit) };
  }
}
