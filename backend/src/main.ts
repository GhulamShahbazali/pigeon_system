import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { Logger } from '@nestjs/common';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrapApi(): Promise<void> {
  const logger = new Logger('bootstrap');
  const app = await NestFactory.create(AppModule, { bufferLogs: false });
  app.use(helmet());
  app.enableCors({
    origin: (process.env.CORS_ORIGINS ?? '').split(',').map((s) => s.trim()).filter(Boolean),
    credentials: true,
  });
  app.setGlobalPrefix('v1');
  // Validation is per-route via ZodValidationPipe (no global class-validator pipe).
  app.enableShutdownHooks();

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
  logger.log(`[api] PigeonFly API listening on :${port}`);
}

async function bootstrapWorker(): Promise<void> {
  const logger = new Logger('bootstrap');
  // Reuse the full module graph (no HTTP server). WorkerRunner spins up the BullMQ
  // Workers because PROCESS_ROLE is worker|scheduler; in the API process it stays idle.
  const app = await NestFactory.createApplicationContext(AppModule, { bufferLogs: false });
  app.enableShutdownHooks();
  logger.log(`[worker] PigeonFly worker started (role=${process.env.PROCESS_ROLE})`);
}

const role = process.env.PROCESS_ROLE ?? 'api';
(role === 'worker' || role === 'scheduler' ? bootstrapWorker() : bootstrapApi()).catch((e) => {
  // eslint-disable-next-line no-console
  console.error('Fatal boot error:', e);
  process.exit(1);
});
