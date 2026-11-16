import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'GaleriPro — Oto Galeri Araç Alım-Satım & Yönetim Sistemi',
  description: 'Oto galeri sahipleri için modern araç stok takibi, kâr/zarar hesaplama, resmi raporlama ve masaüstü yönetim sistemi.',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="tr">
      <body className="antialiased">{children}</body>
    </html>
  )
}
