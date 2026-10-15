'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { api } from './api';

// ── types (mirror backend snake_case — api/11-bots-admin.md) ──────────────────
export interface BotConfig {
  enabled: boolean;
  tickIntervalSec: number;
  gapWindowSec: number;
  postsPerMin: number;
  botPostCooldownMin: number;
  likesPerMin: number;
  newestBiasPct: number;
  maxBotLikesPerPost: number;
  viewsPerMin: number;
  viewBatchSize: number;
  followsPerMin: number;
  tournamentsPerDay: number;
  recordsPerDay: number;
}
export interface Overview {
  enabled: boolean;
  active_source: 'schedule' | 'manual';
  total_bots: number;
  awake_now: number;
  today: { posts: number; likes: number; views: number; follows: number; tournaments: number; records: number };
  live_records_now: number;
}
export interface RosterItem {
  id: string;
  display_name: string;
  username: string;
  photo_url: string | null;
  country_code: string | null;
  city: string | null;
  active_start_hour: number | null;
  active_end_hour: number | null;
  follower_count: number;
  awake_now: boolean;
}
export interface ContentPools {
  captions: number;
  postImages: number;
  tournamentTitles: number;
  cities: number;
  countries: string[];
  pigeonCounts: number[];
}

// ── a tiny fetch hook (no react-query dep) ────────────────────────────────────
export function useApi<T>(loader: () => Promise<T>, deps: unknown[] = []) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const loaderRef = useRef(loader);
  loaderRef.current = loader;

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setData(await loaderRef.current());
    } catch (e: any) {
      setError(e?.message ?? 'Request failed');
    } finally {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  useEffect(() => {
    void reload();
  }, [reload]);

  return { data, error, loading, reload };
}

// ── endpoints ─────────────────────────────────────────────────────────────────
export const Bots = {
  overview: () => api.get<Overview>('/admin/bots/overview'),
  config: () => api.get<BotConfig>('/admin/bots/config'),
  updateConfig: (patch: Partial<BotConfig>) => api.patch<BotConfig>('/admin/bots/config', patch),
  roster: (offset = 0, limit = 60) =>
    api.get<RosterItem[]>(`/admin/bots/roster?offset=${offset}&limit=${limit}`),
  setSource: (source: 'schedule' | 'manual') => api.post('/admin/bots/active-source', { source }),
  content: () => api.get<ContentPools>('/admin/bots/content'),
};
