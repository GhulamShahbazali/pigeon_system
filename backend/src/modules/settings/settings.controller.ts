import { Body, Controller, Delete, Get, HttpCode, Patch } from '@nestjs/common';
import { z } from 'zod';
import { AuthUser, CurrentUser } from '../../shared/auth/decorators';
import { ZodValidationPipe } from '../../shared/pipes/zod-validation.pipe';
import { SettingsService } from './settings.service';

const bool = z.boolean().optional();
const NotifSchema = z.object({
  pushEnabled: bool,
  notifyNewFollower: bool,
  notifyLikes: bool,
  notifyFollowedTournament: bool,
  notifyLiveRecord: bool,
  notifyMessages: bool,
});
const PrivacySchema = z.object({ privateAccount: bool, showOnlineStatus: bool });
const AppSchema = z.object({ language_code: z.enum(['ur', 'hi', 'ar', 'en']) });

@Controller('me')
export class SettingsController {
  constructor(private readonly svc: SettingsService) {}

  @Get('settings')
  get(@CurrentUser() u: AuthUser) {
    return this.svc.getAll(u.id);
  }

  @Patch('settings/notifications')
  notifications(@CurrentUser() u: AuthUser, @Body(new ZodValidationPipe(NotifSchema)) b: any) {
    return this.svc.patchNotifications(u.id, b);
  }

  @Patch('settings/privacy')
  privacy(@CurrentUser() u: AuthUser, @Body(new ZodValidationPipe(PrivacySchema)) b: any) {
    return this.svc.patchPrivacy(u.id, b);
  }

  @Patch('settings/app')
  app(@CurrentUser() u: AuthUser, @Body(new ZodValidationPipe(AppSchema)) b: any) {
    return this.svc.patchApp(u.id, b.language_code);
  }

  @Delete()
  @HttpCode(204)
  deleteAccount(@CurrentUser() u: AuthUser) {
    return this.svc.softDeleteAccount(u.id);
  }
}
