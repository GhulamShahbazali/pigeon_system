import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as admin from 'firebase-admin';

export interface FirebaseIdentity {
  provider: 'google' | 'apple';
  providerId: string; // firebase uid
  email?: string;
}

/** Verifies a client Firebase ID token. Lazy-inits firebase-admin from the service-account JSON. */
@Injectable()
export class FirebaseVerifierAdapter {
  private readonly logger = new Logger(FirebaseVerifierAdapter.name);
  private app?: admin.app.App;

  constructor(private readonly config: ConfigService) {}

  private init(): admin.app.App {
    if (this.app) return this.app;
    if (admin.apps.length) {
      this.app = admin.apps[0]!;
      return this.app;
    }
    const keyPath = this.config.get<string>('FIREBASE_ADMIN_SDK_KEY');
    if (!keyPath || !fs.existsSync(keyPath)) {
      throw new Error('FIREBASE_ADMIN_SDK_KEY is not configured — cannot verify tokens');
    }
    const cert = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
    this.app = admin.initializeApp({ credential: admin.credential.cert(cert) });
    this.logger.log('Firebase Admin initialized');
    return this.app;
  }

  async verify(idToken: string): Promise<FirebaseIdentity> {
    const decoded = await this.init().auth().verifyIdToken(idToken);
    const providerId = decoded.firebase?.sign_in_provider ?? '';
    const provider: 'google' | 'apple' = providerId.includes('apple') ? 'apple' : 'google';
    return { provider, providerId: decoded.uid, email: decoded.email };
  }
}
