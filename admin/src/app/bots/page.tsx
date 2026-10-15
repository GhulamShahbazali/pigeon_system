'use client';

import { useState } from 'react';
import {
  Bots,
  useApi,
  type BotConfig,
  type ContentPools,
  type Overview,
  type RosterItem,
} from '@/lib/bots';

type Tab = 'overview' | 'roster' | 'config' | 'content';

export default function BotsPage() {
  const [tab, setTab] = useState<Tab>('overview');
  return (
    <>
      <div className="pagehead">
        <div>
          <h1>Bots / Liveness</h1>
          <p>Seed posts, likes, views, follows &amp; tournaments so the app feels alive.</p>
        </div>
      </div>
      <div className="tabs">
        {(['overview', 'roster', 'config', 'content'] as Tab[]).map((t) => (
          <button key={t} className={`tab ${tab === t ? 'on' : ''}`} onClick={() => setTab(t)}>
            {t[0].toUpperCase() + t.slice(1)}
          </button>
        ))}
      </div>
      {tab === 'overview' && <OverviewTab />}
      {tab === 'roster' && <RosterTab />}
      {tab === 'config' && <ConfigTab />}
      {tab === 'content' && <ContentTab />}
    </>
  );
}

function ErrBox({ msg }: { msg: string }) {
  return <div className="err">⚠ {msg} — if this is 401/403, sign out and paste a valid SuperAdmin token.</div>;
}

// ── Overview ──────────────────────────────────────────────────────────────────
function OverviewTab() {
  const { data, error, loading, reload } = useApi<Overview>(() => Bots.overview());
  const [busy, setBusy] = useState(false);

  async function toggleEnabled() {
    if (!data) return;
    setBusy(true);
    try {
      await Bots.updateConfig({ enabled: !data.enabled });
      await reload();
    } finally {
      setBusy(false);
    }
  }
  async function setSource(source: 'schedule' | 'manual') {
    setBusy(true);
    try {
      await Bots.setSource(source);
      await reload();
    } finally {
      setBusy(false);
    }
  }

  if (error) return <ErrBox msg={error} />;
  if (loading || !data) return <p className="muted">Loading…</p>;

  return (
    <>
      <div className="card" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
        <div>
          <h3 style={{ marginBottom: 4 }}>Engine {data.enabled ? 'running' : 'stopped'}</h3>
          <span className="muted">Kill-switch — takes effect within one tick, no redeploy.</span>
        </div>
        <button className={`toggle ${data.enabled ? '' : 'off'}`} disabled={busy} onClick={toggleEnabled} aria-label="toggle engine" />
      </div>

      <div className="card" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
        <div>
          <h3 style={{ marginBottom: 4 }}>Active source</h3>
          <span className="muted">Schedule = per-bot UTC windows · Manual = a picked set.</span>
        </div>
        <div className="seg">
          <button className={data.active_source === 'schedule' ? 'on' : ''} disabled={busy} onClick={() => setSource('schedule')}>Schedule</button>
          <button className={data.active_source === 'manual' ? 'on' : ''} disabled={busy} onClick={() => setSource('manual')}>Manual</button>
        </div>
      </div>

      <div className="grid g4" style={{ marginBottom: 16 }}>
        <Stat k="Total bots" v={data.total_bots} />
        <Stat k="Awake now" v={data.awake_now} />
        <Stat k="Status" v={data.enabled ? 'Live' : 'Off'} />
        <Stat k="Source" v={data.active_source} />
      </div>
      <h3 style={{ margin: '6px 2px 12px', fontSize: 13, color: 'var(--sub)', fontWeight: 800, letterSpacing: '.06em', textTransform: 'uppercase' }}>Today (UTC)</h3>
      <div className="grid g4">
        <Stat k="Posts" v={data.today.posts} />
        <Stat k="Likes" v={data.today.likes} />
        <Stat k="Views" v={data.today.views} />
        <Stat k="Follows" v={data.today.follows} />
      </div>
      <div className="grid g4" style={{ marginTop: 16 }}>
        <Stat k="Tournaments" v={data.today.tournaments} />
        <Stat k="Records" v={data.today.records} />
        <Stat k="Live now" v={data.live_records_now} />
      </div>
    </>
  );
}

function Stat({ k, v }: { k: string; v: number | string }) {
  return (
    <div className="stat">
      <div className="k">{k}</div>
      <div className="v num">{v}</div>
    </div>
  );
}

// ── Roster ──────────────────────────────────────────────────────────────────
function RosterTab() {
  const [offset, setOffset] = useState(0);
  const limit = 60;
  const { data, error, loading } = useApi<RosterItem[]>(() => Bots.roster(offset, limit), [offset]);

  if (error) return <ErrBox msg={error} />;
  return (
    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
      <table className="tbl">
        <thead>
          <tr>
            <th>Bot</th><th>Country</th><th>City</th><th>UTC window</th><th>Awake</th><th style={{ textAlign: 'right' }}>Followers</th>
          </tr>
        </thead>
        <tbody>
          {(data ?? []).map((b) => (
            <tr key={b.id}>
              <td>
                <div className="who">
                  {b.photo_url ? <img className="ava" src={b.photo_url} alt="" /> : <div className="ava" />}
                  <div><b>{b.display_name}</b><span>@{b.username}</span></div>
                </div>
              </td>
              <td>{b.country_code ?? '—'}</td>
              <td>{b.city ?? '—'}</td>
              <td className="num">{b.active_start_hour ?? '—'}–{b.active_end_hour ?? '—'}</td>
              <td>{b.awake_now ? <span className="pill on"><i />awake</span> : <span className="pill off">asleep</span>}</td>
              <td className="num" style={{ textAlign: 'right' }}>{b.follower_count}</td>
            </tr>
          ))}
          {loading && <tr><td colSpan={6} className="muted" style={{ padding: 18 }}>Loading…</td></tr>}
          {!loading && (data ?? []).length === 0 && <tr><td colSpan={6} className="muted" style={{ padding: 18 }}>No bots — run <code>npm run seed:bots</code>.</td></tr>}
        </tbody>
      </table>
      <div style={{ display: 'flex', justifyContent: 'space-between', padding: 14, borderTop: '1px solid var(--line)' }}>
        <button className="btn ghost sm" disabled={offset === 0} onClick={() => setOffset(Math.max(0, offset - limit))}>← Prev</button>
        <span className="muted">offset {offset}</span>
        <button className="btn ghost sm" disabled={(data ?? []).length < limit} onClick={() => setOffset(offset + limit)}>Next →</button>
      </div>
    </div>
  );
}

