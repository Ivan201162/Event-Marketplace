import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/utils/supabase/server'

export async function DELETE(request: NextRequest) {
  try {
    const supabase = await createClient()
    
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const userId = user.id

    // Delete all user data in the correct order (respecting foreign key constraints)
    
    // 1. Delete post likes
    await supabase
      .from('post_likes')
      .delete()
      .eq('user_id', userId)

    // 2. Delete post comments
    await supabase
      .from('post_comments')
      .delete()
      .eq('user_id', userId)

    // 3. Delete posts
    await supabase
      .from('posts')
      .delete()
      .eq('user_id', userId)

    // 4. Delete follows (both directions)
    await supabase
      .from('follows')
      .delete()
      .or(`follower_id.eq.${userId},following_id.eq.${userId}`)

    // 5. Delete profile
    await supabase
      .from('profiles')
      .delete()
      .eq('id', userId)

    // 6. Delete the auth user (this will also sign them out)
    const { error: deleteError } = await supabase.auth.admin.deleteUser(userId)

    if (deleteError) {
      console.error('Error deleting user:', deleteError)
      return NextResponse.json({ error: 'Failed to delete account' }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error in delete account:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
