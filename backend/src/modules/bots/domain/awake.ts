/**
 * Is a bot awake at `hourUtc` given its UTC active window? A window may wrap past
 * midnight (start > end); a null/degenerate window means always awake.
 * Shared by the engine (Schedule awake-set) and the admin roster/overview.
 */
export function isAwakeInWindow(
  start: number | null,
  end: number | null,
  hourUtc: number,
): boolean {
  if (start == null || end == null || start === end) return true;
  return start < end ? hourUtc >= start && hourUtc < end : hourUtc >= start || hourUtc < end;
}
