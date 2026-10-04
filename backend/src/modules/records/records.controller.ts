import { Body, Controller, Delete, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../shared/auth/decorators';
import { ZodValidationPipe } from '../../shared/pipes/zod-validation.pipe';
import { RecordUseCases } from './record.use-cases';
import {
  AddPigeonSchema,
  CreateRecordSchema,
  toLivePreview,
  toRecord,
  toRecordDetail,
  type AddPigeonDto,
  type CreateRecordDto,
} from './record.presentation';

function lim(v?: string): number {
  const n = Number(v);
  return Number.isFinite(n) && n > 0 && n <= 50 ? Math.floor(n) : 20;
}

@Controller()
export class RecordsController {
  constructor(private readonly uc: RecordUseCases) {}

  @Get('me/records')
  async mine(@CurrentUser() u: AuthUser, @Query('limit') l?: string) {
    return { data: (await this.uc.listMine(u.id, lim(l))).map(toRecord) };
  }

  @Get('records/live')
  async live(@CurrentUser() u: AuthUser, @Query('limit') l?: string) {
    return { data: (await this.uc.liveNow(u.id, lim(l))).map(toLivePreview) };
  }

  @Get('records/:id')
  async detail(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    const r = await this.uc.detail(id, u.id);
    if (!r.ok) throw r.error;
    return toRecordDetail(r.value);
  }

  @Post('me/records')
  async create(
    @CurrentUser() u: AuthUser,
    @Body(new ZodValidationPipe(CreateRecordSchema)) b: CreateRecordDto,
  ) {
    const r = await this.uc.create(u.id, {
      recordDate: b.record_date,
      flyTime: b.fly_time,
      totalPigeons: b.total_pigeons,
      privacy: b.privacy,
    });
    return toRecord(r);
  }

  @Post('records/:id/go-live')
  async goLive(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    const r = await this.uc.goLive(u.id, id);
    if (!r.ok) throw r.error;
    return toRecord(r.value);
  }

  @Post('records/:id/end')
  async end(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    const r = await this.uc.end(u.id, id);
    if (!r.ok) throw r.error;
    return r.value;
  }

  @Post('records/:id/pigeons')
  async addPigeon(
    @Param('id') id: string,
    @CurrentUser() u: AuthUser,
    @Body(new ZodValidationPipe(AddPigeonSchema)) b: AddPigeonDto,
  ) {
    const r = await this.uc.addPigeon(u.id, id, b.pigeon_name, new Date(b.landing_time));
    if (!r.ok) throw r.error;
    return {
      id: r.value.id,
      pigeon_name: r.value.pigeonName,
      landing_time: r.value.landingTime.toISOString(),
      duration_seconds: r.value.durationSeconds,
    };
  }

  @Post('records/:id/like')
  @HttpCode(204)
  like(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    return this.uc.like(id, u.id);
  }

  @Delete('records/:id/like')
  @HttpCode(204)
  unlike(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    return this.uc.unlike(id, u.id);
  }
}
