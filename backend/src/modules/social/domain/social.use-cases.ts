import { Inject, Injectable } from '@nestjs/common';
import { ISocialRepository, SOCIAL_REPOSITORY, UpdateProfileInput } from './social.repository';
import { Err, Ok, Result } from '../../../shared/result/result';
import { BlockedError, ConflictError, NotFoundError } from '../../../shared/errors/common-errors';
import { NotificationsService } from '../../notifications/notifications.service';

@Injectable()
export class SocialUseCases {
  constructor(
    @Inject(SOCIAL_REPOSITORY) private readonly repo: ISocialRepository,
    private readonly notifications: NotificationsService,
  ) {}

  async profileById(id: string, viewerId: string): Promise<Result<any>> {
    const v = await this.repo.findProfileById(id, viewerId);
    return v ? Ok(v) : Err(new NotFoundError('user'));
  }
  async profileByUsername(username: string, viewerId: string): Promise<Result<any>> {
    const v = await this.repo.findProfileByUsername(username, viewerId);
    return v ? Ok(v) : Err(new NotFoundError('user'));
  }
  async updateProfile(userId: string, input: UpdateProfileInput) {
    // Username is unique and case-insensitive: normalize, and reject if another
    // user already holds it (clear field error instead of a raw DB conflict).
    if (input.username) {
      const username = input.username.toLowerCase();
      const existing = await this.repo.findProfileByUsername(username, userId);
      if (existing && existing.user.id !== userId) {
        throw new ConflictError('Username already taken', 'username');
      }
      input = { ...input, username };
    }
    return this.repo.updateProfile(userId, input);
  }

  async follow(followerId: string, followeeId: string): Promise<Result<null>> {
    if (followerId === followeeId) return Err(new ConflictError('Cannot follow yourself'));
    if (await this.repo.blockExistsEitherWay(followerId, followeeId)) return Err(new BlockedError());
    const ok = await this.repo.follow(followerId, followeeId);
    if (!ok) return Err(new ConflictError('Already following'));
    await this.notifications.notify({
      recipientId: followeeId,
      type: 'new_follower',
      entityType: 'user',
      entityId: followerId,
      actorId: followerId,
    });
    return Ok(null);
  }
  unfollow = (a: string, b: string) => this.repo.unfollow(a, b);

  async block(blockerId: string, blockedId: string): Promise<Result<null>> {
    if (blockerId === blockedId) return Err(new ConflictError('Cannot block yourself'));
    await this.repo.block(blockerId, blockedId);
    return Ok(null);
  }
  unblock = (a: string, b: string) => this.repo.unblock(a, b);

  followers = (id: string, limit: number) => this.repo.listFollowers(id, limit);
  following = (id: string, limit: number) => this.repo.listFollowing(id, limit);
  blocks = (id: string, limit: number) => this.repo.listBlocks(id, limit);
}
