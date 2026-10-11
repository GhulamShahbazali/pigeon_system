import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { DomainError } from '../errors/domain-error';
import { translatePrismaError } from '../errors/prisma-error.translator';

@Catch()
export class DomainExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('Exception');

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();
    // pino (nestjs-pino) sets req.id as the correlation id; genReqId also mirrors it to req.requestId.
    const requestId = (req as any).id ?? (req as any).requestId ?? 'unknown';

    const domain =
      exception instanceof DomainError ? exception : translatePrismaError(exception);

    if (domain) {
      if (domain.httpStatus === 429 && (domain as any).retryAfterSeconds) {
        res.setHeader('Retry-After', String((domain as any).retryAfterSeconds));
      }
      res.status(domain.httpStatus).json({
        error: {
          code: domain.code,
          message: domain.message,
          details: domain.details,
          request_id: requestId,
        },
      });
      return;
    }

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const body = exception.getResponse() as any;
      res.status(status).json({
        error: {
          code: body?.code ?? 'error',
          message: body?.message ?? exception.message,
          request_id: requestId,
        },
      });
      return;
    }

    // Unexpected — hide internals, log for Sentry.
    this.logger.error(
      `Unhandled error [${requestId}] ${req.method} ${req.url}: ${(exception as Error)?.message}`,
      (exception as Error)?.stack,
    );
    res.status(500).json({
      error: { code: 'internal_error', message: 'Something went wrong', request_id: requestId },
    });
  }
}
