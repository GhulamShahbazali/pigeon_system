import { Prisma } from '@prisma/client';
import { DomainError } from './domain-error';
import { ConflictError, NotFoundError } from './common-errors';

class ServiceUnavailableError extends DomainError {
  readonly code = 'service_unavailable';
  readonly httpStatus = 503;
  constructor() {
    super('Service temporarily unavailable');
  }
}

/** Map a Prisma error to a DomainError, or return null if it's not one we translate. */
export function translatePrismaError(e: unknown): DomainError | null {
  if (e instanceof Prisma.PrismaClientKnownRequestError) {
    switch (e.code) {
      case 'P2002': {
        const target = (e.meta?.target as string[] | undefined)?.join(', ') ?? 'value';
        return new ConflictError(`Already exists: ${target}`, target);
      }
      case 'P2025':
        return new NotFoundError();
      case 'P2003':
        return new ConflictError('Related record missing or in use');
      default:
        return null;
    }
  }
  if (
    e instanceof Prisma.PrismaClientInitializationError ||
    e instanceof Prisma.PrismaClientRustPanicError
  ) {
    return new ServiceUnavailableError();
  }
  return null;
}
