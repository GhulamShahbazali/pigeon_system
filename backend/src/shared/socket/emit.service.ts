import { Injectable } from '@nestjs/common';
import { Server } from 'socket.io';
import { RedisService } from '../redis/redis.service';

/** Thin wrapper over the Socket.io server for modules to emit without importing the gateway. */
@Injectable()
export class EmitService {
  private server?: Server;

  constructor(private readonly redis: RedisService) {}

  setServer(server: Server): void {
    this.server = server;
  }

  toUser(userId: string, event: string, payload: unknown): void {
    this.server?.to(`user:${userId}`).emit(event, payload);
  }

  toRoom(room: string, event: string, payload: unknown): void {
    this.server?.to(room).emit(event, payload);
  }

  /** Emit at most once per `ttl`s per key (full-snapshot count updates). */
  async toRoomDebounced(
    room: string,
    throttleKey: string,
    event: string,
    payload: unknown,
    ttl = 2,
  ): Promise<void> {
    try {
      const ok = await this.redis.client.set(throttleKey, '1', 'EX', ttl, 'NX');
      if (ok) this.toRoom(room, event, payload);
    } catch {
      /* Redis down → skip emit; REST carries authoritative counts */
    }
  }
}
