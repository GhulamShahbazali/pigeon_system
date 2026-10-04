import { Body, Controller, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { z } from 'zod';
import { AuthUser, CurrentUser, Roles } from '../../shared/auth/decorators';
import { ZodValidationPipe } from '../../shared/pipes/zod-validation.pipe';
import { ModerationService } from './moderation.service';

const ReportSchema = z.object({
  target_type: z.enum(['post', 'tournament', 'user', 'message', 'record']),
  target_id: z.string().uuid(),
  reason: z.enum(['spam', 'abuse', 'inappropriate', 'other']),
  note: z.string().max(500).optional(),
});
const ActionSchema = z.object({
  action: z.enum(['dismiss', 'hide', 'remove', 'block']),
  note: z.string().max(500).optional(),
});
const SuspendSchema = z.object({ reason: z.string().max(500).optional(), suspended_until: z.string().datetime().optional() });

function num(v: string | undefined, def: number): number {
  const n = Number(v);
  return Number.isFinite(n) && n >= 0 ? Math.floor(n) : def;
}

@Controller()
export class ModerationController {
  constructor(private readonly svc: ModerationService) {}

  // ---- user-facing ----
  @Post('reports')
  @HttpCode(201)
  async report(@CurrentUser() u: AuthUser, @Body(new ZodValidationPipe(ReportSchema)) b: any) {
    await this.svc.createReport(u.id, b.target_type, b.target_id, b.reason, b.note);
    return { data: { ok: true } };
  }

  // ---- admin (superadmin only) ----
  @Roles('superadmin')
  @Get('admin/reports')
  async reports(@Query('status') status?: string, @Query('offset') o?: string, @Query('limit') l?: string) {
    const { data, total } = await this.svc.listReports(status, num(o, 0), num(l, 50));
    return { data, meta: { offset: num(o, 0), limit: num(l, 50), total } };
  }

  @Roles('superadmin')
  @Post('admin/reports/:id/action')
  @HttpCode(204)
  action(@CurrentUser() u: AuthUser, @Param('id') id: string, @Body(new ZodValidationPipe(ActionSchema)) b: any) {
    return this.svc.actionReport(u.id, id, b.action, b.note);
  }

  @Roles('superadmin')
  @Get('admin/users')
  async users(@Query('q') q?: string, @Query('offset') o?: string, @Query('limit') l?: string) {
    const { data, total } = await this.svc.listUsers(q, num(o, 0), num(l, 50));
    return { data, meta: { offset: num(o, 0), limit: num(l, 50), total } };
  }

  @Roles('superadmin')
  @Post('admin/users/:id/suspend')
  @HttpCode(204)
  suspend(@CurrentUser() u: AuthUser, @Param('id') id: string, @Body(new ZodValidationPipe(SuspendSchema)) b: any) {
    return this.svc.suspend(u.id, id, b.reason, b.suspended_until ? new Date(b.suspended_until) : undefined);
  }

  @Roles('superadmin')
  @Post('admin/users/:id/unsuspend')
  @HttpCode(204)
  unsuspend(@CurrentUser() u: AuthUser, @Param('id') id: string) {
    return this.svc.unsuspend(u.id, id);
  }
}
