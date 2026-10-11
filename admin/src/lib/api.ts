'use client';

const BASE = process.env.NEXT_PUBLIC_API_BASE ?? 'http://localhost:3000/v1';
const TOKEN_KEY = 'pf_admin_token';

/** Keep only valid JWT characters — strips stray whitespace / non-ASCII that a
 *  paste can introduce (which otherwise breaks the fetch Authorization header:
 *  "String contains non ISO-8859-1 code point"). */
function sanitize(t: string): string {
  return (t ?? '').replace(/[^A-Za-z0-9._-]/g, '');
}

export function getToken(): string {
  try {
    return sanitize(localStorage.getItem(TOKEN_KEY) ?? '');
  } catch {
    return '';
  }
}
export function setToken(t: string): void {
  try {
    localStorage.setItem(TOKEN_KEY, sanitize(t));
  } catch {
    /* ignore */
  }
}
export function clearToken(): void {
  try {
    localStorage.removeItem(TOKEN_KEY);
  } catch {
    /* ignore */
  }
}

export class ApiError extends Error {
  constructor(public status: number, public code: string, message: string) {
    super(message);
  }
}

/** Thin fetch wrapper: attaches the superadmin Bearer token, unwraps `{ data }`. */
export async function apiFetch<T = any>(
  path: string,
  init: RequestInit = {},
): Promise<T> {
  const res = await fetch(BASE + path, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${getToken()}`,
      ...(init.headers ?? {}),
    },
    cache: 'no-store',
  });
  let body: any = null;
  try {
    body = await res.json();
  } catch {
    /* 204 */
  }
  if (!res.ok) {
    const err = body?.error ?? {};
    throw new ApiError(res.status, err.code ?? 'error', err.message ?? res.statusText);
  }
  // Endpoints return either { data } or a bare object (overview).
  return (body && 'data' in body ? body.data : body) as T;
}

export const api = {
  get: <T>(p: string) => apiFetch<T>(p),
  patch: <T>(p: string, b: unknown) => apiFetch<T>(p, { method: 'PATCH', body: JSON.stringify(b) }),
  post: <T>(p: string, b?: unknown) =>
    apiFetch<T>(p, { method: 'POST', body: b ? JSON.stringify(b) : undefined }),
};

/** Staff login — username + password → stores the returned session token. */
export async function login(username: string, password: string): Promise<void> {
  const r = await apiFetch<{ session_token: string }>('/auth/admin/login', {
    method: 'POST',
    body: JSON.stringify({ username, password }),
  });
  if (!r?.session_token) throw new ApiError(500, 'error', 'No token returned');
  setToken(r.session_token);
}
