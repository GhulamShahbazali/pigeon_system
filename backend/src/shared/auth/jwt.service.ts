import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
import { randomUUID } from 'crypto';

export type JwtScope = 'session' | 'onboarding';

export interface JwtClaims {
  sub: string; // user id
  sid?: string; // device id (session scope)
  role: string;
  scope: JwtScope;
  jti: string;
}

const TTL: Record<JwtScope, string> = { session: '7d', onboarding: '30m' };

@Injectable()
export class JwtService {
  private readonly secret: string;
  constructor(config: ConfigService) {
    this.secret = config.getOrThrow<string>('JWT_SECRET');
  }

  sign(payload: Omit<JwtClaims, 'jti'>): { token: string; jti: string; expiresAt: Date } {
    const jti = randomUUID();
    const expiresIn = TTL[payload.scope];
    const token = jwt.sign({ ...payload, jti }, this.secret, {
      expiresIn,
    } as jwt.SignOptions);
    const decoded = jwt.decode(token) as { exp: number };
    return { token, jti, expiresAt: new Date(decoded.exp * 1000) };
  }

  verify(token: string): JwtClaims {
    return jwt.verify(token, this.secret) as JwtClaims;
  }

  /** Onboarding token carries the verified Firebase identity (no user row yet). */
  signOnboarding(identity: {
    provider: string;
    providerId: string;
    email?: string;
  }): { token: string; expiresAt: Date } {
    const token = jwt.sign({ ...identity, scope: 'onboarding' as const }, this.secret, {
      expiresIn: '30m',
    } as jwt.SignOptions);
    const decoded = jwt.decode(token) as { exp: number };
    return { token, expiresAt: new Date(decoded.exp * 1000) };
  }

  verifyOnboarding(token: string): { provider: string; providerId: string; email?: string } {
    const claims = jwt.verify(token, this.secret) as {
      scope: string;
      provider: string;
      providerId: string;
      email?: string;
    };
    if (claims.scope !== 'onboarding') throw new Error('not an onboarding token');
    return { provider: claims.provider, providerId: claims.providerId, email: claims.email };
  }
}
