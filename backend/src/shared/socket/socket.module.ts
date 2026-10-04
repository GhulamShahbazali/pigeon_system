import { Global, Module } from '@nestjs/common';
import { EmitService } from './emit.service';
import { SocketGateway } from './socket.gateway';

@Global()
@Module({
  providers: [EmitService, SocketGateway],
  exports: [EmitService],
})
export class SocketModule {}
