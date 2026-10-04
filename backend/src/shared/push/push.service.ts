import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as admin from 'firebase-admin';

/** Sends FCM push. No-op (logs) when Firebase isn't configured. */
@Injectable()
export class PushService {
  private readonly logger = new Logger(PushService.name);
  private ready = false;

  constructor(private readonly config: ConfigService) {}

  private ensure(): boolean {
    if (this.ready) return true;
    if (admin.apps.length) {
      this.ready = true;
      return true;
    }
    const keyPath = this.config.get<string>('FIREBASE_ADMIN_SDK_KEY');
    if (!keyPath || !fs.existsSync(keyPath)) return false;
    admin.initializeApp({ credential: admin.credential.cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
    this.ready = true;
    return true;
  }

  async send(tokens: string[], title: string, body: string, data?: Record<string, string>): Promise<void> {
    const valid = tokens.filter(Boolean);
    if (!valid.length) return;
    if (!this.ensure()) {
      this.logger.debug(`[push skipped — no Firebase] ${title}: ${body} → ${valid.length} device(s)`);
      return;
    }
    try {
      await admin.messaging().sendEachForMulticast({
        tokens: valid,
        notification: { title, body },
        data,
      });
    } catch (e) {
      this.logger.warn(`FCM send failed: ${(e as Error).message}`);
    }
  }
}
