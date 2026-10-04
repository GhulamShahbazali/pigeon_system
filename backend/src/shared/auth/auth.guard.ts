import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { JwtService } from './jwt.service';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { IS_PUBLIC_KEY, SCOPE_KEY, ROLES_KEY, AuthUser } from './decorators';
import { ForbiddenError, UnauthenticatedError } from '../errors/common-errors';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);
    if (isPublic) return true;

    const req = ctx.switchToHttp().getRequest<Request>();
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) throw new UnauthenticatedError('Missing token');

    let claims;
    try {
      claims = this.jwt.verify(header.slice(7));
    } catch {
      throw new UnauthenticatedError('Invalid or expired token');
    }

    const requiredScope =
      this.reflector.getAllAndOverride<string>(SCOPE_KEY, [ctx.getHandler(), ctx.getClass()]) ??
      'session';
    if (claims.scope !== requiredScope) throw new UnauthenticatedError('Wrong token scope');

    const user = await this.loadUser(claims.sub, claims.jti);
    if (!user) throw new UnauthenticatedError('Account not found');

    const authUser: AuthUser = {
      id: user.id,
      role: user.role,
      isSuspended: user.isSuspended,
      deviceId: claims.sid,
      jti: claims.jti,
      scope: claims.scope,
    };
    (req as any).user = authUser;

    const roles = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);
    if (roles?.length && !roles.includes(authUser.role)) {
      throw new ForbiddenError('Insufficient role');
    }
    return true;
  }

  private async loadUser(
    userId: string,
    jti: string,
  ): Promise<{ id: string; role: string; isSuspended: boolean } | null> {
    const cacheKey = `session:${jti}`;
    const cached = await this.redis.client.hgetall(cacheKey);
    if (cached && cached.id) {
      return { id: cached.id, role: cached.role, isSuspended: cached.is_suspended === '1' };
    }
    const user = await this.prisma.user.findFirst({
      where: { id: userId, deletedAt: null },
      select: { id: true, role: true, isSuspended: true },
    });
    if (!user) return null;
    await this.redis.client.hset(cacheKey, {
      id: user.id,
      role: user.role,
      is_suspended: user.isSuspended ? '1' : '0',
    });
    await this.redis.client.expire(cacheKey, 3600);
    return user;
  }
}
