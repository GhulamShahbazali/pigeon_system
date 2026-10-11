import { Module } from '@nestjs/common';
import { TournamentsController } from './presentation/tournaments.controller';
import {
  CreateTournamentUseCase,
  AddParticipantUseCase,
  RecordFlightUseCase,
  TournamentSocialUseCase,
} from './domain/write.use-cases';
import { TournamentQueries } from './domain/read.use-cases';
import { PrismaTournamentRepository } from './data/prisma-tournament.repository';
import { TOURNAMENT_REPOSITORY } from './domain/tournament.repository';

@Module({
  controllers: [TournamentsController],
  providers: [
    CreateTournamentUseCase,
    AddParticipantUseCase,
    RecordFlightUseCase,
    TournamentSocialUseCase,
    TournamentQueries,
    { provide: TOURNAMENT_REPOSITORY, useClass: PrismaTournamentRepository },
  ],
  exports: [CreateTournamentUseCase, AddParticipantUseCase, RecordFlightUseCase],
})
export class TournamentsModule {}
