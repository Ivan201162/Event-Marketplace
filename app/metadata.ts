import { Metadata } from 'next'

export const defaultMetadata: Metadata = {
  title: {
    default: 'Event Marketplace',
    template: '%s | Event Marketplace'
  },
  description: 'Соцсеть для ведущих и специалистов событий. Найдите лучших специалистов для вашего мероприятия или продвигайте свои услуги.',
  keywords: ['события', 'специалисты', 'ведущие', 'фотографы', 'видеографы', 'декораторы', 'аниматоры'],
  authors: [{ name: 'Event Marketplace Team' }],
  creator: 'Event Marketplace',
  publisher: 'Event Marketplace',
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  metadataBase: new URL(process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'),
  alternates: {
    canonical: '/',
  },
  openGraph: {
    type: 'website',
    locale: 'ru_RU',
    url: '/',
    title: 'Event Marketplace',
    description: 'Соцсеть для ведущих и специалистов событий',
    siteName: 'Event Marketplace',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'Event Marketplace',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Event Marketplace',
    description: 'Соцсеть для ведущих и специалистов событий',
    images: ['/og-image.png'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  verification: {
    google: 'your-google-verification-code',
    yandex: 'your-yandex-verification-code',
  },
}
