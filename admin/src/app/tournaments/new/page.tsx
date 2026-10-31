'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Tournaments, type CreateTournamentBody } from '@/lib/tournaments';

export default function NewTournamentPage() {
  const router = useRouter();
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [f, setF] = useState({
    title: '',
    start_date: '',
    num_days: '1',
    schedule_type: 'every_day',
    pigeon_count: '10',
    fly_time: '06:00',
    end_time: '18:00',
    organizer_contact: '',
    cover_url: '',
    description: '',
    rules: '',
  });

  const set = (k: keyof typeof f, v: string) => setF({ ...f, [k]: v });
  const valid = f.title.trim() && f.start_date && Number(f.num_days) >= 1 && Number(f.pigeon_count) >= 1;

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!valid) return;
    setSaving(true);
    setError(null);
    const body: CreateTournamentBody = {
      title: f.title.trim(),
      start_date: f.start_date,
      num_days: Number(f.num_days),
      schedule_type: f.schedule_type as 'every_day' | 'alternate_days',
      pigeon_count: Number(f.pigeon_count),
      fly_time: f.fly_time,
      end_time: f.end_time,
      organizer_contact: f.organizer_contact.trim() || undefined,
      cover_url: f.cover_url.trim() || undefined,
      description: f.description.trim() || undefined,
      rules: f.rules.trim() || undefined,
    };
    try {
      const res = await Tournaments.create(body);
      router.push(res?.id ? `/tournaments/${res.id}` : '/tournaments');
    } catch (err: any) {
      setError(err?.message ?? 'Create failed');
      setSaving(false);
    }
  }

  return (
    <>
      <div style={{ marginBottom: 14 }}>
        <Link href="/tournaments" className="muted" style={{ fontWeight: 700 }}>← Tournaments</Link>
      </div>
      <div className="pagehead">
        <div>
          <h1>New tournament</h1>
          <p>Created under your admin account as organizer.</p>
        </div>
      </div>

      {error && <div className="err">⚠ {error}</div>}

      <form className="card" onSubmit={submit} style={{ display: 'flex', flexDirection: 'column', gap: 14, maxWidth: 680 }}>
        <label>
          <div className="k" style={{ marginBottom: 5 }}>Title *</div>
          <input className="field" value={f.title} onChange={(e) => set('title', e.target.value)} autoFocus />
        </label>

        <div className="grid g2">
          <label>
            <div className="k" style={{ marginBottom: 5 }}>Start date *</div>
            <input className="field" type="date" value={f.start_date} onChange={(e) => set('start_date', e.target.value)} />
          </label>
          <label>
            <div className="k" style={{ marginBottom: 5 }}>Schedule</div>
            <select className="field" value={f.schedule_type} onChange={(e) => set('schedule_type', e.target.value)}>
              <option value="every_day">Every day</option>
              <option value="alternate_days">Alternate days</option>
            </select>
          </label>
        </div>

        <div className="grid g3">
          <label>
            <div className="k" style={{ marginBottom: 5 }}>Days</div>
            <input className="field" type="number" min={1} max={31} value={f.num_days} onChange={(e) => set('num_days', e.target.value)} />
          </label>
          <label>
            <div className="k" style={{ marginBottom: 5 }}>Pigeons / loft</div>
            <input className="field" type="number" min={1} max={1000} value={f.pigeon_count} onChange={(e) => set('pigeon_count', e.target.value)} />
          </label>
          <label>
            <div className="k" style={{ marginBottom: 5 }}>Contact</div>
            <input className="field" value={f.organizer_contact} placeholder="+92…" onChange={(e) => set('organizer_contact', e.target.value)} />
          </label>
        </div>

        <div className="grid g2">
          <label>
            <div className="k" style={{ marginBottom: 5 }}>Fly time</div>
            <input className="field" type="time" value={f.fly_time} onChange={(e) => set('fly_time', e.target.value)} />
          </label>
          <label>
            <div className="k" style={{ marginBottom: 5 }}>End time</div>
            <input className="field" type="time" value={f.end_time} onChange={(e) => set('end_time', e.target.value)} />
          </label>
        </div>

        <label>
          <div className="k" style={{ marginBottom: 5 }}>Cover URL</div>
          <input className="field" value={f.cover_url} placeholder="https://…" onChange={(e) => set('cover_url', e.target.value)} />
        </label>
        <label>
          <div className="k" style={{ marginBottom: 5 }}>Description</div>
          <textarea className="field" rows={3} value={f.description} onChange={(e) => set('description', e.target.value)} />
        </label>
        <label>
          <div className="k" style={{ marginBottom: 5 }}>Rules</div>
          <textarea className="field" rows={3} value={f.rules} onChange={(e) => set('rules', e.target.value)} />
        </label>

        <div style={{ display: 'flex', gap: 10 }}>
          <button className="btn" type="submit" disabled={saving || !valid}>
            {saving ? 'Creating…' : 'Create tournament'}
          </button>
          <Link href="/tournaments" className="btn ghost">Cancel</Link>
        </div>
      </form>
    </>
  );
}
