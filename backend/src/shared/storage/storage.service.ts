import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { randomUUID } from 'crypto';

/** Cloudflare R2 (S3-compatible). Falls back to a dev placeholder URL when not configured. */
@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  private client?: S3Client;
  private readonly bucket?: string;
  private readonly base: string;

  constructor(private readonly config: ConfigService) {
    this.bucket = this.config.get<string>('R2_BUCKET');
    this.base = this.config.get<string>('R2_PUBLIC_BASE_URL') ?? 'https://media.pigeonfly.app';
    const account = this.config.get<string>('R2_ACCOUNT_ID');
    const key = this.config.get<string>('R2_ACCESS_KEY_ID');
    const secret = this.config.get<string>('R2_SECRET_ACCESS_KEY');
    if (account && key && secret && this.bucket) {
      this.client = new S3Client({
        region: 'auto',
        endpoint: `https://${account}.r2.cloudflarestorage.com`,
        credentials: { accessKeyId: key, secretAccessKey: secret },
      });
    }
  }

  async put(purpose: string, body: Buffer, contentType: string): Promise<{ url: string; key: string }> {
    const ext = (contentType.split('/')[1] ?? 'bin').replace(/[^a-z0-9]/gi, '');
    const key = `${purpose}/${randomUUID()}.${ext}`;
    if (!this.client || !this.bucket) {
      this.logger.debug(`[storage not configured] returning placeholder for ${key}`);
      return { url: `${this.base}/${key}`, key };
    }
    await this.client.send(
      new PutObjectCommand({ Bucket: this.bucket, Key: key, Body: body, ContentType: contentType }),
    );
    return { url: `${this.base}/${key}`, key };
  }
}
