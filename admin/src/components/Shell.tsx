'use client';

import { useEffect, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import Link from 'next/link';
import { clearToken, getToken } from '@/lib/api';

const NAV = [
  { href: '/bots', icon: '🤖', label: 'Bots / Liveness' },
  { href: '/tournaments', icon: '🏆', label: 'Tournaments' },
  { href: '/users', icon: '👥', label: 'Users' },
];

/** Shared admin shell: auth gate + sidebar (active item from the pathname). */
export default function Shell({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (!getToken()) router.replace('/login');
    else setReady(true);
  }, [router]);

  if (!ready) return null;

  function signOut() {
    clearToken();
    router.replace('/login');
  }

  return (
    <div className="shell">
      <aside className="side">
        <div className="brand">
          <div className="logo">🕊️</div>
          <div>
            <b>PigeonFly</b>
            <span>Admin Console</span>
          </div>
        </div>
        {NAV.map((n) => {
          const on = pathname === n.href || pathname.startsWith(n.href + '/');
          return (
            <Link key={n.href} href={n.href} className={`navitem ${on ? 'on' : ''}`}>
              <span className="ic">{n.icon}</span> {n.label}
            </Link>
          );
        })}
        <div className="navitem" style={{ opacity: 0.45, cursor: 'default' }}>
          <span className="ic">🚩</span> Moderation
        </div>
        <div className="foot">
          <div className="signout" onClick={signOut}>↩ Sign out</div>
          <div style={{ padding: '8px 12px' }}>v0.1 · {process.env.NEXT_PUBLIC_API_BASE ?? 'localhost:3000/v1'}</div>
        </div>
      </aside>
      <main className="main">{children}</main>
    </div>
  );
}
