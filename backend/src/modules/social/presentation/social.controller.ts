import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, Query } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../../shared/auth/decorators';
import { ZodValidationPipe } from '../../../shared/pipes/zod-validation.pipe';
import { SocialUseCases } from '../domain/social.use-cases';
import {
  UpdateProfileSchema,
  profileResponse,
  userCard,
  type UpdateProfileDto,
} from './social.presentation';

function limitOf(v?: string): number {
  const n = Number(v);
  return Number.isFinite(n) && n > 0 && n <= 50 ? Math.floor(n) : 20;
}

@Controller()
export class SocialController {
  constructor(private readonly social: SocialUseCases) {}

  @Patch('me')
  async updateMe(
    @CurrentUser() user: AuthUser,
    @Body(new ZodValidationPipe(UpdateProfileSchema)) b: UpdateProfileDto,
  ) {
    const u = await this.social.updateProfile(user.id, {
      displayName: b.display_name,
      bio: b.bio,
      city: b.city,
      photoUrl: b.photo_url,
    });
    return profileResponse({ user: u, isFollowing: false, isBlocked: false, tournamentCount: 0 });
  }

  @Get('me/blocks')
  async myBlocks(@CurrentUser() u: AuthUser, @Query('limit') limit?: string) {
    return { data: (await this.social.blocks(u.id, limitOf(limit))).map(userCard) };
  }

  @Get('users/by-username/:username')
  async byUsername(@Param('username') username: string, @CurrentUser() u: AuthUser) {
    const r = await this.social.profileByUsername(username, u.id);
    if (!r.ok) throw r.error;
    return profileResponse(r.value);
  }

  @Get('users/:id')
  async profile(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    const r = await this.social.profileById(id, u.id);
    if (!r.ok) throw r.error;
    return profileResponse(r.value);
  }

  @Get('users/:id/followers')
  async followers(@Param('id') id: string, @Query('limit') limit?: string) {
    return { data: (await this.social.followers(id, limitOf(limit))).map(userCard) };
  }

  @Get('users/:id/following')
  async following(@Param('id') id: string, @Query('limit') limit?: string) {
    return { data: (await this.social.following(id, limitOf(limit))).map(userCard) };
  }

  @Post('users/:id/follow')
  @HttpCode(204)
  async follow(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    const r = await this.social.follow(u.id, id);
    if (!r.ok) throw r.error;
  }

  @Delete('users/:id/follow')
  @HttpCode(204)
  async unfollow(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    await this.social.unfollow(u.id, id);
  }

  @Post('users/:id/block')
  @HttpCode(204)
  async block(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    const r = await this.social.block(u.id, id);
    if (!r.ok) throw r.error;
  }

  @Delete('users/:id/block')
  @HttpCode(204)
  async unblock(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    await this.social.unblock(u.id, id);
  }
}
