/**
 * Bot roster seed — idempotent upsert on `bot_key`.
 * Project-accurate: Pakistani + Arabic heavy, few English; ~95% male / 5% female;
 * region-matched avatars (DiceBear — skin tone + gender per country).
 * Re-run any time: inserts new, updates changed, soft-deletes bots no longer in the set.
 * Run: `npx ts-node prisma/seed/bots.ts` (DATABASE_URL in env; use the DIRECT url in prod).
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

type Pool = {
  count: number;
  cities: string[];
  skin: string;          // DiceBear skinColor list
  maleFirst: string[];
  femaleFirst: string[];
  last: string[];
};

// Distribution: PK + Arab dominate; English kept small.
const COUNTRIES: Record<string, Pool> = {
  PK: { count: 48, skin: 'ae5d29,d08b5b', cities: ['Lahore', 'Karachi', 'Faisalabad', 'Rawalpindi', 'Multan', 'Gujranwala', 'Sialkot', 'Peshawar'],
        maleFirst: ['Bilal', 'Kashif', 'Sohail', 'Usman', 'Imran', 'Adnan', 'Faisal', 'Zeeshan', 'Hamza', 'Tariq', 'Asif', 'Rizwan', 'Shahid', 'Naveed', 'Waqas', 'Junaid', 'Saad', 'Umair'],
        femaleFirst: ['Ayesha', 'Fatima', 'Sana', 'Hira'],
        last: ['Raza', 'Ali', 'Ahmed', 'Khan', 'Butt', 'Malik', 'Shah', 'Chaudhry', 'Qureshi', 'Iqbal'] },
  AE: { count: 26, skin: 'd08b5b,edb98a', cities: ['Dubai', 'Abu Dhabi', 'Sharjah', 'Al Ain', 'Ajman'],
        maleFirst: ['Khalid', 'Omar', 'Rashid', 'Yousef', 'Saeed', 'Hamdan', 'Mohammed', 'Sultan', 'Majid', 'Abdullah', 'Faisal', 'Hamad'],
        femaleFirst: ['Mariam', 'Noura'],
        last: ['Al Mansoori', 'Al Nuaimi', 'Al Maktoum', 'Al Marri', 'Al Suwaidi', 'Al Hashimi'] },
  SA: { count: 22, skin: 'd08b5b,edb98a', cities: ['Riyadh', 'Jeddah', 'Dammam', 'Mecca', 'Medina'],
        maleFirst: ['Saud', 'Turki', 'Majed', 'Abdullah', 'Faisal', 'Fahad', 'Nawaf', 'Bandar', 'Salman'],
        femaleFirst: ['Sara', 'Lama'],
        last: ['Al Qahtani', 'Al Harbi', 'Al Dossari', 'Al Ghamdi', 'Al Otaibi', 'Al Shehri'] },
  KW: { count: 14, skin: 'd08b5b,edb98a', cities: ['Kuwait City', 'Hawalli', 'Salmiya', 'Jahra', 'Farwaniya'],
        maleFirst: ['Fahad', 'Nasser', 'Bader', 'Yousef', 'Mishal', 'Abdulaziz'],
        femaleFirst: ['Dana'],
        last: ['Al Sabah', 'Al Rashidi', 'Al Otaibi', 'Al Azmi', 'Al Mutairi'] },
  IN: { count: 22, skin: 'ae5d29,d08b5b', cities: ['Mumbai', 'Delhi', 'Hyderabad', 'Chennai', 'Kolkata', 'Pune'],
        maleFirst: ['Rohan', 'Arjun', 'Vikram', 'Sanjay', 'Deepak', 'Imran', 'Rahul', 'Aakash', 'Suresh', 'Faizan'],
        femaleFirst: ['Priya', 'Anjali'],
        last: ['Mehta', 'Nair', 'Rao', 'Patel', 'Verma', 'Khan', 'Sharma', 'Reddy'] },
  BD: { count: 16, skin: 'ae5d29,d08b5b', cities: ['Dhaka', 'Chittagong', 'Khulna', 'Sylhet', 'Rajshahi'],
        maleFirst: ['Rakib', 'Tanvir', 'Shakil', 'Nahid', 'Jubayer', 'Arif', 'Sumon', 'Rifat'],
        femaleFirst: ['Nusrat', 'Sadia'],
        last: ['Hasan', 'Islam', 'Ahmed', 'Rahman', 'Alam', 'Chowdhury'] },
  UK: { count: 10, skin: 'edb98a,ffdbb4', cities: ['London', 'Manchester', 'Birmingham', 'Bradford', 'Leeds'],
        maleFirst: ['James', 'David', 'Liam', 'Mohammed', 'Daniel', 'Harry', 'Jack', 'Imran'],
        femaleFirst: ['Emily'],
        last: ['Carter', 'Hughes', 'Walsh', 'Patel', 'Smith', 'Khan'] },
  US: { count: 8, skin: 'edb98a,d08b5b,614335', cities: ['New York', 'Chicago', 'Houston', 'Los Angeles'],
        maleFirst: ['Mike', 'Carlos', 'Tyrone', 'Kevin', 'Jason', 'Chris'],
        femaleFirst: ['Ashley'],
        last: ['Anderson', 'Rivera', 'Brooks', 'Johnson', 'Martinez'] },
  AU: { count: 6, skin: 'edb98a,ffdbb4', cities: ['Sydney', 'Melbourne', 'Brisbane', 'Perth'],
        maleFirst: ['Jack', 'Nathan', 'Daniel', 'Luke', 'Ethan'],
        femaleFirst: ['Chloe'],
        last: ['Thompson', 'Lee', 'Cross', 'Walker'] },
};

const TZ_OFFSET: Record<string, number> = { PK: 5, IN: 5.5, BD: 6, AE: 4, KW: 3, SA: 3, UK: 0, US: -5, AU: 10 };
const rand = <T>(a: T[]): T => a[Math.floor(Math.random() * a.length)];

/** Real-person portrait, gender-matched (randomuser.me — keyless, 100 photos each).
 *  `idx` 0–99 spread by the running counter so repeats are minimised.
 *  NOTE: keyless real photos can't be filtered by ethnicity, so faces are a global
 *  mix; for true region-matched real photos use a curated R2 avatar pool. */
