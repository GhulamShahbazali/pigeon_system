import * as fs from 'fs';
import * as path from 'path';

/**
 * Resolves Firebase service account credentials from:
 * 1. Raw JSON string (single-line or formatted)
 * 2. Base64-encoded JSON string
 * 3. File path (relative or absolute)
 * 4. Render secret files path (/etc/secrets/...)
 */
export function resolveFirebaseCert(keyVal?: string): Record<string, any> | null {
  if (!keyVal) {
    if (fs.existsSync('/etc/secrets/firebase-admin.json')) {
      try {
        return JSON.parse(fs.readFileSync('/etc/secrets/firebase-admin.json', 'utf8'));
      } catch {
        return null;
      }
    }
    return null;
  }

  const trimmed = keyVal.trim();

  // 1. Raw JSON string
  if (trimmed.startsWith('{')) {
    try {
      return JSON.parse(trimmed);
    } catch {
      return null;
    }
  }

  // 2. Direct file path
  if (fs.existsSync(trimmed)) {
    try {
      return JSON.parse(fs.readFileSync(trimmed, 'utf8'));
    } catch {
      return null;
    }
  }

  // 3. Render secret file fallback: /etc/secrets/<filename> or /etc/secrets/firebase-admin.json
  const basename = path.basename(trimmed);
  const renderSecretPath = path.join('/etc/secrets', basename);
  if (fs.existsSync(renderSecretPath)) {
    try {
      return JSON.parse(fs.readFileSync(renderSecretPath, 'utf8'));
    } catch {
      return null;
    }
  }
  if (fs.existsSync('/etc/secrets/firebase-admin.json')) {
    try {
      return JSON.parse(fs.readFileSync('/etc/secrets/firebase-admin.json', 'utf8'));
    } catch {
      return null;
    }
  }

  // 4. Base64-encoded JSON string
  try {
    const decoded = Buffer.from(trimmed, 'base64').toString('utf8').trim();
    if (decoded.startsWith('{')) {
      return JSON.parse(decoded);
    }
  } catch {
    // not base64
  }

  return null;
}

