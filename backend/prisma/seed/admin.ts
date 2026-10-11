/**
 * Seed a SuperAdmin staff account with username + password (scrypt).
 * Idempotent upsert. Credentials from env or defaults:
 *   ADMIN_USERNAME (default: admin)   ADMIN_PASSWORD (default: pigeonfly123)
 * Run: `npm run seed:admin`   (DATABASE_URL in env)
 */
import { PrismaClient } from '@prisma/client';
import { randomBytes, scryptSync } from 'crypto';
import { randomUUID } from 'crypto';

const prisma = new PrismaClient();

function hashPassword(password: string): string {
  const salt = randomBytes(16).toString('hex');
  const hash = scryptSync(password, salt, 64).toString('hex');
  return `scrypt$${salt}$${hash}`;
}

async function main() {
  const username = (process.env.ADMIN_USERNAME ?? 'admin').toLowerCase();
  const password = process.env.ADMIN_PASSWORD ?? 'pigeonfly123';
  const passwordHash = hashPassword(password);

  await prisma.user.upsert({
    where: { username },
    create: {
      authProvider: 'bot', // internal account, never a real Google/Apple identity
      authProviderId: 'staff-' + randomUUID(),
      displayName: 'Super Admin',
      username,
      role: 'superadmin',
      passwordHash,
      timezone: 'UTC',
      languageCode: 'en',
      email: `${username}@pigeonfly.internal`,
    },
    update: { role: 'superadmin', passwordHash },
  });

  console.log(`\n✓ SuperAdmin ready:\n   username: ${username}\n   password: ${password}\n`);
  await prisma.$disconnect();
}

main().catch(async (e) => {
  console.error('Admin seed failed:', e);
  await prisma.$disconnect();
  process.exit(1);
});