function avatar(idx: number, female: boolean): string {
  const n = ((idx % 100) + 100) % 100;
  return female
    ? `https://randomuser.me/api/portraits/women/${n}.jpg`
    : `https://randomuser.me/api/portraits/men/${n}.jpg`;
}

async function main() {
  const desiredKeys: string[] = [];
  let created = 0, updated = 0, n = 0, females = 0;

  for (const [cc, c] of Object.entries(COUNTRIES)) {
    for (let i = 0; i < c.count; i++) {
      n++;
      const botKey = `${cc.toLowerCase()}-${String(i + 1).padStart(3, '0')}`;
      desiredKeys.push(botKey);

      // ~5% female, deterministic by position.
      const female = n % 20 === 0;
      if (female) females++;
      const first = female ? rand(c.femaleFirst) : rand(c.maleFirst);
      const displayName = `${first} ${rand(c.last)}`;
      // Stable + guaranteed-unique (botKey is unique): e.g. "bilal.pk001".
      const username = `${first.toLowerCase().replace(/[^a-z]/g, '')}.${cc.toLowerCase()}${String(i + 1).padStart(3, '0')}`;
      const city = rand(c.cities);
      // Spread photo indices: males 0-99 by male-sequence, females by female-sequence.
      const photoUrl = avatar(female ? females : n - females, female);

      // Spread start hours evenly around the clock (13 is coprime with 24) and use
      // a WIDE 14-hour window so ~55-60% of bots are awake at ANY UTC hour — the
      // feed never feels dead. (Per-bot still has day/night variation.)
      const start = (n * 13) % 24;
      const end = (start + 14) % 24;

      const timezone = 'Asia/Karachi';

      const existing = await prisma.user.findUnique({ where: { botKey }, select: { id: true } });
      await prisma.user.upsert({
        where: { botKey },
        create: {
          authProvider: 'bot', authProviderId: botKey, botKey, isBot: true,
          email: `bot+${botKey}@pigeonfly.internal`,
          displayName, username, photoUrl, countryCode: cc, city,
          timezone,
          languageCode: cc === 'PK' ? 'ur' : cc === 'BD' ? 'bn' : cc === 'IN' ? 'hi' : ['AE', 'SA', 'KW'].includes(cc) ? 'ar' : 'en',
          activeStartHour: start, activeEndHour: end,
          deletedAt: null,
        },
        update: { displayName, username, photoUrl, city, countryCode: cc, timezone, activeStartHour: start, activeEndHour: end, deletedAt: null },
      });
      existing ? updated++ : created++;
    }
  }

  // Retire bots no longer in the set (soft-delete so they drop from roster + engine; posts kept).
  const retired = await prisma.user.updateMany({
    where: { isBot: true, deletedAt: null, botKey: { notIn: desiredKeys } },
    data: { deletedAt: new Date() },
  });

  const total = created + updated;
  console.log(
    `Bot roster seeded: ${created} created, ${updated} updated, ${total} active ` +
    `(${females} female ≈ ${Math.round((females / total) * 100)}%), ${retired.count} retired.`,
  );
  await prisma.$disconnect();
}

main().catch(async (e) => {
  console.error('Bot seed failed:', e);
  await prisma.$disconnect();
  process.exit(1);
});
