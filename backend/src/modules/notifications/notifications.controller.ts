import { Controller, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../shared/auth/decorators';
import { NotificationsService } from './notifications.service';

function n(v?: string): number {
  const x = Number(v);
  return Number.isFinite(x) && x > 0 && x <= 50 ? Math.floor(x) : 20;
}

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly svc: NotificationsService) {}

  @Get()
  async feed(@CurrentUser() u: AuthUser, @Query('limit') limit?: string) {
    const rows = await this.svc.feed(u.id, n(limit));
    return {
      data: rows.map((r) => ({
        id: r.id,
        type: r.type,
        entity_type: r.entityType,
        entity_id: r.entityId,
        is_read: r.isRead,
        created_at: r.createdAt.toISOString(),
        actors: r.actors.map((a) => ({
          id: a.id,
          display_name: a.displayName,
          username: a.username,
          photo_url: a.photoUrl,
        })),
        actor_ids: r.actors.map((a) => a.id),
        entity: r.entityTitle
          ? { type: r.entityType, id: r.entityId, title: r.entityTitle }
          : null,
        data: r.data ?? null,
      })),
    };
  }

  @Get('unread-count')
  async unread(@CurrentUser() u: AuthUser) {
    return { unread_count: await this.svc.unreadCount(u.id) };
  }

  @Post('read-all')
  @HttpCode(204)
  readAll(@CurrentUser() u: AuthUser) {
    return this.svc.markAllRead(u.id);
  }

  @Post(':id/read')
  @HttpCode(204)
  read(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    return this.svc.markRead(u.id, id);
  }
}
