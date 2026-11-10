import './globals.css';
export const metadata = { title: 'Boyfriend Services', description: 'A private little booking app for two.' , manifest: '/manifest.webmanifest', appleWebApp: { capable: true, title: 'Boyfriend Services' }};
export const viewport = { width: 'device-width', initialScale: 1, themeColor: '#16121e' };
export default function RootLayout({children}) { return <html lang="en"><body>{children}</body></html>; }
