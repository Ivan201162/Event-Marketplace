import { Inter } from 'next/font/google'
import './globals.css'
import { SupabaseProvider } from '@/lib/providers/supabase-provider'
import ErrorBoundary from '@/components/error-boundary'
import { Toaster } from 'react-hot-toast'
import { defaultMetadata } from './metadata'

const inter = Inter({ subsets: ['latin'] })

export const metadata = defaultMetadata

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ru">
      <body className={inter.className}>
        <ErrorBoundary>
          <SupabaseProvider>
            {children}
            <Toaster
              position="top-right"
              toastOptions={{
                duration: 4000,
                style: {
                  background: '#1f2937',
                  color: '#fff',
                },
              }}
            />
          </SupabaseProvider>
        </ErrorBoundary>
      </body>
    </html>
  )
}