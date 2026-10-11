export interface BotPost {
  caption: string;
  imageUrl: string;
}

export interface BotTournament {
  title: string;
  pigeonCount: number;      // one of {1,3,5,7,9,11,15,20} — max pigeons per participant
  scheduleType: 'every_day' | 'alternate_days';
  city: string;
  countryCode: string;      // ISO 3166-1 alpha-2
  coverUrl: string;
  flyTime: string;          // "HH:MM" 24h
  endTime: string;          // "HH:MM" 24h — results cut-off
  numDays: number;
  organizerContact: string;
  participantNames: string[];
}

export interface BotRecord {
  flyTime: string;        // "HH:MM"
  totalPigeons: number;
  pigeonNames: string[];  // names for the pigeons that return
}

/** Supplies bot content. Template/URL pools now; an AI provider can implement
 *  the same port later (admin-switchable). */
export interface IContentProvider {
  pickPost(): BotPost;
  pickTournament(): BotTournament;
  pickRecord(): BotRecord;
  /** N believable pigeon names (for tournament flights). */
  pigeonNames(n: number): string[];
  /** The pools, for the admin Content tab (read-only view). */
  pools(): {
    captions: number;
    postImages: number;
    tournamentTitles: number;
    cities: number;
    countries: string[];
    pigeonCounts: number[];
  };
}
