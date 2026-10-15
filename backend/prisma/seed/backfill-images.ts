/**
 * One-shot backfill: replace broken LoremFlickr image URLs (now HTTP 401) on
 * existing bot content with reliable Unsplash CDN photos, and apply the 70/30
 * image/text-only ratio to bot posts.
 * Run: `npx ts-node prisma/seed/backfill-images.ts`
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Visually-verified PIGEON photo IDs — must stay in sync with content.provider.ts.
const UNSPLASH_PHOTO_IDS = [
  '1534695941753-73cf13435eb4', '1641144355850-e7991d050bdc', '1513099335611-0fd3bca7131c',
  '1592964377969-dc564e4c1599', '1514446194108-aa408d4d61d9', '1742659722918-e925e7877725',
  '1723302641915-ad18f40f2203', '1611172444539-823c575d298e', '1518157770830-df40b281672e',
  '1540382658444-5f53c7f12ac3', '1679243984878-b836be465a37', '1607417190565-630353c3d223',
  '1554226114-04bd78f87c24', '1697989120456-5fb3b24749fb', '1692652966645-d05118429bbd',
];
const rand = <T>(a: T[]): T => a[Math.floor(Math.random() * a.length)];
const img = (w: number, h: number) =>
  `https://images.unsplash.com/photo-${rand(UNSPLASH_PHOTO_IDS)}?auto=format&fit=crop&w=${w}&h=${h}&q=70`;
// A URL already pointing at one of our verified pigeon IDs — leave those alone.
const isPigeonUrl = (u: string | null) =>
  !!u && UNSPLASH_PHOTO_IDS.some((id) => u.includes(id));

async function main() {
  // Posts authored by bots that still point at loremflickr (or any non-unsplash host).
  const posts = await prisma.post.findMany({
    where: { author: { isBot: true }, imageUrl: { not: null } },
    select: { id: true, imageUrl: true },
  });
  let fixedPosts = 0, nulled = 0;
  for (const p of posts) {
    if (isPigeonUrl(p.imageUrl)) continue; // already a verified pigeon photo
    // 30% become text-only to match the live ratio; 70% get a working photo.
    if (Math.random() < 0.3) {
      await prisma.post.update({ where: { id: p.id }, data: { imageUrl: null } });
      nulled++;
    } else {
      await prisma.post.update({ where: { id: p.id }, data: { imageUrl: img(800, 600) } });
      fixedPosts++;
    }
  }

  // Tournament covers created by bots.
  const tours = await prisma.tournament.findMany({
    where: { organizer: { isBot: true } },
    select: { id: true, coverUrl: true },
  });
  let fixedCovers = 0;
  for (const t of tours) {
    if (isPigeonUrl(t.coverUrl)) continue;
    await prisma.tournament.update({ where: { id: t.id }, data: { coverUrl: img(1200, 600) } });
    fixedCovers++;
  }

  console.log(
    `Backfill done: ${fixedPosts} post images fixed, ${nulled} posts made text-only, ` +
    `${fixedCovers} tournament covers fixed (of ${posts.length} posts, ${tours.length} tournaments).`,
  );
  await prisma.$disconnect();
}

main().catch(async (e) => {
  console.error('Backfill failed:', e);
  await prisma.$disconnect();
  process.exit(1);
});
