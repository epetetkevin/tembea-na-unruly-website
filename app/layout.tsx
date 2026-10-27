import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = { title: 'TEMBEA NA UNRULY | Find Your Wild', description: 'Kenyan road trips, adventures, tours and unforgettable experiences with UnrulyFamily.' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body>{children}</body></html>; }
