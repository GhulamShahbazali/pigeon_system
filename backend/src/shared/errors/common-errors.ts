import { DomainError } from './domain-error';

export class NotFoundError extends DomainError {
  readonly code = 'not_found';
  readonly httpStatus = 404;
  constructor(entity = 'resource') {
    super(`${entity} not found`);
  }
}

export class ForbiddenError extends DomainError {
  readonly code = 'forbidden';
  readonly httpStatus = 403;
  constructor(message = 'Not allowed') {
    super(message);
  }
}

export class BlockedError extends DomainError {
  readonly code = 'blocked';
  readonly httpStatus = 403;
  constructor() {
    super('Blocked');
  }
}

export class ConflictError extends DomainError {
  readonly code = 'conflict';
  readonly httpStatus = 409;
  constructor(message = 'Conflict', field?: string) {
    super(message);
    if (field) this.details = { fields: { [field]: message } };
  }
}

export class UnprocessableError extends DomainError {
  readonly code = 'unprocessable';
  readonly httpStatus = 422;
  constructor(message: string, fields?: Record<string, string>) {
    super(message);
    if (fields) this.details = { fields };
  }
}

export class UnauthenticatedError extends DomainError {
  readonly code = 'unauthenticated';
  readonly httpStatus = 401;
  constructor(message = 'Not authenticated') {
    super(message);
  }
}

export class RateLimitError extends DomainError {
  readonly code = 'rate_limited';
  readonly httpStatus = 429;
  constructor(public readonly retryAfterSeconds: number) {
    super('Too many requests');
    this.details = { retry_after: retryAfterSeconds };
  }
}
