import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentUser, AuthUser } from '../../../shared/auth/decorators';
import { ZodValidationPipe } from '../../../shared/pipes/zod-validation.pipe';
import {
  CreateTournamentUseCase,
  AddParticipantUseCase,
  RecordFlightUseCase,
  UpdateFlightUseCase,
  DeleteFlightUseCase,
  TournamentSocialUseCase,
} from '../domain/write.use-cases';
import { TournamentQueries } from '../domain/read.use-cases';
import {
  AddParticipantSchema,
  CreateTournamentSchema,
  ListQuerySchema,
  RecordFlightSchema,
  UpdateFlightSchema,
  type AddParticipantDto,
  type CreateTournamentDto,
  type ListQueryDto,
  type RecordFlightDto,
  type UpdateFlightDto,
} from './tournament.schemas';
import {
  toCard,
  toDetail,
  toFlight,
  toParticipantDetail,
  toParticipantRow,
} from './tournament.responses';

@Controller('tournaments')
export class TournamentsController {
  constructor(
    private readonly create: CreateTournamentUseCase,
    private readonly addParticipant: AddParticipantUseCase,
    private readonly recordFlight: RecordFlightUseCase,
    private readonly updateFlightUc: UpdateFlightUseCase,
    private readonly deleteFlightUc: DeleteFlightUseCase,
    private readonly social: TournamentSocialUseCase,
    private readonly queries: TournamentQueries,
  ) {}

  // ---- browse ----
  @Get()
  async list(
    @CurrentUser() user: AuthUser,
    @Query(new ZodValidationPipe(ListQuerySchema)) q: ListQueryDto,
  ) {
    const rows = await this.queries.list(q.tab, user.id, q.cursor ?? null, q.limit);
    return { data: rows.map(toCard) };
  }

  @Get('by-user/:userId')
  async byUser(
    @Param('userId') userId: string,
    @CurrentUser() user: AuthUser,
    @Query(new ZodValidationPipe(ListQuerySchema)) q: ListQueryDto,
  ) {
    const rows = await this.queries.byOrganizer(userId, user.id, q.limit);
    return { data: rows.map(toCard) };
  }

  @Get(':id')
  async detail(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return toDetail(await this.queries.detail(id, user.id));
  }

  @Get(':id/participants')
  async standings(@Param('id') id: string) {
    const rows = await this.queries.standings(id);
    return { data: rows.map(toParticipantRow) };
  }

  @Get(':id/participants/:pid')
  async participant(@Param('id') id: string, @Param('pid') pid: string) {
    return toParticipantDetail(await this.queries.participantDays(id, pid));
  }

  // ---- owner writes ----
  @Post()
  async createTournament(
    @CurrentUser() user: AuthUser,
    @Body(new ZodValidationPipe(CreateTournamentSchema)) b: CreateTournamentDto,
  ) {
    const r = await this.create.execute({
      organizerId: user.id,
      title: b.title,
      rules: b.rules,
      description: b.description,
      coverUrl: b.cover_url,
      numDays: b.num_days,
      scheduleType: b.schedule_type,
      pigeonCount: b.pigeon_count,
      flyTime: b.fly_time,
      endTime: b.end_time,
      startDate: b.start_date,
      organizerContact: b.organizer_contact,
    });
    if (!r.ok) throw r.error;
    return r.value;
  }

  @Post(':id/participants')
  async addP(
    @Param('id') id: string,
    @CurrentUser() user: AuthUser,
    @Body(new ZodValidationPipe(AddParticipantSchema)) b: AddParticipantDto,
  ) {
    const r = await this.addParticipant.execute(user.id, {
      tournamentId: id,
      name: b.name,
      photoUrl: b.photo_url,
      contactNo: b.contact_no,
      phone: b.phone,
      address: b.address,
    });
    if (!r.ok) throw r.error;
    return toParticipantRow(r.value);
  }

  @Post(':id/participants/:pid/flights')
  async flight(
    @Param('id') id: string,
    @Param('pid') pid: string,
    @CurrentUser() user: AuthUser,
    @Body(new ZodValidationPipe(RecordFlightSchema)) b: RecordFlightDto,
  ) {
    const r = await this.recordFlight.execute(user.id, {
      tournamentId: id,
      participantId: pid,
      dayId: b.day_id,
      pigeonName: b.pigeon_name,
      landingTime: new Date(b.landing_time),
    });
    if (!r.ok) throw r.error;
    return toFlight(r.value);
  }

  @Patch(':id/participants/:pid/flights/:fid')
  async editFlight(
    @Param('id') id: string,
    @Param('pid') pid: string,
    @Param('fid') fid: string,
    @CurrentUser() user: AuthUser,
    @Body(new ZodValidationPipe(UpdateFlightSchema)) b: UpdateFlightDto,
  ) {
    const r = await this.updateFlightUc.execute(user.id, {
      tournamentId: id,
      participantId: pid,
      flightId: fid,
      pigeonName: b.pigeon_name,
      landingTime: b.landing_time ? new Date(b.landing_time) : undefined,
    });
    if (!r.ok) throw r.error;
    return toFlight(r.value);
  }

  @Delete(':id/participants/:pid/flights/:fid')
  @HttpCode(204)
  async removeFlight(
    @Param('id') id: string,
    @Param('pid') pid: string,
    @Param('fid') fid: string,
    @CurrentUser() user: AuthUser,
  ) {
    const r = await this.deleteFlightUc.execute(user.id, id, pid, fid);
    if (!r.ok) throw r.error;
  }

  // ---- social ----
  @Post(':id/follow')
  @HttpCode(204)
  follow(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    return this.social.follow(id, u.id);
  }
  @Delete(':id/follow')
  @HttpCode(204)
  unfollow(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    return this.social.unfollow(id, u.id);
  }
  @Post(':id/like')
  @HttpCode(204)
  like(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    return this.social.like(id, u.id);
  }
  @Delete(':id/like')
  @HttpCode(204)
  unlike(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    return this.social.unlike(id, u.id);
  }
}
