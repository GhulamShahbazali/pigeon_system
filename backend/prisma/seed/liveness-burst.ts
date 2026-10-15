/**
 * Liveness burst — seeds a batch of bot posts, tournaments and live records RIGHT NOW
 * so a fresh feed feels alive instead of waiting for the slow drip of the engine tick.
 * Reuses the real BotActivityService (same use-cases → real counters, flights,
 * standings, 24h live records, notifications). Safe to re-run; it just adds more.
 *
 * Run: `npx ts-node -r dotenv/config prisma/seed/liveness-burst.ts`
 * Tunable via env: BURST_POSTS, BURST_TOURNAMENTS, BURST_RECORDS, BURST_FOLLOWS.
 */
import { NestFactory } from '@nestjs/core';
import { Logger } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { BotActivityService } from '../../src/modules/bots/services/bot-activity.service';
import { PrismaService } from '../../src/shared/prisma/prisma.service';

const num = (k: string, d: number) => Number(process.env[k] ?? d);
const rand = <T>(a: T[]): T => a[Math.floor(Math.random() * a.length)];
const shuffle = <T>(a: T[]): T[] => [...a].sort(() => Math.random() - 0.5);

async function main() {
  const log = new Logger('LivenessBurst');
  process.env.PROCESS_ROLE = process.env.PROCESS_ROLE ?? 'api'; // never 'scheduler' → engine stays off
  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['error', 'warn'] });

  const bots = app.get(BotActivityService, { strict: false });
  const prisma = app.get(PrismaService, { strict: false });

  const botRows = await prisma.user.findMany({
    where: { isBot: true, deletedAt: null },
    select: { id: true },
  });
  const botIds = botRows.map((b) => b.id);
  if (botIds.length === 0) {
    log.error('No bots found — run `npx ts-node prisma/seed/bots.ts` first.');
    await app.close();
    return;
  }
  log.log(`Roster: ${botIds.length} bots.`);

  const nPosts = num('BURST_POSTS', 45);
  const nTours = num('BURST_TOURNAMENTS', 8);
  const nRecords = num('BURST_RECORDS', 5);
  const nFollows = num('BURST_FOLLOWS', 60);

  // Posts (70/30 image split handled by the content provider).
  let posts = 0;
  for (const botId of shuffle(botIds).slice(0, nPosts)) {
    if (await bots.doPost(botId)) posts++;
  }
  log.log(`Posts created: ${posts}/${nPosts}`);

  // Tournaments (with participants + past-day flights → standings populate).
  let tours = 0;
  for (const botId of shuffle(botIds).slice(0, nTours)) {
    if (await bots.doTournament(botId)) tours++;
  }
  log.log(`Tournaments created: ${tours}/${nTours}`);

  // Live records (24h auto-end lifecycle).
  let recs = 0;
  for (const botId of shuffle(botIds).slice(0, nRecords)) {
    if (await bots.doRecord(botId)) recs++;
  }
  log.log(`Live records created: ${recs}/${nRecords}`);

  // Follows + likes + views so counts aren't all zero.
  let follows = 0;
  for (let i = 0; i < nFollows; i++) {
    const [a, b] = shuffle(botIds).slice(0, 2);
    if (a && b && (await bots.doFollow(a, b))) follows++;
  }
  log.log(`Follows created: ${follows}/${nFollows}`);

  // Spread a few likes/views over the freshest posts (kept light — this loop is
  // the slowest part on a remote DB, so cap it rather than liking every post).
  const nLikePosts = num('BURST_LIKE_POSTS', 15);
  const fresh = await prisma.post.findMany({
    orderBy: { createdAt: 'desc' },
    take: nLikePosts,
    select: { id: true },
  });
  const freshIds = fresh.map((p) => p.id);
  let likes = 0;
  for (const postId of freshIds) {
    const likers = shuffle(botIds).slice(0, 1 + Math.floor(Math.random() * 3));
    for (const botId of likers) if (await bots.doLike(postId, botId)) likes++;
  }
  if (freshIds.length) await bots.doView(rand(botIds), freshIds);
  log.log(`Likes created: ${likes} over ${freshIds.length} fresh posts.`);

  log.log('Liveness burst complete.');
  await app.close();
}

main().catch((e) => {
  console.error('Liveness burst failed:', e);
  process.exit(1);
});
