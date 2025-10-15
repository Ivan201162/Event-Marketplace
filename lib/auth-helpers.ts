import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'
import { generateUsername, transliterate } from './utils'

export async function handleOAuthCallback(user: any) {
  const supabase = createClientComponentClient()

  // Проверяем, есть ли профиль пользователя
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single()

  if (profileError && profileError.code === 'PGRST116') {
    // Профиль не найден, создаем новый
    const userMetadata = user.user_metadata
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
        id: user.id,
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
      return { needsOnboarding: true }
    }

    return { needsOnboarding: true }
  } else if (profileError) {
    console.error('Profile check error:', profileError)
    return { needsOnboarding: true }
  }

  // Профиль существует
  return { needsOnboarding: false }
}

export async function signOut() {
  const supabase = createClientComponentClient()
  const { error } = await supabase.auth.signOut()

  if (error) {
    throw new Error(error.message)
  }
}

export async function signInWithEmail(email: string, password: string) {
  const supabase = createClientComponentClient()
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  })

  if (error) {
    throw new Error(error.message)
  }

  return data
}

export async function signUpWithEmail(email: string, password: string, name: string) {
  const supabase = createClientComponentClient()
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        name,
      }
    }
  })

  if (error) {
    throw new Error(error.message)
  }

  return data
}

export async function signInWithOAuth(provider: 'google' | 'github' | 'vk') {
  const supabase = createClientComponentClient()
  const { error } = await supabase.auth.signInWithOAuth({
    provider,
    options: {
      redirectTo: `${window.location.origin}/auth/callback`
    }
  })

  if (error) {
    throw new Error(error.message)
  }
}
