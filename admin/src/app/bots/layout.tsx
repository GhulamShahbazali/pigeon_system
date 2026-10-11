'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { clearToken, getToken } from '@/lib/api';

export default function PanelLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
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
        <div className="navitem on"><span className="ic">🤖</span> Bots / Liveness</div>
        <div className="navitem" style={{ opacity: 0.5 }}><span className="ic">🏆</span> Tournaments</div>
        <div className="navitem" style={{ opacity: 0.5 }}><span className="ic">🚩</span> Moderation</div>
        <div className="navitem" style={{ opacity: 0.5 }}><span className="ic">👥</span> Users</div>
        <div className="foot">
          <div className="signout" onClick={signOut}>↩ Sign out</div>
          <div style={{ padding: '8px 12px' }}>v0.1 · {process.env.NEXT_PUBLIC_API_BASE ?? 'localhost:3000/v1'}</div>
        </div>
      </aside>
      <main className="main">{children}</main>
    </div>
  );
}
