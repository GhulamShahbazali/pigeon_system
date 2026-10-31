'use client';

import { api } from './api';

export interface AdminUser {
  id: string;
  display_name: string;
  username: string;
  email: string | null;
  is_suspended: boolean;
  created_at: string;
}

/** The /admin/users endpoint returns raw Prisma rows (camelCase); normalize. */
function norm(u: any): AdminUser {
  return {
    id: u.id,
    display_name: u.display_name ?? u.displayName ?? '',
    username: u.username ?? '',
    email: u.email ?? null,
    is_suspended: u.is_suspended ?? u.isSuspended ?? false,
    created_at: u.created_at ?? u.createdAt ?? '',
  };
}

export const Users = {
  async list(q: string, offset: number, limit: number): Promise<AdminUser[]> {
    const rows = await api.get<any[]>(
      `/admin/users?q=${encodeURIComponent(q)}&offset=${offset}&limit=${limit}`,
    );
    return (rows ?? []).map(norm);
  },
  suspend: (id: string, reason?: string) =>
    api.post(`/admin/users/${id}/suspend`, reason ? { reason } : {}),
  unsuspend: (id: string) => api.post(`/admin/users/${id}/unsuspend`),
};
