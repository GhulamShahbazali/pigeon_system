'use client';

import { Fragment, useState } from 'react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useApi } from '@/lib/bots';
import {
  Tournaments,
  type TournamentDetail,
  type ParticipantRow,
  type ParticipantDetail,
} from '@/lib/tournaments';

function fmtDate(iso: string): string {
  const d = new Date(iso);
  return Number.isNaN(d.getTime())
    ? '—'
    : d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
}
function fmtTime(iso: string): string {
  const d = new Date(iso);
  return Number.isNaN(d.getTime())
    ? '—'
    : d.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });
}
/** Endurance durations are long (hours); show h/m, or m/s when under an hour. */
function fmtDur(s: number | null): string {
  if (s == null) return '—';
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = Math.floor(s % 60);
  return h > 0 ? `${h}h ${m}m` : `${m}m ${sec}s`;
}

function StatusPill({ t }: { t: TournamentDetail }) {
  if (t.is_live) return <span className="pill amber">● Live</span>;
  if (t.status === 'completed') return <span className="pill off">Completed</span>;
  return <span className="pill brand">Active</span>;
}

export default function TournamentDetailPage() {
  const params = useParams();
  const id = String(params.id);
  const router = useRouter();

  const det = useApi<TournamentDetail>(() => Tournaments.get(id), [id]);
  const std = useApi<ParticipantRow[]>(() => Tournaments.standings(id), [id]);

  const [openPid, setOpenPid] = useState<string | null>(null);
  const [pdetails, setPdetails] = useState<Record<string, ParticipantDetail>>({});
  const [loadingPid, setLoadingPid] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);

  async function toggleParticipant(pid: string) {
    if (openPid === pid) {
      setOpenPid(null);
      return;
    }
    setOpenPid(pid);
    if (!pdetails[pid]) {
      setLoadingPid(pid);
      try {
        const d = await Tournaments.participant(id, pid);
        setPdetails((m) => ({ ...m, [pid]: d }));
      } catch {
        /* surfaced as "no detail" below */
      } finally {
        setLoadingPid(null);
      }
    }
  }

  async function remove() {
    const t = det.data;
    if (!t) return;
    if (!window.confirm(`Delete “${t.title}”? This removes it from the app (soft-delete).`)) return;
    setDeleting(true);
    try {
      await Tournaments.remove(id);
      router.push('/tournaments');
    } finally {
      setDeleting(false);
    }
  }

  const t = det.data;
  const rows = std.data ?? [];

  return (
    <>
      <div style={{ marginBottom: 14 }}>
        <Link href="/tournaments" className="muted" style={{ fontWeight: 700 }}>← Tournaments</Link>
      </div>

      {det.error && <div className="err">⚠ {det.error} — if this is 401/403, sign out and log in again.</div>}

      {det.loading || !t ? (
        <p className="muted">Loading…</p>
      ) : (
        <>
          {/* header */}
          <div className="card" style={{ display: 'flex', gap: 18, alignItems: 'flex-start', marginBottom: 16 }}>
            {t.cover_url && (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={t.cover_url}
                alt=""
                style={{ width: 120, height: 84, objectFit: 'cover', borderRadius: 12, flexShrink: 0 }}
              />
            )}
            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
                <h1 style={{ fontSize: 20, fontWeight: 800, letterSpacing: '-.02em' }}>{t.title}</h1>
                <StatusPill t={t} />
              </div>
              <p className="muted" style={{ marginTop: 6 }}>
                {t.organizer ? `by @${t.organizer.username}` : 'by —'}
                {t.organizer_contact ? ` · ☎ ${t.organizer_contact}` : ''}
                {` · created ${fmtDate(t.created_at)}`}
              </p>
              {t.description && <p className="muted" style={{ marginTop: 8 }}>{t.description}</p>}
            </div>
            <button
              className="btn ghost sm"
              disabled={deleting}
              style={{ color: 'var(--danger)', borderColor: '#f6cbc7' }}
              onClick={remove}
            >
              {deleting ? '…' : 'Delete'}
            </button>
          </div>

          {/* stats */}
          <div className="grid g4" style={{ marginBottom: 20 }}>
            <div className="stat"><div className="k">Days</div><div className="v num">{t.num_days}</div></div>
            <div className="stat"><div className="k">Pigeons / loft</div><div className="v num">{t.pigeon_count}</div></div>
            <div className="stat"><div className="k">Followers</div><div className="v num">{t.follower_count}</div></div>
            <div className="stat">
              <div className="k">Overall avg</div>
              <div className="v num">{fmtDur(t.overall_avg_seconds)}</div>
            </div>
          </div>

          {/* standings */}
          <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
            <div style={{ padding: '14px 18px', borderBottom: '1px solid var(--line)' }}>
              <h3 style={{ margin: 0 }}>Standings · {rows.length} participant(s)</h3>
            </div>
            {std.loading ? (
              <p className="muted" style={{ padding: 18 }}>Loading standings…</p>
            ) : (
              <table className="tbl">
                <thead>
                  <tr>
                    <th className="num" style={{ width: 54 }}>Pos</th>
                    <th>Loft</th>
                    <th className="num">Returned</th>
                    <th className="num">Overall avg</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((p) => {
                    const open = openPid === p.id;
                    const pd = pdetails[p.id];
                    return (
                      <Fragment key={p.id}>
                        <tr style={{ cursor: 'pointer' }} onClick={() => toggleParticipant(p.id)}>
                          <td className="num"><b>{p.position ?? '—'}</b></td>
                          <td>
                            <div className="who">
                              <div
                                className="ava"
                                style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, color: 'var(--brand-ink)' }}
                              >
                                {(p.name || '?').charAt(0).toUpperCase()}
                              </div>
                              <div><b>{p.name}</b></div>
                            </div>
                          </td>
                          <td className="num">{p.overall_returned_count}</td>
                          <td className="num">{fmtDur(p.overall_avg_seconds)}</td>
                          <td className="muted" style={{ textAlign: 'right' }}>{open ? '▲' : '▼'}</td>
                        </tr>
                        {open && (
                          <tr>
                            <td colSpan={5} style={{ background: 'var(--soft)' }}>
                              {loadingPid === p.id && !pd ? (
                                <span className="muted">Loading flights…</span>
                              ) : !pd || pd.days.length === 0 ? (
                                <span className="muted">No flights recorded yet.</span>
                              ) : (
                                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                                  {pd.days.map((d) => (
                                    <div key={d.day_id}>
                                      <div style={{ fontWeight: 700, fontSize: 12.5, marginBottom: 4 }}>
                                        Day {d.day_number} · {fmtDate(d.date)}
                                        <span className="muted" style={{ fontWeight: 500 }}>
                                          {'  '}· {d.returned_count} returned · avg {fmtDur(d.avg_seconds)}
                                        </span>
                                      </div>
                                      {d.flights.length === 0 ? (
                                        <span className="muted" style={{ fontSize: 12.5 }}>— no landings —</span>
                                      ) : (
                                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                                          {d.flights.map((f) => (
                                            <span key={f.id} className="pill brand" style={{ fontWeight: 600 }}>
                                              {f.pigeon_name} · {fmtTime(f.landing_time)} · {fmtDur(f.duration_seconds)}
                                            </span>
                                          ))}
                                        </div>
                                      )}
                                    </div>
                                  ))}
                                </div>
                              )}
                            </td>
                          </tr>
                        )}
                      </Fragment>
                    );
                  })}
                  {rows.length === 0 && (
                    <tr>
                      <td colSpan={5} className="muted" style={{ textAlign: 'center', padding: 28 }}>
                        No participants yet.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            )}
          </div>
        </>
      )}
    </>
  );
}
