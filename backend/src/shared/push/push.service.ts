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
    const keyVal = this.config.get<string>('FIREBASE_ADMIN_SDK_KEY');
    if (!keyVal) return false;
    let cert: any;
    if (keyVal.trim().startsWith('{')) {
      try {
        cert = JSON.parse(keyVal);
      } catch {
        return false;
      }
    } else if (fs.existsSync(keyVal)) {
      try {
        cert = JSON.parse(fs.readFileSync(keyVal, 'utf8'));
      } catch {
        return false;
      }
    } else {
      return false;
    }
    admin.initializeApp({ credential: admin.credential.cert(cert) });
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
      const res = await admin.messaging().sendEachForMulticast({
        tokens: valid,
        notification: { title, body },
        data,
        android: {
          priority: 'high',
          notification: {
            channelId: 'pigeonfly_notifications',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      });
      this.logger.log(`FCM multicast sent: ${res.successCount} success, ${res.failureCount} failed`);
      if (res.failureCount > 0) {
        for (const resp of res.responses) {
          if (!resp.success) {
            this.logger.warn(`FCM send error: ${resp.error?.message} (${resp.error?.code})`);
          }
        }
      }
    } catch (e) {
      this.logger.warn(`FCM send failed: ${(e as Error).message}`);
    }
  }
}
