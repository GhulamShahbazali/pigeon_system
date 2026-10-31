import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as admin from 'firebase-admin';
import { UnauthenticatedError } from '../../../../shared/errors/common-errors';

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
    const keyVal = this.config.get<string>('FIREBASE_ADMIN_SDK_KEY');
    if (!keyVal) {
      this.logger.error('FIREBASE_ADMIN_SDK_KEY is not configured in environment variables');
      throw new Error('FIREBASE_ADMIN_SDK_KEY is not configured — cannot verify tokens');
    }
    let cert: any;
    if (keyVal.trim().startsWith('{')) {
      try {
        cert = JSON.parse(keyVal);
      } catch (err: any) {
        this.logger.error(`Failed to parse FIREBASE_ADMIN_SDK_KEY as JSON: ${err.message}`);
        throw new Error(`FIREBASE_ADMIN_SDK_KEY invalid JSON: ${err.message}`);
      }
    } else if (fs.existsSync(keyVal)) {
      try {
        cert = JSON.parse(fs.readFileSync(keyVal, 'utf8'));
      } catch (err: any) {
        this.logger.error(`Failed to read/parse FIREBASE_ADMIN_SDK_KEY file at ${keyVal}: ${err.message}`);
        throw new Error(`FIREBASE_ADMIN_SDK_KEY file read error: ${err.message}`);
      }
    } else {
      this.logger.error(`FIREBASE_ADMIN_SDK_KEY file not found at: ${keyVal}`);
      throw new Error(`FIREBASE_ADMIN_SDK_KEY file not found at: ${keyVal}`);
    }
    this.app = admin.initializeApp({ credential: admin.credential.cert(cert) });
    this.logger.log('Firebase Admin initialized successfully');
    return this.app;
  }

  async verify(idToken: string): Promise<FirebaseIdentity> {
    try {
      const decoded = await this.init().auth().verifyIdToken(idToken);
      const providerId = decoded.firebase?.sign_in_provider ?? '';
      const provider: 'google' | 'apple' = providerId.includes('apple') ? 'apple' : 'google';
      return { provider, providerId: decoded.uid, email: decoded.email };
    } catch (err: any) {
      if (err instanceof UnauthenticatedError) throw err;
      this.logger.warn(`Firebase token verification failed: ${err.message}`);
      throw new UnauthenticatedError(`Invalid or expired token: ${err.message}`);
    }
  }
}
