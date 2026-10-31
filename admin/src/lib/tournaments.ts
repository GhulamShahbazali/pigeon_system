'use client';

import { api } from './api';

export interface TournamentCard {
  id: string;
  title: string;
  cover_url: string | null;
  schedule_type: string;
  num_days: number;
  pigeon_count: number;
  status: string;
  is_live: boolean;
  like_count: number;
  view_count: number;
  follower_count: number;
  link_slug: string;
  organizer: { id: string; display_name: string; username: string; photo_url: string | null } | null;
  created_at: string;
}

export type TournamentTab = 'all' | 'ongoing' | 'upcoming' | 'past';

export interface TournamentDay {
  id: string;
  day_number: number;
  date: string;
}

export interface TournamentDetail extends TournamentCard {
  rules: string | null;
  description: string | null;
  organizer_contact: string | null;
  overall_avg_seconds: number | null;
  days: TournamentDay[];
}

export interface ParticipantRow {
  id: string;
  name: string;
  photo_url: string | null;
  position: number | null;
  overall_avg_seconds: number | null;
  overall_returned_count: number;
}

export interface Flight {
  id: string;
  pigeon_name: string;
  landing_time: string;
  duration_seconds: number;
}

export interface ParticipantDetail {
  participant: {
    id: string;
    name: string;
    photo_url: string | null;
    contact_no: string | null;
    phone: string | null;
    address: string | null;
    position: number | null;
    overall_avg_seconds: number | null;
    overall_returned_count: number;
  };
  days: {
    day_id: string;
    day_number: number;
    date: string;
    avg_seconds: number | null;
    returned_count: number;
    flights: Flight[];
  }[];
}

export const Tournaments = {
  // Public browse endpoint (superadmin session token works); backend caps limit at 50.
  list: (tab: TournamentTab, limit = 50) =>
    api.get<TournamentCard[]>(`/tournaments?tab=${tab}&limit=${limit}`),
  get: (id: string) => api.get<TournamentDetail>(`/tournaments/${id}`),
  standings: (id: string) => api.get<ParticipantRow[]>(`/tournaments/${id}/participants`),
  participant: (id: string, pid: string) =>
    api.get<ParticipantDetail>(`/tournaments/${id}/participants/${pid}`),
  // SuperAdmin override — edit cosmetic/contact fields only (T15).
  update: (id: string, patch: EditTournamentPatch) =>
    api.patch<{ id: string }>(`/admin/tournaments/${id}`, patch),
  // SuperAdmin override — soft-delete any tournament (DELETE /admin/tournaments/:id).
  remove: (id: string) => api.del(`/admin/tournaments/${id}`),
  // Create (organizer = the signed-in admin), via the normal create endpoint.
  create: (body: CreateTournamentBody) => api.post<{ id: string }>(`/tournaments`, body),
};

/** T15: only cosmetic/contact fields are editable. */
export interface EditTournamentPatch {
  title?: string;
  description?: string | null;
  rules?: string | null;
  cover_url?: string | null;
  organizer_contact?: string | null;
}

export interface CreateTournamentBody {
  title: string;
  description?: string;
  rules?: string;
  cover_url?: string;
  num_days: number;
  schedule_type: 'every_day' | 'alternate_days';
  pigeon_count: number;
  fly_time: string;
  end_time: string;
  start_date: string;
  organizer_contact?: string;
}
