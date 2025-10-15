import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextRequest, NextResponse } from 'next/server'
import { generateUsername, transliterate } from '@/lib/utils'

export async function GET(request: NextRequest) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get('code')

  if (code) {
    const cookieStore = cookies()
    const supabase = createRouteHandlerClient({ cookies: () => cookieStore })

    try {
      const { data, error } = await supabase.auth.exchangeCodeForSession(code)

      if (error) {
        console.error('Auth callback error:', error)
        return NextResponse.redirect(`${requestUrl.origin}/auth/sign-in?error=auth_callback_error`)
      }

      if (data.user) {
        // Проверяем, есть ли профиль пользователя
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', data.user.id)
          .single()

        if (profileError && profileError.code === 'PGRST116') {
          // Профиль не найден, создаем новый
          const userMetadata = data.user.user_metadata
          const name = userMetadata?.name || userMetadata?.full_name || 'Пользователь'
          const avatarUrl = userMetadata?.avatar_url || userMetadata?.picture
          const city = userMetadata?.city // Для VK

          // Генерируем уникальный username
          let username = generateUsername(name)
          let attempts = 0

          while (attempts < 10) {
            const { data: existingProfile } = await supabase
              .from('profiles')
              .select('id')
              .eq('username', username)
              .single()

            if (!existingProfile) break

            username = generateUsername(name)
            attempts++
          }

          // Создаем профиль
          const { error: insertError } = await supabase
            .from('profiles')
            .insert({
              id: data.user.id,
              username,
              name,
              avatar_url: avatarUrl,
              city,
              skills: [],
              links: [],
              is_public: true,
            })

          if (insertError) {
            console.error('Profile creation error:', insertError)
            return NextResponse.redirect(`${requestUrl.origin}/onboarding`)
          }

          return NextResponse.redirect(`${requestUrl.origin}/onboarding`)
        } else if (profileError) {
          console.error('Profile check error:', profileError)
          return NextResponse.redirect(`${requestUrl.origin}/onboarding`)
        }

        // Профиль существует, перенаправляем на главную
        return NextResponse.redirect(`${requestUrl.origin}/`)
      }
    } catch (error) {
      console.error('Unexpected error in auth callback:', error)
      return NextResponse.redirect(`${requestUrl.origin}/auth/sign-in?error=unexpected_error`)
    }
  }

  // Если нет кода, перенаправляем на страницу входа
  return NextResponse.redirect(`${requestUrl.origin}/auth/sign-in`)
}