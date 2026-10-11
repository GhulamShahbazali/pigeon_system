import { Module } from '@nestjs/common';
import { LoggerModule } from 'nestjs-pino';
import { randomUUID } from 'crypto';
import type { IncomingMessage, ServerResponse } from 'http';

/**
 * Structured JSON logging (pino) with a correlation id per request.
 * Reuses an incoming `X-Request-Id` (set by the edge/LB) or generates one, echoes
 * it back on the response, and stamps it on `req.id` + `req.requestId` so the
 * exception filter puts the SAME id in the error envelope. Auth/cookie headers
 * are redacted. JSON everywhere (ship to Datadog/CloudWatch/Loki as-is).
 */
@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp: {
        level: process.env.LOG_LEVEL ?? 'info',
        genReqId: (req: IncomingMessage, res: ServerResponse) => {
          const incoming = req.headers['x-request-id'];
          const id = (Array.isArray(incoming) ? incoming[0] : incoming) || randomUUID();
          res.setHeader('X-Request-Id', id);
          (req as any).requestId = id;
          return id;
        },
        customProps: (req: any) => ({ requestId: req.id }),
        redact: {
          paths: ['req.headers.authorization', 'req.headers.cookie', 'req.headers["x-api-key"]'],
          remove: true,
        },
        // Health probes are noise — don't log them at info.
        autoLogging: {
          ignore: (req: IncomingMessage) => (req.url ?? '').startsWith('/v1/health'),
        },
        customLogLevel: (_req, res, err) => {
          if (err || res.statusCode >= 500) return 'error';
          if (res.statusCode >= 400) return 'warn';
          return 'info';
        },
      },
    }),
  ],
})
export class LoggingModule {}
