import { Body, Controller, Delete, Get, HttpCode, Post, Req } from '@nestjs/common';
import { Request } from 'express';
import { Public } from '../../../shared/auth/decorators';
import { CurrentUser, AuthUser } from '../../../shared/auth/decorators';
import { ZodValidationPipe } from '../../../shared/pipes/zod-validation.pipe';
import { PrismaAuthRepository } from '../data/prisma-auth.repository';
import { SignInUseCase } from '../domain/sign-in.use-case';
import { CompleteSignupUseCase } from '../domain/complete-signup.use-case';
import { RedisService } from '../../../shared/redis/redis.service';
import { toUserResponse } from './user.response';
import { NotFoundError } from '../../../shared/errors/common-errors';
import {
  CompleteSignupSchema,
  SessionSchema,
  type CompleteSignupDto,
  type SessionDto,
} from './auth.schemas';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly signIn: SignInUseCase,
    private readonly completeSignup: CompleteSignupUseCase,
    private readonly repo: PrismaAuthRepository,
    private readonly redis: RedisService,
  ) {}

  @Public()
  @Post('session')
  async session(@Body(new ZodValidationPipe(SessionSchema)) body: SessionDto) {
    const r = await this.signIn.execute({
      idToken: body.id_token,
      device: {
        deviceId: body.device_id,
        deviceType: body.device_type,
        fcmToken: body.fcm_token,
        appVersion: body.app_version,
      },
    });
    if (!r.ok) throw r.error;
    if (r.value.status === 'new') {
      return { data: { onboarding_required: true, temp_token: r.value.tempToken, expires_at: r.value.expiresAt.toISOString() } };
    }
    return {
      data: {
        user: toUserResponse(r.value.user),
        session_token: r.value.sessionToken,
        expires_at: r.value.expiresAt.toISOString(),
      },
    };
  }

  @Public()
  @Post('complete-signup')
  async complete(
    @Req() req: Request,
    @Body(new ZodValidationPipe(CompleteSignupSchema)) body: CompleteSignupDto,
  ) {
    const header = req.headers.authorization;
    const onboardingToken = header?.startsWith('Bearer ') ? header.slice(7) : '';
    const r = await this.completeSignup.execute({
      onboardingToken,
      displayName: body.display_name,
      username: body.username,
      languageCode: body.language_code,
      photoUrl: body.profile_photo_url,
      timezone: body.timezone,
      device: {
        deviceId: body.device_id,
        deviceType: body.device_type,
        fcmToken: body.fcm_token,
        appVersion: body.app_version,
      },
    });
    if (!r.ok) throw r.error;
    return {
      data: {
        user: toUserResponse(r.value.user),
        session_token: r.value.sessionToken,
        expires_at: r.value.expiresAt.toISOString(),
      },
    };
  }

  @Get('me')
  async me(@CurrentUser() user: AuthUser) {
    const u = await this.repo.findById(user.id);
    if (!u) throw new NotFoundError('user');
    return toUserResponse(u);
  }

  @Delete('session/current')
  @HttpCode(204)
  async logout(@CurrentUser() user: AuthUser) {
    if (user.deviceId) await this.repo.deleteDevice(user.id, user.deviceId);
    await this.redis.client.del(`session:${user.jti}`);
    await this.redis.client.srem(`user_sessions:${user.id}`, user.jti);
  }

  @Delete('session/all')
  @HttpCode(204)
  async logoutAll(@CurrentUser() user: AuthUser) {
    await this.repo.deleteAllDevices(user.id);
    const jtis = await this.redis.client.smembers(`user_sessions:${user.id}`);
    if (jtis.length) await this.redis.client.del(...jtis.map((j) => `session:${j}`));
    await this.redis.client.del(`user_sessions:${user.id}`);
  }
}
