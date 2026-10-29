import { Global, Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { PushSendProcessor } from './push-send.processor';
import { FollowerFanoutProcessor } from './follower-fanout.processor';
import { TournamentFanoutProcessor } from './tournament-fanout.processor';

@Global()
@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService, PushSendProcessor, FollowerFanoutProcessor, TournamentFanoutProcessor],
  exports: [NotificationsService, PushSendProcessor, FollowerFanoutProcessor, TournamentFanoutProcessor],
})
export class NotificationsModule {}
