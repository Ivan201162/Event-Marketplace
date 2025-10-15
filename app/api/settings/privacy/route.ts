import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/utils/supabase/server'

export async function GET() {
  try {
    const supabase = await createClient()
    
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Get privacy settings from user metadata or a separate table
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('privacy_settings')
      .eq('id', user.id)
      .single()

    if (error) {
      console.error('Error fetching privacy settings:', error)
      return NextResponse.json({ error: 'Failed to fetch settings' }, { status: 500 })
    }

    // Default privacy settings
    const defaultSettings = {
      profileVisibility: 'public',
      allowMessages: true,
      showEmail: false,
      showPhone: false,
      notifications: {
        newFollowers: true,
        newMessages: true,
        newLikes: true,
        newComments: true,
      },
    }

    const settings = profile?.privacy_settings || defaultSettings

    return NextResponse.json(settings)
  } catch (error) {
    console.error('Error in privacy settings GET:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

export async function PATCH(request: NextRequest) {
  try {
    const supabase = await createClient()
    
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await request.json()
    const { profileVisibility, allowMessages, showEmail, showPhone, notifications } = body

    // Validate the settings
    const validSettings = {
      profileVisibility: profileVisibility === 'private' ? 'private' : 'public',
      allowMessages: Boolean(allowMessages),
      showEmail: Boolean(showEmail),
      showPhone: Boolean(showPhone),
      notifications: {
        newFollowers: Boolean(notifications?.newFollowers),
        newMessages: Boolean(notifications?.newMessages),
        newLikes: Boolean(notifications?.newLikes),
        newComments: Boolean(notifications?.newComments),
      },
    }

    const { error } = await supabase
      .from('profiles')
      .update({ privacy_settings: validSettings })
      .eq('id', user.id)

    if (error) {
      console.error('Error updating privacy settings:', error)
      return NextResponse.json({ error: 'Failed to update settings' }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error in privacy settings PATCH:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
