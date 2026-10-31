'use client';

import { useState } from 'react';
import { useApi } from '@/lib/bots';
import { Tournaments, type TournamentCard, type TournamentTab } from '@/lib/tournaments';

const TABS: { key: TournamentTab; label: string }[] = [
  { key: 'all', label: 'All' },
  { key: 'ongoing', label: 'Ongoing' },
  { key: 'upcoming', label: 'Upcoming' },
  { key: 'past', label: 'Past' },
];

function fmtDate(iso: string): string {
  const d = new Date(iso);
  return Number.isNaN(d.getTime())
    ? '—'
    : d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
}

function StatusPill({ t }: { t: TournamentCard }) {
  if (t.is_live) return <span className="pill amber">● Live</span>;
  if (t.status === 'completed') return <span className="pill off">Completed</span>;
  return <span className="pill brand">Active</span>;
}

export default function TournamentsPage() {
  const [tab, setTab] = useState<TournamentTab>('all');
  const { data, error, loading } = useApi<TournamentCard[]>(() => Tournaments.list(tab, 50), [tab]);
  const rows = data ?? [];

  return (
    <>
      <div className="pagehead">
        <div>
          <h1>Tournaments</h1>
          <p>Every tournament on the platform — live status, organizer and engagement.</p>
        </div>
      </div>

      <div className="tabs">
        {TABS.map((t) => (
          <button key={t.key} className={`tab ${tab === t.key ? 'on' : ''}`} onClick={() => setTab(t.key)}>
            {t.label}
          </button>
        ))}
      </div>

      {error && <div className="err">⚠ {error} — if this is 401/403, sign out and log in again.</div>}

      {loading ? (
        <p className="muted">Loading…</p>
      ) : (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <table className="tbl">
            <thead>
              <tr>
                <th>Tournament</th>
                <th>Organizer</th>
                <th>Status</th>
                <th className="num">Days</th>
                <th className="num">Pigeons</th>
                <th className="num">Followers</th>
                <th className="num">Likes</th>
                <th className="num">Views</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((t) => (
                <tr key={t.id}>
                  <td>
                    <div className="who">
                      {t.cover_url ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img className="ava" src={t.cover_url} alt="" style={{ borderRadius: 9 }} />
                      ) : (
                        <div className="ava" style={{ borderRadius: 9 }} />
                      )}
                      <div>
                        <b>{t.title}</b>
                        <span>{t.schedule_type === 'alternate_days' ? 'Alternate days' : 'Every day'}</span>
                      </div>
                    </div>
                  </td>
                  <td className="muted">{t.organizer ? `@${t.organizer.username}` : '—'}</td>
                  <td><StatusPill t={t} /></td>
                  <td className="num">{t.num_days}</td>
                  <td className="num">{t.pigeon_count}</td>
                  <td className="num">{t.follower_count}</td>
                  <td className="num">{t.like_count}</td>
                  <td className="num">{t.view_count}</td>
                  <td className="muted num">{fmtDate(t.created_at)}</td>
                </tr>
              ))}
              {rows.length === 0 && (
                <tr>
                  <td colSpan={9} className="muted" style={{ textAlign: 'center', padding: 28 }}>
                    No tournaments in “{tab}”.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
      {rows.length === 50 && (
        <p className="muted" style={{ marginTop: 12 }}>Showing the most recent 50.</p>
      )}
    </>
  );
}
