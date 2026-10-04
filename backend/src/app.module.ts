import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { validateEnv } from './shared/config/env.validation';
import { PrismaModule } from './shared/prisma/prisma.module';
import { RedisModule } from './shared/redis/redis.module';
import { QueueModule } from './shared/queue/queue.module';
import { SocketModule } from './shared/socket/socket.module';
import { PushModule } from './shared/push/push.module';
import { StorageModule } from './shared/storage/storage.module';
import { SharedAuthModule } from './shared/auth/auth.module';
import { AuthGuard } from './shared/auth/auth.guard';
import { DomainExceptionFilter } from './shared/filters/domain-exception.filter';
import { ResponseEnvelopeInterceptor } from './shared/interceptors/response-envelope.interceptor';
import { RequestIdMiddleware } from './shared/interceptors/request-id.middleware';
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
import { WorkerRunner } from './worker/worker-runner.service';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
    PrismaModule,
    RedisModule,
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
  ],
  providers: [
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_FILTER, useClass: DomainExceptionFilter },
    { provide: APP_INTERCEPTOR, useClass: ResponseEnvelopeInterceptor },
    WorkerRunner,
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(RequestIdMiddleware).forRoutes('*');
  }
}
