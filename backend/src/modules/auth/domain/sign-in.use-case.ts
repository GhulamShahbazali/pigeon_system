import { Inject, Injectable } from '@nestjs/common';
import { AUTH_REPOSITORY, DeviceInput, IAuthRepository, UserRecord } from './auth.repository';
import { FirebaseVerifierAdapter } from '../data/adapters/firebase-verifier.adapter';
import { JwtService } from '../../../shared/auth/jwt.service';
import { RedisService } from '../../../shared/redis/redis.service';
import { Ok, Result } from '../../../shared/result/result';

export interface SignInCommand {
  idToken: string;
  device: DeviceInput;
}

export type SignInResult =
  | { status: 'new'; tempToken: string; expiresAt: Date }
  | { status: 'returning'; user: UserRecord; sessionToken: string; expiresAt: Date };

@Injectable()
export class SignInUseCase {
  constructor(
    @Inject(AUTH_REPOSITORY) private readonly repo: IAuthRepository,
    private readonly firebase: FirebaseVerifierAdapter,
    private readonly jwt: JwtService,
    private readonly redis: RedisService,
  ) {}

  async execute(cmd: SignInCommand): Promise<Result<SignInResult>> {
    const identity = await this.firebase.verify(cmd.idToken);
    const user = await this.repo.findByProvider(identity.provider, identity.providerId);

    if (!user) {
      const { token, expiresAt } = this.jwt.signOnboarding(identity);
      return Ok({ status: 'new', tempToken: token, expiresAt });
    }

    const deviceRowId = await this.repo.upsertDevice(user.id, cmd.device);
    await this.repo.touchActive(user.id);
    const { token, jti, expiresAt } = this.jwt.sign({
      sub: user.id,
      sid: deviceRowId,
      role: user.role,
      scope: 'session',
    });
    await this.cacheSession(user, jti);
    return Ok({ status: 'returning', user, sessionToken: token, expiresAt });
  }

  private async cacheSession(user: UserRecord, jti: string): Promise<void> {
    await this.redis.client.hset(`session:${jti}`, {
      id: user.id,
      role: user.role,
      is_suspended: user.isSuspended ? '1' : '0',
    });
    await this.redis.client.expire(`session:${jti}`, 3600);
    await this.redis.client.sadd(`user_sessions:${user.id}`, jti);
  }
}
