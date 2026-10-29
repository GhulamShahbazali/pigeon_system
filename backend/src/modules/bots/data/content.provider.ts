import { Injectable } from '@nestjs/common';
import { BotPost, BotRecord, BotTournament, IContentProvider } from '../domain/content-provider.port';

const PIGEON_NAMES = [
  'Shaheen', 'Sheru', 'Chotu', 'Badal', 'Toofan', 'Raja', 'Noori', 'Heera', 'Billa', 'Kala',
  'Teetar', 'Baaz', 'Shahbaz', 'Gulab', 'Moti', 'Tara', 'Bijli', 'Sultan', 'Rani', 'Chand',
];

const rand = <T>(a: T[]): T => a[Math.floor(Math.random() * a.length)];

/**
 * DESI (height / high-flyer) kabootar photos — the app's MAIN breed (kabootar
 * baazi), so these should dominate the feed (~95% of photo posts + most covers).
 *
 * Unsplash has almost no South-Asian high-flyer shots, so this pool is meant to
 * be filled with YOUR OWN stable image URLs — e.g. your Cloudflare R2 bucket, or
 * any public https image. Each entry may be a full `https://…` URL OR a bare
 * Unsplash photo id (`1534…-73cf…`). While this list is empty the feed falls
 * back to the generic/racing pool below, so nothing ever breaks.
 *
 *   const DESI_PHOTO_URLS = [
 *     'https://<your-r2-public-host>/desi/highflyer-01.jpg',
 *     'https://<your-r2-public-host>/desi/golden-teeli-02.jpg',
 *   ];
 */
const DESI_PHOTO_URLS: string[] = [
  // ← paste 4–8 desi high-flyer image URLs here
];

/**
 * Generic / racing-homer pigeon photos (Unsplash CDN, keyless, stable; each id
 * was visually verified to show a real pigeon). Kept deliberately as the MINOR
 * share — racing is only ~2–4% of the feed — and as the safe fallback for desi.
 */
const RACING_PHOTO_IDS = [
  '1534695941753-73cf13435eb4', '1641144355850-e7991d050bdc', '1513099335611-0fd3bca7131c',
  '1592964377969-dc564e4c1599', '1514446194108-aa408d4d61d9', '1742659722918-e925e7877725',
  '1723302641915-ad18f40f2203', '1611172444539-823c575d298e', '1518157770830-df40b281672e',
  '1540382658444-5f53c7f12ac3', '1679243984878-b836be465a37', '1607417190565-630353c3d223',
  '1554226114-04bd78f87c24', '1697989120456-5fb3b24749fb', '1692652966645-d05118429bbd',
];

// Pigeon-medicine / pills photos for medicine-themed posts. Full URLs or bare
// Unsplash ids (confirm on device; any that don't load fall back to the post's
// text + the app's image error placeholder).
const MEDICINE_PHOTO_IDS = [
  '1584308666744-24d5c474f2ae', '1587854692152-cbe660dbde88', '1550572017-edd951aa8f7f',
  '1631549916768-4119b2e514cd', '1471864190281-a93a3070b6de', '1583947215259-38e31be8751f',
];

// Share of NON-medicine photo posts that use a racing shot (the rest are desi).
// Keeps racing in the 2–4% band the product wants. Only applied once DESI_PHOTO_URLS
// is populated — until then desi falls back to the racing pool anyway.
const RACING_SHARE = 0.03;

/** Direct Unsplash CDN image, resized/cropped server-side. */
const img = (id: string, w = 800, h = 600) =>
  `https://images.unsplash.com/photo-${id}?auto=format&fit=crop&w=${w}&h=${h}&q=70`;

/** Accept either a full https URL (served as-is) or a bare Unsplash id. */
const resolve = (idOrUrl: string, w = 800, h = 600) =>
  idOrUrl.startsWith('http') ? idOrUrl : img(idOrUrl, w, h);

/** Medicine/health captions lead with a pill/health emoji or name a med. */
const isMedicineCaption = (c: string): boolean =>
  /💊|🧪|🧄|🌿|Ronidazole|Ivermectin|Levamisole|Tylosin|Doxycycline|Amprolium|Metronidazole|دوا|العلاج/i.test(c);

const postImageFor = (caption: string) => {
  if (isMedicineCaption(caption)) return resolve(rand(MEDICINE_PHOTO_IDS));
  // Desi dominates; racing appears only ~RACING_SHARE of the time. When the desi
  // pool is empty we fall back to the racing pool so the feed still shows photos.
  const hasDesi = DESI_PHOTO_URLS.length > 0;
  const useRacing = !hasDesi || Math.random() < RACING_SHARE;
  return resolve(rand(useRacing ? RACING_PHOTO_IDS : DESI_PHOTO_URLS));
};
const coverImage = () => {
  const pool = DESI_PHOTO_URLS.length ? DESI_PHOTO_URLS : RACING_PHOTO_IDS;
  return resolve(rand(pool), 1200, 600);
};

