import { Global, Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { PushSendProcessor } from './push-send.processor';
import { FollowerFanoutProcessor } from './follower-fanout.processor';

@Global()
@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService, PushSendProcessor, FollowerFanoutProcessor],
  exports: [NotificationsService, PushSendProcessor, FollowerFanoutProcessor],
})
export class NotificationsModule {}
