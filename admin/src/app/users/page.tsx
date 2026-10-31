'use client';

import { useState } from 'react';
import { useApi } from '@/lib/bots';
import { Users, type AdminUser } from '@/lib/users';

const PAGE = 100;

function fmtDate(iso: string): string {
  const d = new Date(iso);
  return Number.isNaN(d.getTime())
    ? '—'
    : d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
}
function initial(u: AdminUser): string {
  return (u.display_name || u.username || '?').trim().charAt(0).toUpperCase();
}

export default function UsersPage() {
  const [q, setQ] = useState('');
  const [query, setQuery] = useState('');
  const { data, error, loading, reload } = useApi<AdminUser[]>(() => Users.list(query, 0, PAGE), [query]);
  const [busy, setBusy] = useState<string | null>(null);

  async function toggle(u: AdminUser) {
    setBusy(u.id);
    try {
      if (u.is_suspended) await Users.unsuspend(u.id);
      else await Users.suspend(u.id);
      await reload();
    } finally {
      setBusy(null);
    }
  }

  const rows = data ?? [];

  return (
    <>
      <div className="pagehead">
        <div>
          <h1>Users</h1>
          <p>Search accounts and suspend or restore access.</p>
        </div>
      </div>

      <form
        className="card"
        style={{ marginBottom: 18, display: 'flex', gap: 10 }}
        onSubmit={(e) => {
          e.preventDefault();
          setQuery(q.trim());
        }}
      >
        <input
          className="field"
          placeholder="Search by name or username…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
        <button className="btn" type="submit">Search</button>
        {query && (
          <button
            className="btn ghost"
            type="button"
            onClick={() => {
              setQ('');
              setQuery('');
            }}
          >
            Clear
          </button>
        )}
      </form>

      {error && <div className="err">⚠ {error} — if this is 401/403, sign out and log in again.</div>}

      {loading ? (
        <p className="muted">Loading…</p>
      ) : (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <table className="tbl">
            <thead>
              <tr>
                <th>User</th>
                <th>Email</th>
                <th>Joined</th>
                <th>Status</th>
                <th style={{ textAlign: 'right' }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((u) => (
                <tr key={u.id}>
                  <td>
                    <div className="who">
                      <div
                        className="ava"
                        style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, color: 'var(--brand-ink)' }}
                      >
                        {initial(u)}
                      </div>
                      <div>
                        <b>{u.display_name || 'Unnamed'}</b>
                        <span>@{u.username || '—'}</span>
                      </div>
                    </div>
                  </td>
                  <td className="muted">{u.email ?? '—'}</td>
                  <td className="muted num">{fmtDate(u.created_at)}</td>
                  <td>
                    {u.is_suspended ? (
                      <span className="pill off">Suspended</span>
                    ) : (
                      <span className="pill on"><i />Active</span>
                    )}
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <button
                      className={`btn sm ${u.is_suspended ? '' : 'ghost'}`}
                      disabled={busy === u.id}
                      onClick={() => toggle(u)}
                    >
                      {busy === u.id ? '…' : u.is_suspended ? 'Unsuspend' : 'Suspend'}
                    </button>
                  </td>
                </tr>
              ))}
              {rows.length === 0 && (
                <tr>
                  <td colSpan={5} className="muted" style={{ textAlign: 'center', padding: 28 }}>
                    {query ? `No users match “${query}”.` : 'No users yet.'}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
      {rows.length === PAGE && (
        <p className="muted" style={{ marginTop: 12 }}>
          Showing the first {PAGE}. Refine the search to narrow results.
        </p>
      )}
    </>
  );
}
