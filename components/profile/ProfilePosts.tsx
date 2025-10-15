'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import PostCard from '@/components/posts/PostCard'
import { PostWithAuthor } from '@/types'

interface ProfilePostsProps {
  profile: {
    id: string
    username: string
  }
}

export default function ProfilePosts({ profile }: ProfilePostsProps) {
  const [posts, setPosts] = useState<PostWithAuthor[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const supabase = createClient()

  useEffect(() => {
    const fetchPosts = async () => {
      try {
        const { data, error } = await supabase
          .from('posts')
          .select(`
            *,
            author:profiles!posts_author_id_fkey(*),
            post_likes!post_likes_post_id_fkey(id, user_id)
          `)
          .eq('author_id', profile.id)
          .order('created_at', { ascending: false })

        if (error) {
          console.error('Error fetching posts:', error)
        } else {
          const { data: { user } } = await supabase.auth.getUser()
          const postsWithFlags = data.map(post => ({
            ...post,
            is_liked: post.post_likes.some(like => like.user_id === user?.id),
            is_following: false,
          }))
          setPosts(postsWithFlags)
        }
      } catch (error) {
        console.error('Error:', error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchPosts()
  }, [profile.id, supabase])

  if (isLoading) {
    return (
      <div className="space-y-6">
        {[...Array(3)].map((_, i) => (
          <div key={i} className="card p-6 animate-pulse">
            <div className="flex items-start space-x-3">
              <div className="h-10 w-10 bg-secondary rounded-full" />
              <div className="flex-1 space-y-2">
                <div className="h-4 bg-secondary rounded w-1/4" />
                <div className="h-4 bg-secondary rounded w-3/4" />
                <div className="h-4 bg-secondary rounded w-1/2" />
              </div>
            </div>
          </div>
        ))}
      </div>
    )
  }

  if (posts.length === 0) {
    return (
      <div className="text-center py-12">
        <h3 className="text-lg font-medium text-foreground mb-2">
          Пока нет постов
        </h3>
        <p className="text-muted-foreground">
          Этот пользователь еще не опубликовал ни одного поста
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {posts.map((post) => (
        <PostCard key={post.id} post={post} />
      ))}
    </div>
  )
}
