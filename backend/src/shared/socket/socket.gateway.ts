import { Logger } from '@nestjs/common';
import {
  OnGatewayConnection,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { createAdapter } from '@socket.io/redis-adapter';
import { Server, Socket } from 'socket.io';
import { JwtService } from '../auth/jwt.service';
import { RedisService } from '../redis/redis.service';
import { EmitService } from './emit.service';

@WebSocketGateway({ cors: { origin: '*' } })
export class SocketGateway implements OnGatewayInit, OnGatewayConnection {
  private readonly logger = new Logger('Socket');
  @WebSocketServer() server!: Server;

  constructor(
    private readonly jwt: JwtService,
    private readonly redis: RedisService,
    private readonly emit: EmitService,
  ) {}

  afterInit(server: Server): void {
    const pub = this.redis.duplicate();
    const sub = this.redis.duplicate();
    server.adapter(createAdapter(pub, sub));
    this.emit.setServer(server);
    this.logger.log('Socket.io gateway ready (Redis adapter wired)');
  }

  handleConnection(client: Socket): void {
    try {
      const token = (client.handshake.auth?.token || client.handshake.query?.token) as string;
      const claims = this.jwt.verify(token);
      client.data.userId = claims.sub;
      client.join(`user:${claims.sub}`);
    } catch {
      client.disconnect(true);
    }
  }

  private ack(): { ok: true } {
    return { ok: true };
  }

  @SubscribeMessage('tournament.subscribe')
  tSub(@ConnectedSocket() c: Socket, @MessageBody() b: { tournament_id: string }) {
    c.join([`tournament:${b.tournament_id}`, `tournament:${b.tournament_id}:counts`]);
    return this.ack();
  }
  @SubscribeMessage('tournament.unsubscribe')
  tUnsub(@ConnectedSocket() c: Socket, @MessageBody() b: { tournament_id: string }) {
    c.leave(`tournament:${b.tournament_id}`);
    c.leave(`tournament:${b.tournament_id}:counts`);
    return this.ack();
  }

  @SubscribeMessage('record.subscribe')
  rSub(@ConnectedSocket() c: Socket, @MessageBody() b: { record_id: string }) {
    c.join([`record:${b.record_id}`, `record:${b.record_id}:counts`]);
    return this.ack();
  }
  @SubscribeMessage('record.unsubscribe')
  rUnsub(@ConnectedSocket() c: Socket, @MessageBody() b: { record_id: string }) {
    c.leave(`record:${b.record_id}`);
    c.leave(`record:${b.record_id}:counts`);
    return this.ack();
  }

  @SubscribeMessage('post.counts.subscribe')
  pSub(@ConnectedSocket() c: Socket, @MessageBody() b: { post_id: string }) {
    c.join(`post:${b.post_id}:counts`);
    return this.ack();
  }
  @SubscribeMessage('post.counts.unsubscribe')
  pUnsub(@ConnectedSocket() c: Socket, @MessageBody() b: { post_id: string }) {
    c.leave(`post:${b.post_id}:counts`);
    return this.ack();
  }

  @SubscribeMessage('feed.subscribe')
  fSub(@ConnectedSocket() c: Socket) {
    c.join('feed:global');
    return this.ack();
  }
  @SubscribeMessage('feed.unsubscribe')
  fUnsub(@ConnectedSocket() c: Socket) {
    c.leave('feed:global');
    return this.ack();
  }

  @SubscribeMessage('chat.subscribe')
  cSub(@ConnectedSocket() c: Socket, @MessageBody() b: { conversation_id: string }) {
    c.join(`chat:${b.conversation_id}`);
    return this.ack();
  }
  @SubscribeMessage('chat.unsubscribe')
  cUnsub(@ConnectedSocket() c: Socket, @MessageBody() b: { conversation_id: string }) {
    c.leave(`chat:${b.conversation_id}`);
    return this.ack();
  }
}
