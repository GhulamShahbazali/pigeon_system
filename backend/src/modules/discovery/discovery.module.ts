import { Module } from '@nestjs/common';
import { DiscoveryController } from './discovery.controller';
import { DiscoveryUseCases } from './discovery.use-cases';
import { PrismaDiscoveryRepository } from './data/prisma-discovery.repository';

@Module({
  controllers: [DiscoveryController],
  providers: [DiscoveryUseCases, PrismaDiscoveryRepository],
})
export class DiscoveryModule {}
