import { Module } from '@nestjs/common';
import { MediaController } from './media.controller';

/** Chat media uploads (voice/image/video) stored on disk in the project uploads/ folder. */
@Module({
  controllers: [MediaController],
})
export class MediaModule {}
