import {
  createParamDecorator,
  ExecutionContext,
  SetMetadata,
} from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';
/** Skip the AuthGuard for this route. */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);

export const SCOPE_KEY = 'requiredScope';
/** Require a specific JWT scope (default 'session'). */
export const RequiresScope = (scope: 'session' | 'onboarding') =>
  SetMetadata(SCOPE_KEY, scope);

export const ROLES_KEY = 'roles';
export const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles);

export interface AuthUser {
  id: string;
  role: string;
  isSuspended: boolean;
  deviceId?: string;
  jti: string;
  scope: string;
}

/** Inject the authenticated user. */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AuthUser => {
    const req = ctx.switchToHttp().getRequest();
    return req.user as AuthUser;
  },
);
