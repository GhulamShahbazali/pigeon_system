import { Module } from '@nestjs/common';
import { SocialController } from './presentation/social.controller';
import { SocialUseCases } from './domain/social.use-cases';
import { PrismaSocialRepository } from './data/prisma-social.repository';
import { SOCIAL_REPOSITORY } from './domain/social.repository';

@Module({
  controllers: [SocialController],
  providers: [SocialUseCases, { provide: SOCIAL_REPOSITORY, useClass: PrismaSocialRepository }],
  exports: [SocialUseCases],
})
export class SocialModule {}