// Multilingual pigeon posts — each has its own topic/"title" lead so no two read
// the same. English, Urdu (script + roman) and Arabic. Topics are strictly pigeon:
// medicine (named meds), feed, health, racing, breeding, desi/high-flyer/low-flyer.
// Every entry is unique; pickPost() also avoids repeating the last several captions.
const CAPTIONS = [
  // ── Medicine / health (named meds — believable kabootar baazi guidance) ──
  '💊 Canker (zakham) se bachao: har 3 hafte Ronidazole ka course zaroori hai. Ignore mat karo.',
  '💊 Worms ke liye mahine mein ek baar Ivermectin ya Levamisole — andar ka parasite speed kha jata hai.',
  '💊 Respiratory infection? Tylosin + Doxycycline ka 5-din course, phir probiotic se gut recover karao.',
  '💊 Coccidiosis ke liye ESB3 / Amprolium — garmi mein paani zyada ganda hota hai, ehtiyat lazmi.',
  '💊 Race week pe electrolytes + glucose paani mein. Dehydration sab se bara dushman hai.',
  '💊 Paika / canker ki pehchan: moun mein zard dana. Foran Metronidazole do, dusron se alag rakho.',
  '🧪 Multivitamin + B-complex hafte mein 2 din — feather aur stamina dono behtar.',
  '🧄 Qudrati nuskha: lehsun (garlic) + sfesh (apple cider vinegar) paani mein, immunity ka kaam karta hai.',
  '🌿 Oregano oil aur probiotic — antibiotic ke baad gut flora wapas, bina inke birds susti dikhate hain.',
  'Pigeon health tip: calcium + grit box hamesha loft mein rakho. Haddi aur egg-shell mazboot.',
  'Health first — بیمار کبوتر کو فوراً الگ کریں، باقی ریوڑ کو کینکر اور کرم کی دوائی دیں۔',
  'دواؤں کا شیڈول: ہر مہینے کرم کش، ہر 3 ہفتے کینکر، ریس سے پہلے ملٹی وٹامن اور الیکٹرولائٹس۔',
  'الوقاية خير من العلاج: جرعة ديدان شهرية، وعلاج الكنكر كل ثلاثة أسابيع، وفيتامينات قبل السباق.',
  // ── Feed / loft ──
  '🌾 Race mix: 40% barley, jo, maash, bajra + thora oil seed. Energy slow-release milti hai.',
  '🌾 Moulting season mein protein barhao — sunflower aur high-protein pellets, naye par jaldi aate hain.',
  'Loft saaf, hawadar aur sukha — 70% bimariyan sirf gandi loft se aati hain. Roz safai.',
  'لوفٹ کی صفائی مکمل، خوراک سیٹ — ریس ویک کا ڈسپلن شروع 💪',
  'العلف المتوازن سر البطولة: شعير، ذرة، وبذور زيتية مع حصى ومعادن.',
  // ── Racing / toss ──
  '🕊️ Subah ki toss zabardast rahi — poora kit sharp aur tight udta raha.',
  '🏁 400km race is weekend. Birds basket mein, dua mein yaad rakhna 🤲',
  '🏆 Aaj Chotu sab se pehle wapas aaya, MashaAllah — 1180 mpm ki speed!',
  'تیز ہوا کے خلاف آج زبردست واپسی، ٹیم پر فخر ہے 🕊️',
  'سباق ٤٠٠ كم نهاية الأسبوع، بالتوفيق للجميع 🏁',
  // ── Breeding / bloodline ──
  '🥚 Breeding jori of the year set ho gayi — bloodline hi asal daulat hai.',
  'Janglor x Teddy cross ke squeakers — ummeed hai is season ke champion yahi hon.',
  'نئی نسل تیار ہو رہی ہے ماشاءاللہ، والدین کی لائن شاندار ہے۔',
  // ── Desi pigeons (kabootar baazi — teeli, golden, madras) ──
  '🇵🇰 Desi kabootar ka apna maza hai — teeli, golden, madras. Asli shauq wale samajhte hain.',
  'Desi baazi: aaj chhat pe 45 minute ka uraan, poora ghola ek saath — dil khush ho gaya.',
  'دیسی کبوتر بازی کا الگ ہی نشہ ہے — ٹیڈی، گولڈن، لکھے — صبح کی اُڑان لاجواب۔',
  // ── High flyer ──
  '🔝 High flyer kit aaj 3 ghante 20 minute asman pe — buland parwaz, nazar se ojhal!',
  'High flyers ke liye light feed aur sabr — jitna halka pet, utni oonchi aur lambi uraan.',
  'عالي الطيران حلّق أكثر من ٣ ساعات اليوم — قمة اللياقة والتحمل.',
  // ── Low flyer / homer ──
  '⏱️ Low flyer homer ki baat alag — speed aur direction, seedha loft wapas. Racing ki jaan.',
  'Low flyer training: short tosses rozana barhao, bird distance aur homing dono seekhta hai.',
];

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
  /** Last few captions handed out, so the feed never shows the same text twice in a row. */
  private readonly recentCaptions: string[] = [];

  pickPost(): BotPost {
    // Pick a caption that isn't one of the last few used (avoids the "same post
    // twice" problem). Falls back after a few tries if the pool is tiny.
    let caption = rand(CAPTIONS);
    for (let i = 0; i < 6 && this.recentCaptions.includes(caption); i++) caption = rand(CAPTIONS);
    this.recentCaptions.push(caption);
    if (this.recentCaptions.length > Math.min(12, CAPTIONS.length - 1)) this.recentCaptions.shift();

    // ~70% of posts carry a photo, ~30% are text-only — mirrors a real feed and
    // reads better than every single post having an image.
    const withImage = Math.random() < 0.7;
    return { caption, imageUrl: withImage ? postImageFor(caption) : null };
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
      coverUrl: coverImage(),
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
      postImages: DESI_PHOTO_URLS.length + RACING_PHOTO_IDS.length + MEDICINE_PHOTO_IDS.length,
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
