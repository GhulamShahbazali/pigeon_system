import { PrismaClient } from '@prisma/client';
import { zonedToUtc } from '../../src/shared/date/tz';

const prisma = new PrismaClient();

async function fixAll() {
  console.log('Setting all bot timezones to Asia/Karachi...');
  await prisma.user.updateMany({
    where: { isBot: true },
    data: { timezone: 'Asia/Karachi' },
  });

  console.log('Aligning all personal records to standard 06:00 AM PKT release...');
  const records = await prisma.personalRecord.findMany({
    include: {
      user: { select: { displayName: true } },
      pigeons: true,
    },
  });

  for (const r of records) {
    const dateStr = r.recordDate.toISOString().slice(0, 10);
    const flyTime = '06:00';
    const properReleaseAt = zonedToUtc(dateStr, flyTime, 'Asia/Karachi');

    await prisma.personalRecord.update({
      where: { id: r.id },
      data: {
        flyTime,
        releaseAt: properReleaseAt,
      },
    });

    if (r.pigeons.length > 0) {
      for (const p of r.pigeons) {
        const dur = Math.max(0, Math.floor((p.landingTime.getTime() - properReleaseAt.getTime()) / 1000));
        await prisma.recordPigeon.update({
          where: { id: p.id },
          data: { durationSeconds: dur },
        });
      }

      const agg = await prisma.recordPigeon.aggregate({
        where: { recordId: r.id },
        _avg: { durationSeconds: true },
        _count: { _all: true },
      });

      const newAvg = agg._avg.durationSeconds ? Math.round(agg._avg.durationSeconds) : null;
      await prisma.personalRecord.update({
        where: { id: r.id },
        data: {
          totalAvgSeconds: newAvg,
          returnedCount: agg._count._all,
        },
      });

      const avgH = Math.floor((newAvg ?? 0) / 3600);
      const avgM = Math.floor(((newAvg ?? 0) % 3600) / 60);
      console.log(`✓ ${r.user.displayName}: Fly ${flyTime} AM | ${r.pigeons.length} pigeons | Avg: ${String(avgH).padStart(2, '0')}:${String(avgM).padStart(2, '0')}`);
    }
  }

  console.log('All personal records synchronized to 06:00 AM PKT!');
  await prisma.$disconnect();
}

fixAll().catch((e) => {
  console.error(e);
  process.exit(1);
});
