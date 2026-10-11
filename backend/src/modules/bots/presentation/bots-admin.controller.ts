import { Body, Controller, Get, HttpCode, Post, Patch, Query } from '@nestjs/common';
import { z } from 'zod';
import { Roles } from '../../../shared/auth/decorators';
import { ZodValidationPipe } from '../../../shared/pipes/zod-validation.pipe';
import { BotsAdminService } from '../services/bots-admin.service';

const ConfigSchema = z
  .object({
    enabled: z.boolean(),
    tickIntervalSec: z.coerce.number().int().min(1).max(60),
    gapWindowSec: z.coerce.number().int().min(30).max(3600),
    postsPerMin: z.coerce.number().int().min(0).max(120),
    botPostCooldownMin: z.coerce.number().int().min(0).max(1440),
    likesPerMin: z.coerce.number().int().min(0).max(600),
    newestBiasPct: z.coerce.number().int().min(0).max(100),
    maxBotLikesPerPost: z.coerce.number().int().min(0).max(500),
    viewsPerMin: z.coerce.number().int().min(0).max(2000),
    viewBatchSize: z.coerce.number().int().min(1).max(50),
    followsPerMin: z.coerce.number().int().min(0).max(60),
    tournamentsPerDay: z.coerce.number().int().min(0).max(100),
    recordsPerDay: z.coerce.number().int().min(0).max(200),
  })
  .partial();

const SourceSchema = z.object({ source: z.enum(['schedule', 'manual']) });
const SelectionSchema = z.object({ ids: z.array(z.string().uuid()).max(500) });

function num(v: string | undefined, def: number): number {
  const n = Number(v);
  return Number.isFinite(n) && n >= 0 ? Math.floor(n) : def;
}

@Roles('superadmin')
@Controller('admin/bots')
export class BotsAdminController {
  constructor(private readonly svc: BotsAdminService) {}

  @Get('overview')
  overview() {
    return this.svc.overview();
  }

  @Get('config')
  async config() {
    return { data: await this.svc.getConfig() };
  }

  @Patch('config')
  async updateConfig(@Body(new ZodValidationPipe(ConfigSchema)) b: any) {
    return { data: await this.svc.updateConfig(b) };
  }

  @Get('roster')
  async roster(@Query('offset') o?: string, @Query('limit') l?: string) {
    const { data, total } = await this.svc.roster(num(o, 0), num(l, 50));
    return { data, meta: { offset: num(o, 0), limit: num(l, 50), total } };
  }

  @Get('active-source')
  async source() {
    return { data: { source: await this.svc.getActiveSource() } };
  }

  @Post('active-source')
  @HttpCode(204)
  async setSource(@Body(new ZodValidationPipe(SourceSchema)) b: any) {
    await this.svc.setActiveSource(b.source);
  }

  @Get('manual-selection')
  async selection() {
    return { data: await this.svc.getManualSelection() };
  }

  @Post('manual-selection')
  @HttpCode(204)
  async setSelection(@Body(new ZodValidationPipe(SelectionSchema)) b: any) {
    await this.svc.setManualSelection(b.ids);
  }

  @Get('content')
  contentPools() {
    return { data: this.svc.contentPools() };
  }
}
