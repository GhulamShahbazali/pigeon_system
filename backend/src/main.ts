import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { Logger as PinoLogger } from 'nestjs-pino';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { UPLOADS_DIR, UPLOADS_ROUTE } from './modules/media/media.constants';

async function bootstrapApi(): Promise<void> {
  // bufferLogs → startup logs are held until the pino logger is attached.
  const app = await NestFactory.create<NestExpressApplication>(AppModule, { bufferLogs: true });
  app.useLogger(app.get(PinoLogger)); // structured JSON logging + correlation id
  // Serve uploaded chat media (voice/image/video) from the project uploads folder.
  // Static assets bypass the /v1 global prefix, so these URLs are /uploads/… .
  app.useStaticAssets(UPLOADS_DIR, { prefix: `${UPLOADS_ROUTE}/` });
  // crossOriginResourcePolicy relaxed so the mobile app can load media cross-origin.
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  const allowedOrigins = (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((s) => s.trim().replace(/\/+$/, ''))
    .filter(Boolean);

  app.enableCors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);
      const isAllowed =
        allowedOrigins.length === 0 ||
        allowedOrigins.includes(origin) ||
        allowedOrigins.includes('*') ||
        /\.onrender\.com$/.test(new URL(origin).hostname) ||
        /^http:\/\/localhost(:\d+)?$/.test(origin);
      if (isAllowed) {
        callback(null, true);
      } else {
        callback(new Error(`Origin ${origin} not allowed by CORS`));
      }
    },
    credentials: true,
    methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  });
  app.setGlobalPrefix('v1');
  // Real client IP behind Nginx/LB (so the throttler keys on the user, not the proxy).
  app.getHttpAdapter().getInstance().set('trust proxy', 1);
  // Validation is per-route via ZodValidationPipe (no global class-validator pipe).
  app.enableShutdownHooks();

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, '0.0.0.0');
  app.get(PinoLogger).log(`[api] PigeonFly API listening on 0.0.0.0:${port}`);
}

async function bootstrapWorker(): Promise<void> {
  // Reuse the full module graph (no HTTP server). WorkerRunner spins up the BullMQ
  // Workers because PROCESS_ROLE is worker|scheduler; in the API process it stays idle.
  const app = await NestFactory.createApplicationContext(AppModule, { bufferLogs: true });
  app.useLogger(app.get(PinoLogger));
  app.enableShutdownHooks();
  app.get(PinoLogger).log(`[worker] PigeonFly worker started (role=${process.env.PROCESS_ROLE})`);
}

const role = process.env.PROCESS_ROLE ?? 'api';
(role === 'worker' || role === 'scheduler' ? bootstrapWorker() : bootstrapApi()).catch((e) => {
  // eslint-disable-next-line no-console
  console.error('Fatal boot error:', e);
  process.exit(1);
});

