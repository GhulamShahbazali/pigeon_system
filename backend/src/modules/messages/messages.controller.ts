import { Body, Controller, Delete, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { z } from 'zod';
import { AuthUser, CurrentUser } from '../../shared/auth/decorators';
import { ZodValidationPipe } from '../../shared/pipes/zod-validation.pipe';
import { MessageUseCases } from './message.use-cases';

const SendSchema = z
  .object({
    to_user_id: z.string().uuid().optional(),
    conversation_id: z.string().uuid().optional(),
    type: z.enum(['text', 'voice', 'image', 'video']),
    body: z.string().max(5000).optional(),
    media_url: z.string().url().optional(),
    media_duration_seconds: z.number().int().positive().max(3600).optional(),
  })
  .refine((v) => v.to_user_id || v.conversation_id, { message: 'to_user_id or conversation_id required' })
  .refine((v) => v.type === 'text' ? !!v.body?.trim() : !!v.media_url, {
    message: 'text needs body; media needs media_url',
  });

const ReadSchema = z.object({ up_to_message_id: z.string().uuid() });

function lim(v?: string): number {
  const n = Number(v);
  return Number.isFinite(n) && n > 0 && n <= 100 ? Math.floor(n) : 30;
}

@Controller()
export class MessagesController {
  constructor(private readonly uc: MessageUseCases) {}

  @Get('conversations')
  async inbox(@CurrentUser() u: AuthUser, @Query('limit') l?: string) {
    return { data: await this.uc.inbox(u.id, lim(l)) };
  }

  @Get('conversations/requests')
  async requests(@CurrentUser() u: AuthUser) {
    return { data: await this.uc.requests(u.id) };
  }

  @Get('conversations/with/:userId')
  async conversationWith(@Param('userId') userId: string, @CurrentUser() u: AuthUser) {
    const convo = await this.uc.findWith(u.id, userId);
    return {
      data: convo ? { conversation_id: convo.id, status: convo.status } : null,
    };
  }

  @Get('conversations/:id/messages')
  async messages(@Param('id') id: string, @CurrentUser() u: AuthUser, @Query('limit') l?: string) {
    return { data: await this.uc.messages(id, u.id, lim(l)) };
  }

  @Post('messages')
  async send(@CurrentUser() u: AuthUser, @Body(new ZodValidationPipe(SendSchema)) b: any) {
    return this.uc.send(u.id, b);
  }

  @Post('conversations/:id/accept')
  @HttpCode(204)
  accept(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    return this.uc.accept(id, u.id);
  }

  @Delete('conversations/:id/request')
  @HttpCode(204)
  async decline(@Param('id') id: string, @CurrentUser() u: AuthUser) {
    await this.uc.deleteRequest(id, u.id);
  }

  @Post('conversations/:id/read')
  @HttpCode(204)
  read(@Param('id') id: string, @CurrentUser() u: AuthUser, @Body(new ZodValidationPipe(ReadSchema)) b: any) {
    return this.uc.read(id, u.id, b.up_to_message_id);
  }

  @Delete('messages/:id')
  @HttpCode(204)
  async del(@Param('id') id: string, @CurrentUser() u: AuthUser, @Query('conversation_id') cid?: string) {
    await this.uc.deleteMessage(id, u.id, cid ?? '');
  }
}
