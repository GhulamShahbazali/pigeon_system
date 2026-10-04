import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, Query } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../shared/auth/decorators';
import { ZodValidationPipe } from '../../shared/pipes/zod-validation.pipe';
import { PostUseCases } from './post.use-cases';
import { CreatePostSchema, ReportSchema, toPost, type CreatePostDto, type ReportDto } from './post.presentation';

function lim(v?: string): number {
  const n = Number(v);
  return Number.isFinite(n) && n > 0 && n <= 50 ? Math.floor(n) : 20;
}

@Controller()
export class PostsController {
  constructor(private readonly uc: PostUseCases) {}

  @Get('feed')
  async feed(@CurrentUser() u: AuthUser, @Query('tab') tab?: string, @Query('limit') l?: string) {
    const t = tab === 'following' ? 'following' : 'for_you';
    return { data: (await this.uc.feed(t, u.id, lim(l))).map(toPost) };
  }

  @Get('posts/:id')
  async detail(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    return toPost(await this.uc.detail(id, u.id));
  }

  @Post('posts')
  async create(@CurrentUser() u: AuthUser, @Body(new ZodValidationPipe(CreatePostSchema)) b: CreatePostDto) {
    const r = await this.uc.create(u.id, b.content, b.image_url);
    if (!r.ok) throw r.error;
    return toPost(r.value);
  }

  @Patch('posts/:id')
  async update(@Param('id') id: string, @CurrentUser() u: AuthUser, @Body(new ZodValidationPipe(CreatePostSchema)) b: CreatePostDto) {
    const r = await this.uc.update(u.id, id, b.content, b.image_url);
    if (!r.ok) throw r.error;
    return toPost(r.value);
  }

  @Delete('posts/:id')
  @HttpCode(204)
  async remove(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    const r = await this.uc.remove(u.id, id);
    if (!r.ok) throw r.error;
  }

  @Post('posts/:id/like')
  @HttpCode(204)
  like(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    return this.uc.like(id, u.id);
  }
  @Delete('posts/:id/like')
  @HttpCode(204)
  unlike(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    return this.uc.unlike(id, u.id);
  }
  @Post('posts/:id/share')
  @HttpCode(204)
  share(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    return this.uc.share(id, u.id);
  }
  @Post('posts/:id/hide')
  @HttpCode(204)
  hide(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    return this.uc.hide(id, u.id);
  }
  @Delete('posts/:id/hide')
  @HttpCode(204)
  unhide(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    return this.uc.unhide(id, u.id);
  }
  @Post('posts/:id/report')
  @HttpCode(201)
  async report(@Param('id') id: string, @CurrentUser() u: AuthUser, @Body(new ZodValidationPipe(ReportSchema)) b: ReportDto) {
    await this.uc.report(u.id, id, b.reason, b.note);
    return { data: { ok: true } };
  }
}
