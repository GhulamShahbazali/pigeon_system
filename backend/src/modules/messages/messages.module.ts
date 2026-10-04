import { Module } from '@nestjs/common';
import { MessagesController } from './messages.controller';
import { MessageUseCases } from './message.use-cases';
import { PrismaMessageRepository } from './data/prisma-message.repository';
import { DmPushProcessor } from './dm-push.processor';

@Module({
  controllers: [MessagesController],
  providers: [MessageUseCases, PrismaMessageRepository, DmPushProcessor],
  exports: [DmPushProcessor],
})
export class MessagesModule {}
