import {
  BadRequestException,
  Controller,
  Post,
  Req,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { randomUUID } from 'crypto';
import { extname } from 'path';
import { mkdirSync } from 'fs';
import { AuthUser, CurrentUser } from '../../shared/auth/decorators';
import {
  CHAT_MEDIA_DIR,
  CHAT_MEDIA_SUBDIR,
  MAX_MEDIA_BYTES,
  UPLOADS_ROUTE,
  kindFromMime,
} from './media.constants';

/** Minimal shape of a multer file (avoids a hard dep on @types/multer). */
interface UploadedFileLike {
  filename: string;
  mimetype: string;
  size: number;
}

// Ensure the target folder exists before multer writes to it.
mkdirSync(CHAT_MEDIA_DIR, { recursive: true });

@Controller('media')
export class MediaController {
  /**
   * Upload one chat media file (voice / image / video) to the project `uploads/`
   * folder and return its public URL + kind. The client then sends a message with
   * `media_url` set to this URL.
   */
  @Post()
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: CHAT_MEDIA_DIR,
        filename: (_req, file, cb) => cb(null, `${randomUUID()}${extname(file.originalname) || ''}`),
      }),
      limits: { fileSize: MAX_MEDIA_BYTES },
      fileFilter: (_req, file, cb) =>
        kindFromMime(file.mimetype)
          ? cb(null, true)
          : cb(new BadRequestException('Unsupported media type'), false),
    }),
  )
  upload(
    @CurrentUser() _user: AuthUser,
    @UploadedFile() file: UploadedFileLike | undefined,
    @Req() req: { protocol: string; get(name: string): string | undefined },
  ) {
    if (!file) throw new BadRequestException('No file uploaded');
    const kind = kindFromMime(file.mimetype);
    if (!kind) throw new BadRequestException('Unsupported media type');
    // Absolute URL so the mobile client can load it directly and the message
    // schema's url() validation passes. Host comes from the request (LAN IP in dev,
    // public host behind the proxy in prod — trust proxy is enabled).
    const base = process.env.PUBLIC_BASE_URL?.replace(/\/$/, '') || `${req.protocol}://${req.get('host')}`;
    const url = `${base}${UPLOADS_ROUTE}/${CHAT_MEDIA_SUBDIR}/${file.filename}`;
    return { data: { url, kind, size: file.size } };
  }
}
