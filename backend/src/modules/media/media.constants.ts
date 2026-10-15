import { join } from 'path';

/** Public URL prefix for uploaded media (served statically, outside the /v1 prefix). */
export const UPLOADS_ROUTE = '/uploads';

/** On-disk folder where chat media is stored — a `uploads/` folder in the project root. */
export const UPLOADS_DIR = join(process.cwd(), 'uploads');

/** Sub-folder for chat media specifically. */
export const CHAT_MEDIA_SUBDIR = 'media';
export const CHAT_MEDIA_DIR = join(UPLOADS_DIR, CHAT_MEDIA_SUBDIR);

export const MAX_MEDIA_BYTES = 25 * 1024 * 1024; // 25 MB

/** Map an incoming mimetype to our MessageType/MediaKind, or null if unsupported. */
export function kindFromMime(mime: string): 'voice' | 'image' | 'video' | null {
  if (mime.startsWith('audio/')) return 'voice';
  if (mime.startsWith('image/')) return 'image';
  if (mime.startsWith('video/')) return 'video';
  return null;
}
