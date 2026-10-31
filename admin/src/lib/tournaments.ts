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

export const Tournaments = {
  // Public browse endpoint (superadmin session token works); backend caps limit at 50.
  list: (tab: TournamentTab, limit = 50) =>
    api.get<TournamentCard[]>(`/tournaments?tab=${tab}&limit=${limit}`),
  // SuperAdmin override — soft-delete any tournament (DELETE /admin/tournaments/:id).
  remove: (id: string) => api.del(`/admin/tournaments/${id}`),
};
