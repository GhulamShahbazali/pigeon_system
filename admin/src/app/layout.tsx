import './globals.css';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'PigeonFly Admin',
  description: 'PigeonFly admin panel — bots/liveness + moderation',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
