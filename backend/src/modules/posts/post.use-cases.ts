import { Injectable } from '@nestjs/common';
import { PrismaPostRepository } from './data/prisma-post.repository';
import { EmitService } from '../../shared/socket/emit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { Err, Ok, Result } from '../../shared/result/result';
import { ForbiddenError, NotFoundError } from '../../shared/errors/common-errors';

@Injectable()
export class PostUseCases {
  constructor(
    private readonly repo: PrismaPostRepository,
    private readonly emit: EmitService,
    private readonly notifs: NotificationsService,
  ) {}

  feed = (tab: 'for_you' | 'following', viewerId: string, limit: number) =>
    this.repo.feed(tab, viewerId, limit);

  async detail(id: string, viewerId: string) {
    const p = await this.repo.getById(id);
    if (p.authorId !== viewerId) await this.repo.view(id, viewerId);
    return p;
  }

  async create(authorId: string, content?: string, imageUrl?: string): Promise<Result<any>> {
    if (!content && !imageUrl) return Err(new ForbiddenError('Empty post'));
    const p = await this.repo.create(authorId, content, imageUrl);
    this.emit.toRoom('feed:global', 'post.new', { post_id: p.id, author_id: authorId });
    return Ok(p);
  }

  async update(actorId: string, id: string, content?: string, imageUrl?: string): Promise<Result<any>> {
    const author = await this.repo.authorOf(id);
    if (!author) return Err(new NotFoundError('post'));
    if (author !== actorId) return Err(new ForbiddenError());
    return Ok(await this.repo.update(id, content, imageUrl));
  }

  async remove(actorId: string, id: string): Promise<Result<null>> {
    const author = await this.repo.authorOf(id);
    if (!author) return Err(new NotFoundError('post'));
    if (author !== actorId) return Err(new ForbiddenError());
    await this.repo.softDelete(id);
    return Ok(null);
  }

  async like(id: string, userId: string): Promise<void> {
    const authorId = await this.repo.like(id, userId);
    const counts = await this.repo.counts(id);
    await this.emit.toRoomDebounced(
      `post:${id}:counts`,
      `throttle:post_counts:${id}`,
      'post.counts',
      { post_id: id, like_count: counts?.likeCount, share_count: counts?.shareCount, view_count: counts?.viewCount },
    );
    if (authorId) {
      await this.notifs.notify({ recipientId: authorId, type: 'content_like', entityType: 'post', entityId: id, actorId: userId });
    }
  }
  unlike = (id: string, uid: string) => this.repo.unlike(id, uid);
  share = (id: string, uid: string) => this.repo.share(id, uid);
  hide = (id: string, uid: string) => this.repo.hide(id, uid);
  unhide = (id: string, uid: string) => this.repo.unhide(id, uid);
  report = (uid: string, id: string, reason: string, note?: string) => this.repo.report(uid, id, reason, note);
}
