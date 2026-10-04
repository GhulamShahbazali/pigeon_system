import { Inject, Injectable } from '@nestjs/common';
import { AUTH_REPOSITORY, DeviceInput, IAuthRepository, UserRecord } from './auth.repository';
import { JwtService } from '../../../shared/auth/jwt.service';
import { RedisService } from '../../../shared/redis/redis.service';
import { Err, Ok, Result } from '../../../shared/result/result';
import { ConflictError, UnauthenticatedError } from '../../../shared/errors/common-errors';

export interface CompleteSignupCommand {
  onboardingToken: string;
  displayName: string;
  username: string;
  languageCode: string;
  photoUrl?: string;
  timezone?: string;
  device: DeviceInput;
}

export interface CompleteSignupResult {
  user: UserRecord;
  sessionToken: string;
  expiresAt: Date;
}

@Injectable()
export class CompleteSignupUseCase {
  constructor(
    @Inject(AUTH_REPOSITORY) private readonly repo: IAuthRepository,
    private readonly jwt: JwtService,
    private readonly redis: RedisService,
  ) {}

  async execute(cmd: CompleteSignupCommand): Promise<Result<CompleteSignupResult>> {
    let identity;
    try {
      identity = this.jwt.verifyOnboarding(cmd.onboardingToken);
    } catch {
      return Err(new UnauthenticatedError('Invalid or expired onboarding token'));
    }

    if (await this.repo.usernameTaken(cmd.username.toLowerCase())) {
      return Err(new ConflictError('Username already taken', 'username'));
    }

    const user = await this.repo.createUserWithDefaults(
      {
        provider: identity.provider as 'google' | 'apple',
        providerId: identity.providerId,
        email: identity.email,
        displayName: cmd.displayName,
        username: cmd.username,
        languageCode: cmd.languageCode,
        photoUrl: cmd.photoUrl,
        timezone: cmd.timezone,
      },
      cmd.device,
    );

    // the device row id for sid
    const deviceRowId = await this.repo.upsertDevice(user.id, cmd.device);
    const { token, jti, expiresAt } = this.jwt.sign({
      sub: user.id,
      sid: deviceRowId,
      role: user.role,
      scope: 'session',
    });
    await this.redis.client.hset(`session:${jti}`, {
      id: user.id,
      role: user.role,
      is_suspended: '0',
    });
    await this.redis.client.expire(`session:${jti}`, 3600);
    await this.redis.client.sadd(`user_sessions:${user.id}`, jti);

    return Ok({ user, sessionToken: token, expiresAt });
  }
}