// ── Config ──────────────────────────────────────────────────────────────────
const KNOBS: { key: keyof BotConfig; label: string; hint: string }[] = [
  { key: 'tickIntervalSec', label: 'Tick interval (s)', hint: 'engine loop period' },
  { key: 'gapWindowSec', label: 'Gap window (s)', hint: 'post gap-fill rolling window' },
  { key: 'postsPerMin', label: 'Posts / min', hint: 'target post rate (gap-filled)' },
  { key: 'botPostCooldownMin', label: 'Post cooldown (min)', hint: 'per-bot cooldown after posting' },
  { key: 'likesPerMin', label: 'Likes / min', hint: 'full-rate, newest-biased' },
  { key: 'newestBiasPct', label: 'Newest bias %', hint: 'chance a like targets the freshest posts' },
  { key: 'maxBotLikesPerPost', label: 'Max bot likes / post', hint: 'anti fake-viral cap' },
  { key: 'viewsPerMin', label: 'Views / min', hint: 'cheapest stream' },
  { key: 'viewBatchSize', label: 'View batch size', hint: 'posts stamped per view action' },
  { key: 'followsPerMin', label: 'Follows / min', hint: 'bot → random user (→ notification)' },
  { key: 'tournamentsPerDay', label: 'Tournaments / day', hint: 'slow cadence, with real flights' },
  { key: 'recordsPerDay', label: 'Live records / day', hint: 'bots go live; followers view/like' },
];

function ConfigTab() {
  const { data, error, loading, reload } = useApi<BotConfig>(() => Bots.config());
  const [draft, setDraft] = useState<BotConfig | null>(null);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  const cfg = draft ?? data;
  if (error) return <ErrBox msg={error} />;
  if (loading || !cfg) return <p className="muted">Loading…</p>;

  function set<K extends keyof BotConfig>(k: K, v: BotConfig[K]) {
    setDraft({ ...(cfg as BotConfig), [k]: v });
    setSaved(false);
  }
  async function save() {
    if (!draft) return;
    setSaving(true);
    try {
      await Bots.updateConfig(draft);
      setDraft(null);
      setSaved(true);
      await reload();
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="grid g2" style={{ alignItems: 'start' }}>
      <div className="card">
        <div className="row">
          <div><div className="lbl">Engine enabled</div><div className="hint">master kill-switch</div></div>
          <button className={`toggle ${cfg.enabled ? '' : 'off'}`} onClick={() => set('enabled', !cfg.enabled)} aria-label="enabled" />
        </div>
        {KNOBS.slice(0, 6).map((n) => (
          <div className="row" key={n.key as string}>
            <div><div className="lbl">{n.label}</div><div className="hint">{n.hint}</div></div>
            <input className="field num-in" type="number" value={cfg[n.key] as number}
              onChange={(e) => set(n.key, Number(e.target.value) as any)} />
          </div>
        ))}
      </div>
      <div className="card">
        {KNOBS.slice(6).map((n) => (
          <div className="row" key={n.key as string}>
            <div><div className="lbl">{n.label}</div><div className="hint">{n.hint}</div></div>
            <input className="field num-in" type="number" value={cfg[n.key] as number}
              onChange={(e) => set(n.key, Number(e.target.value) as any)} />
          </div>
        ))}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 16 }}>
          <button className="btn" disabled={!draft || saving} onClick={save}>{saving ? 'Saving…' : 'Save changes'}</button>
          {saved && <span className="pill on"><i />saved</span>}
          {draft && <span className="muted">unsaved</span>}
        </div>
      </div>
    </div>
  );
}

// ── Content ─────────────────────────────────────────────────────────────────
function ContentTab() {
  const { data, error, loading } = useApi<ContentPools>(() => Bots.content());
  if (error) return <ErrBox msg={error} />;
  if (loading || !data) return <p className="muted">Loading…</p>;
  return (
    <>
      <div className="grid g4" style={{ marginBottom: 16 }}>
        <Stat k="Captions" v={data.captions} />
        <Stat k="Image pools" v={data.postImages} />
        <Stat k="Title combos" v={data.tournamentTitles} />
        <Stat k="Cities" v={data.cities} />
      </div>
      <div className="card" style={{ marginBottom: 16 }}>
        <h3>Countries ({data.countries.length})</h3>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {data.countries.map((c) => <span key={c} className="pill brand">{c}</span>)}
        </div>
      </div>
      <div className="card">
        <h3>Pigeon counts</h3>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {data.pigeonCounts.map((n) => <span key={n} className="pill amber">{n}</span>)}
        </div>
        <p className="muted" style={{ marginTop: 12 }}>
          Captions, images (LoremFlickr pigeon tags) &amp; tournament pools live in the backend content provider.
          Making these editable from here is a planned enhancement (DB-backed templates).
        </p>
      </div>
    </>
  );
}
