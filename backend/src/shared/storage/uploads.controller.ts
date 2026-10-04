import {
  Controller,
  Post,
  UploadedFile,
  UseInterceptors,
  Body,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { StorageService } from './storage.service';
import { UnprocessableError } from '../errors/common-errors';

const PURPOSES = [
  'participant_photo',
  'tournament_cover',
  'post_image',
  'profile_photo',
  'chat_image',
  'chat_video',
  'voice_note',
];

@Controller('uploads')
export class UploadsController {
  constructor(private readonly storage: StorageService) {}

  @Post()
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 25 * 1024 * 1024 } }))
  async upload(
    @UploadedFile() file: { buffer: Buffer; mimetype: string } | undefined,
    @Body('purpose') purpose: string,
  ) {
    if (!file) throw new UnprocessableError('No file', { file: 'required' });
    if (!PURPOSES.includes(purpose)) throw new UnprocessableError('Bad purpose', { purpose: 'invalid' });
    const { url, key } = await this.storage.put(purpose, file.buffer, file.mimetype || 'application/octet-stream');
    return { url, key, upload_id: key };
  }
}
