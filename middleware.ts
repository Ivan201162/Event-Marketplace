import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function middleware(req: NextRequest) {
  const res = NextResponse.next()
  const supabase = createMiddlewareClient({ req, res })

  const {
    data: { session },
  } = await supabase.auth.getSession()

  // Защищенные роуты
  const protectedRoutes = ['/create', '/settings', '/onboarding']
  const authRoutes = ['/auth/sign-in', '/auth/sign-up']

  const isProtectedRoute = protectedRoutes.some(route =>
    req.nextUrl.pathname.startsWith(route)
  )
  const isAuthRoute = authRoutes.some(route =>
    req.nextUrl.pathname.startsWith(route)
  )

  // Если пользователь не авторизован и пытается попасть на защищенную страницу
  if (isProtectedRoute && !session) {
    return NextResponse.redirect(new URL('/auth/sign-in', req.url))
  }

  // Если пользователь авторизован и пытается попасть на страницы авторизации
  if (isAuthRoute && session) {
    return NextResponse.redirect(new URL('/', req.url))
  }

  // Если пользователь авторизован, но не завершил онбординг
  if (session && req.nextUrl.pathname !== '/onboarding') {
    const { data: profile } = await supabase
      .from('profiles')
      .select('id')
      .eq('id', session.user.id)
      .single()

    if (!profile) {
      return NextResponse.redirect(new URL('/onboarding', req.url))
    }
  }

  return res
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}