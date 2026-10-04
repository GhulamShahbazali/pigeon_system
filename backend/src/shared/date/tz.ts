/** Minutes the IANA tz is ahead of UTC at the given instant. */
export function offsetMinutes(tz: string, at: Date): number {
  const dtf = new Intl.DateTimeFormat('en-US', {
    timeZone: tz,
    hour12: false,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
  const m: Record<string, string> = {};
  for (const p of dtf.formatToParts(at)) m[p.type] = p.value;
  const asUTC = Date.UTC(+m.year, +m.month - 1, +m.day, +m.hour, +m.minute, +m.second);
  return (asUTC - at.getTime()) / 60000;
}

/** UTC instant for a wall-clock date (YYYY-MM-DD) + time (HH:MM) in a timezone. */
export function zonedToUtc(dateStr: string, timeStr: string, tz: string): Date {
  const hhmm = timeStr.length >= 5 ? timeStr.slice(0, 5) : '00:00';
  const guess = new Date(`${dateStr}T${hhmm}:00Z`);
  return new Date(guess.getTime() - offsetMinutes(tz, guess) * 60000);
}

export function addDays(dateStr: string, days: number): string {
  const d = new Date(`${dateStr}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

/** UTC instant of the NEXT local midnight (00:00) in the given timezone. */
export function nextLocalMidnightUtc(tz: string, now = new Date()): Date {
  const today = new Intl.DateTimeFormat('en-CA', {
    timeZone: tz,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(now); // YYYY-MM-DD
  return zonedToUtc(addDays(today, 1), '00:00', tz);
}
