import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { Logger as PinoLogger } from 'nestjs-pino';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrapApi(): Promise<void> {
  // bufferLogs → startup logs are held until the pino logger is attached.
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  app.useLogger(app.get(PinoLogger)); // structured JSON logging + correlation id
  app.use(helmet());
  app.enableCors({
    origin: (process.env.CORS_ORIGINS ?? '').split(',').map((s) => s.trim()).filter(Boolean),
    credentials: true,
  });
  app.setGlobalPrefix('v1');
  // Real client IP behind Nginx/LB (so the throttler keys on the user, not the proxy).
  app.getHttpAdapter().getInstance().set('trust proxy', 1);
  // Validation is per-route via ZodValidationPipe (no global class-validator pipe).
  app.enableShutdownHooks();

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
  app.get(PinoLogger).log(`[api] PigeonFly API listening on :${port}`);
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
