import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const tzMap: Record<string, string> = {
  PK: 'Asia/Karachi',
  IN: 'Asia/Kolkata',
  BD: 'Asia/Dhaka',
  AE: 'Asia/Dubai',
  KW: 'Asia/Kuwait',
  SA: 'Asia/Riyadh',
  UK: 'Europe/London',
  US: 'America/New_York',
  AU: 'Australia/Sydney',
};

async function fix() {
  console.log('Fixing bot timezones...');
  const bots = await prisma.user.findMany({ where: { isBot: true }, select: { id: true, countryCode: true } });
  for (const b of bots) {
    const tz = (b.countryCode && tzMap[b.countryCode]) ? tzMap[b.countryCode] : 'Asia/Karachi';
    await prisma.user.update({ where: { id: b.id }, data: { timezone: tz } });
  }
  console.log(`Updated ${bots.length} bot timezones.`);

  console.log('Fixing Daniel Patel record...');
  const daniel = await prisma.user.findFirst({ where: { displayName: { contains: 'Daniel Patel' } } });
  if (daniel) {
    const rec = await prisma.personalRecord.findFirst({
      where: { userId: daniel.id },
      include: { pigeons: true },
    });
    if (rec) {
      const properReleaseAt = new Date('2026-10-14T00:59:00.000Z');
      await prisma.personalRecord.update({
        where: { id: rec.id },
        data: { releaseAt: properReleaseAt },
      });
      for (const p of rec.pigeons) {
        const dur = Math.max(0, Math.floor((p.landingTime.getTime() - properReleaseAt.getTime()) / 1000));
        await prisma.recordPigeon.update({
          where: { id: p.id },
          data: { durationSeconds: dur },
        });
      }
      const agg = await prisma.recordPigeon.aggregate({
        where: { recordId: rec.id },
        _avg: { durationSeconds: true },
        _count: { _all: true },
      });
      await prisma.personalRecord.update({
        where: { id: rec.id },
        data: {
          totalAvgSeconds: agg._avg.durationSeconds ? Math.round(agg._avg.durationSeconds) : null,
          returnedCount: agg._count._all,
        },
      });
      console.log('Daniel Patel new totalAvgSeconds:', agg._avg.durationSeconds ? Math.round(agg._avg.durationSeconds) : null);
    }
  }

  console.log('Done fixing.');
  await prisma.$disconnect();
}

fix().catch((e) => {
  console.error(e);
  process.exit(1);
});
