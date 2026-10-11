import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ThrottlerGuard } from '@nestjs/throttler';
import { validateEnv } from './shared/config/env.validation';
import { LoggingModule } from './shared/logging/logging.module';
import { PrismaModule } from './shared/prisma/prisma.module';
import { RedisModule } from './shared/redis/redis.module';
import { CacheModule } from './shared/cache/cache.module';
import { AppThrottlerModule } from './shared/throttler/throttler.module';
import { QueueModule } from './shared/queue/queue.module';
import { SocketModule } from './shared/socket/socket.module';
import { PushModule } from './shared/push/push.module';
import { StorageModule } from './shared/storage/storage.module';
import { SharedAuthModule } from './shared/auth/auth.module';
import { AuthGuard } from './shared/auth/auth.guard';
import { DomainExceptionFilter } from './shared/filters/domain-exception.filter';
import { ResponseEnvelopeInterceptor } from './shared/interceptors/response-envelope.interceptor';
import { HealthModule } from './shared/health/health.module';
import { AuthModule } from './modules/auth/auth.module';
import { TournamentsModule } from './modules/tournaments/tournaments.module';
import { SocialModule } from './modules/social/social.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { RecordsModule } from './modules/records/records.module';
import { PostsModule } from './modules/posts/posts.module';
import { SettingsModule } from './modules/settings/settings.module';
import { MessagesModule } from './modules/messages/messages.module';
import { ModerationModule } from './modules/moderation/moderation.module';
import { DiscoveryModule } from './modules/discovery/discovery.module';
import { BotsModule } from './modules/bots/bots.module';
import { WorkerRunner } from './worker/worker-runner.service';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
    LoggingModule,
    PrismaModule,
    RedisModule,
    CacheModule,
    AppThrottlerModule,
    QueueModule,
    SocketModule,
    PushModule,
    StorageModule,
    SharedAuthModule,
    HealthModule,
    AuthModule,
    TournamentsModule,
    SocialModule,
    NotificationsModule,
    RecordsModule,
    PostsModule,
    SettingsModule,
    MessagesModule,
    ModerationModule,
    DiscoveryModule,
    BotsModule,
  ],
  providers: [
    // Rate limit first (cheap, protects everything behind it), then auth.
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_FILTER, useClass: DomainExceptionFilter },
    { provide: APP_INTERCEPTOR, useClass: ResponseEnvelopeInterceptor },
    WorkerRunner,
  ],
})
export class AppModule {}
