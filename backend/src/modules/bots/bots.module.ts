import { Module } from '@nestjs/common';
import { PostsModule } from '../posts/posts.module';
import { SocialModule } from '../social/social.module';
import { TournamentsModule } from '../tournaments/tournaments.module';
import { RecordsModule } from '../records/records.module';
import { BotsAdminController } from './presentation/bots-admin.controller';
import { BotsAdminService } from './services/bots-admin.service';
import { BotActivityService } from './services/bot-activity.service';
import { BotEngine } from './services/bot-engine';
import { BotEngineBootstrap } from './services/bot-engine.bootstrap';
import { ContentProvider } from './data/content.provider';
import { PrismaBotConfigRepository } from './data/prisma-bot-config.repository';
import { PrismaBotRosterRepository } from './data/prisma-bot-roster.repository';
import { RedisBotState } from './data/redis-bot-state';
import { BOT_CONFIG_REPOSITORY, BOT_ROSTER_REPOSITORY, BOT_STATE, CONTENT_PROVIDER } from './domain/tokens';

@Module({
  imports: [PostsModule, SocialModule, TournamentsModule, RecordsModule],
  controllers: [BotsAdminController],
  providers: [
    BotsAdminService,
    BotActivityService,
    BotEngine,
    BotEngineBootstrap,
    { provide: CONTENT_PROVIDER, useClass: ContentProvider },
    { provide: BOT_CONFIG_REPOSITORY, useClass: PrismaBotConfigRepository },
    { provide: BOT_ROSTER_REPOSITORY, useClass: PrismaBotRosterRepository },
    { provide: BOT_STATE, useClass: RedisBotState },
  ],
})
export class BotsModule {}
