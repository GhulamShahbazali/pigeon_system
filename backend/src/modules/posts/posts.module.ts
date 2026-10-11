import { Module } from '@nestjs/common';
import { PostsController } from './posts.controller';
import { PostUseCases } from './post.use-cases';
import { PrismaPostRepository } from './data/prisma-post.repository';

@Module({
  controllers: [PostsController],
  providers: [PostUseCases, PrismaPostRepository],
  exports: [PostUseCases, PrismaPostRepository],
})
export class PostsModule {}
