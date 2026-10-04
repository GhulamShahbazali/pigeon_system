import { Module } from '@nestjs/common';
import { RecordsController } from './records.controller';
import { RecordUseCases } from './record.use-cases';
import { PrismaRecordRepository } from './data/prisma-record.repository';
import { LiveRecordAutoEndProcessor } from './live-record-auto-end.processor';

@Module({
  controllers: [RecordsController],
  providers: [RecordUseCases, PrismaRecordRepository, LiveRecordAutoEndProcessor],
  exports: [PrismaRecordRepository, LiveRecordAutoEndProcessor],
})
export class RecordsModule {}
