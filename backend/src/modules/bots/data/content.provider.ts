import { Injectable } from '@nestjs/common';
import { BotPost, BotRecord, BotTournament, IContentProvider } from '../domain/content-provider.port';

const PIGEON_NAMES = [
  'Shaheen', 'Sheru', 'Chotu', 'Badal', 'Toofan', 'Raja', 'Noori', 'Heera', 'Billa', 'Kala',
  'Teetar', 'Baaz', 'Shahbaz', 'Gulab', 'Moti', 'Tara', 'Bijli', 'Sultan', 'Rani', 'Chand',
];

const rand = <T>(a: T[]): T => a[Math.floor(Math.random() * a.length)];
const lock = () => Math.floor(Math.random() * 100000);

/** Keyless, topical images via LoremFlickr (Flickr by tag). `lock` keeps a URL stable. */
const img = (tags: string, w = 800, h = 600) =>
  `https://loremflickr.com/${w}/${h}/${tags}?lock=${lock()}`;

const CAPTIONS = [
  'Morning toss done — birds looked sharp today 🕊️',
  'New kit settling in nicely. Form is building for the season.',
  'That young blue hen is turning into a real racer MashaAllah.',
  'Loft cleaned, feed dialled in. Race week discipline 💪',
  'Sunset training fly — this is why we love the sport.',
  'Fresh ring numbers in. Who else is prepping for the derby?',
  'Homed in strong headwind today. Proud of this team.',
  '400km race this weekend — duaon mein yaad rakhna 🤲',
  'Perfect trap today, every bird in under a minute.',
  'Breeding pair of the year. Bloodline is everything.',
  'Clear sky, light wind — ideal toss conditions.',
  'Patience + good feed + clean water = winning birds.',
  'Velvet cock back first again. Consistency is key.',
  'Young bird training going well, loft full of energy.',
  'Race basket packed. May the fastest home birds win 🏁',
];

const POST_TAGS = ['pigeon', 'pigeon,loft', 'racing,pigeon', 'pigeon,sky', 'dove,bird', 'pigeon,flock'];
const COVER_TAGS = ['pigeon,sky', 'racing,pigeon', 'pigeon,flight', 'bird,sky'];

const TITLE_PREFIX = ['Valley', 'Royal', 'Falcon', 'Shaheen', 'Desert', 'Coastal', 'National', 'Champions', 'Golden', 'City'];
const TITLE_SUFFIX = ['Cup', 'Open', 'Derby', 'Classic', 'Championship', 'Race', 'Challenge', 'Trophy'];

const PIGEON_COUNTS = [1, 3, 5, 7, 9, 11, 15, 20];

/** City pools per racing country. */
const COUNTRIES: Record<string, { cities: string[]; names: string[] }> = {
  PK: { cities: ['Lahore', 'Karachi', 'Faisalabad', 'Rawalpindi', 'Multan', 'Gujranwala'], names: ['Bilal Raza', 'Kashif Ali', 'Sohail Ahmed', 'Usman Tariq', 'Imran Shah', 'Adnan Butt'] },
  IN: { cities: ['Mumbai', 'Delhi', 'Hyderabad', 'Chennai', 'Kolkata', 'Pune'], names: ['Rohan Mehta', 'Arjun Nair', 'Vikram Rao', 'Imraan Khan', 'Sanjay Patel', 'Deepak Verma'] },
  BD: { cities: ['Dhaka', 'Chittagong', 'Khulna', 'Sylhet', 'Rajshahi'], names: ['Rakib Hasan', 'Tanvir Islam', 'Shakil Ahmed', 'Nahid Rahman', 'Jubayer Alam'] },
  AE: { cities: ['Dubai', 'Abu Dhabi', 'Sharjah', 'Al Ain'], names: ['Khalid Al Mansoori', 'Omar Saeed', 'Rashid Al Nuaimi', 'Yousef Hamdan'] },
  KW: { cities: ['Kuwait City', 'Hawalli', 'Salmiya', 'Jahra'], names: ['Fahad Al Sabah', 'Nasser Al Rashidi', 'Bader Al Otaibi'] },
  SA: { cities: ['Riyadh', 'Jeddah', 'Dammam', 'Mecca'], names: ['Saud Al Qahtani', 'Turki Al Harbi', 'Majed Al Dossari'] },
  UK: { cities: ['London', 'Manchester', 'Birmingham', 'Glasgow', 'Leeds'], names: ['James Carter', 'David Hughes', 'Mohammed Patel', 'Liam Walsh', 'Ryan Scott'] },
  US: { cities: ['New York', 'Chicago', 'Houston', 'Los Angeles', 'Atlanta'], names: ['Mike Anderson', 'Carlos Rivera', 'Tyrone Brooks', 'Kevin Doyle'] },
  AU: { cities: ['Sydney', 'Melbourne', 'Brisbane', 'Perth'], names: ['Jack Thompson', 'Nathan Lee', 'Daniel Cross'] },
};
const COUNTRY_CODES = Object.keys(COUNTRIES);

@Injectable()
export class ContentProvider implements IContentProvider {
  pickPost(): BotPost {
    return { caption: rand(CAPTIONS), imageUrl: img(rand(POST_TAGS)) };
  }

  pickTournament(): BotTournament {
    const cc = rand(COUNTRY_CODES);
    const c = COUNTRIES[cc];
    const city = rand(c.cities);
    const title = `${rand(TITLE_PREFIX)} ${rand(TITLE_SUFFIX)} ${new Date().getFullYear()}`;
    const pigeonCount = rand(PIGEON_COUNTS);
    // Mostly every_day; sometimes alternate_days — like real clubs.
    const scheduleType: 'every_day' | 'alternate_days' = Math.random() < 0.75 ? 'every_day' : 'alternate_days';
    const nParticipants = 3 + Math.floor(Math.random() * 6); // 3–8
    const participantNames = [...c.names].sort(() => Math.random() - 0.5).slice(0, nParticipants);
    const numDays = rand([1, 3, 5, 7]);
    return {
      title,
      pigeonCount,
      scheduleType,
      city,
      countryCode: cc,
      coverUrl: img(rand(COVER_TAGS), 1200, 600),
      flyTime: rand(['05:30', '06:00', '06:30', '07:00']),
      endTime: rand(['17:00', '18:00', '18:30', '19:00']),
      numDays,
      organizerContact: '+000000000000',
      participantNames,
    };
  }

  pickRecord(): BotRecord {
    const totalPigeons = rand([3, 5, 7, 9, 11]);
    return {
      flyTime: rand(['05:30', '06:00', '06:30', '07:00']),
      totalPigeons,
      pigeonNames: this.pigeonNames(totalPigeons),
    };
  }

  pigeonNames(n: number): string[] {
    return [...PIGEON_NAMES].sort(() => Math.random() - 0.5).slice(0, Math.min(n, PIGEON_NAMES.length));
  }

  pools() {
    return {
      captions: CAPTIONS.length,
      postImages: POST_TAGS.length,
      tournamentTitles: TITLE_PREFIX.length * TITLE_SUFFIX.length,
      cities: Object.values(COUNTRIES).reduce((n, c) => n + c.cities.length, 0),
      countries: COUNTRY_CODES,
      pigeonCounts: PIGEON_COUNTS,
    };
  }
}

/** Country/city/name pools shared with the roster seed script. */
export const BOT_COUNTRIES = COUNTRIES;
export const BOT_COUNTRY_CODES = COUNTRY_CODES;
