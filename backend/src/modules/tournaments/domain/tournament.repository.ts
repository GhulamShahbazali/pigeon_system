export interface CreateTournamentInput {
  organizerId: string;
  title: string;
  rules?: string;
  description?: string;
  coverUrl?: string;
  numDays: number;
  scheduleType: 'every_day' | 'alternate_days';
  pigeonCount: number;
  flyTime: string; // HH:MM
  endTime: string; // HH:MM
  startDate: string; // YYYY-MM-DD
  organizerContact?: string;
}

export interface AddParticipantInput {
  tournamentId: string;
  name: string;
  photoUrl?: string;
  contactNo?: string;
  phone?: string;
  address?: string;
}

export interface RecordFlightInput {
  tournamentId: string;
  participantId: string;
  dayId: string;
  pigeonName: string;
  landingTime: Date;
  bypassDateCheck?: boolean;
}

export interface UpdateFlightInput {
  tournamentId: string;
  participantId: string;
  flightId: string;
  pigeonName?: string;
  landingTime?: Date;
}

export interface TournamentSummary {
  id: string;
  organizerId: string;
  pigeonCount: number;
  status: string;
}

export interface ITournamentRepository {
  create(input: CreateTournamentInput): Promise<string>; // returns id
  findSummary(id: string): Promise<TournamentSummary | null>;
  findDetail(id: string, viewerId: string): Promise<any | null>;
  list(
    tab: 'all' | 'following' | 'mine' | 'upcoming' | 'ongoing' | 'past',
    userId: string,
    cursor: string | null,
    limit: number,
  ): Promise<any[]>;
  byOrganizer(organizerId: string, viewerId: string, limit: number): Promise<any[]>;
  addParticipant(input: AddParticipantInput): Promise<any>;
  /** Atomic: cap-check + insert flight + recompute day/overall stats + positions. Throws PigeonCapExceededError. */
  recordFlight(input: RecordFlightInput): Promise<any>;
  updateFlight(input: UpdateFlightInput): Promise<any>;
  deleteFlight(tournamentId: string, participantId: string, flightId: string): Promise<void>;
  standings(tournamentId: string): Promise<any[]>;
  participantDays(tournamentId: string, participantId: string): Promise<any>;
  toggleFollow(tournamentId: string, userId: string, follow: boolean): Promise<void>;
  toggleLike(tournamentId: string, userId: string, like: boolean): Promise<void>;
  recordView(tournamentId: string, userId: string): Promise<void>;
}

export const TOURNAMENT_REPOSITORY = Symbol('TOURNAMENT_REPOSITORY');
