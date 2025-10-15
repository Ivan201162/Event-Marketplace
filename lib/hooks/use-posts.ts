'use client'

import { useState, useEffect } from 'react'
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'
import { Post } from '@/lib/types'

export function usePosts() {
  const [posts, setPosts] = useState<Post[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const supabase = createClientComponentClient()

  useEffect(() => {
    const fetchPosts = async () => {
      try {
        const { data, error } = await supabase
          .from('posts')
          .select(`
            *,
            profile:profiles(*)
          `)
          .order('created_at', { ascending: false })

        if (error) throw error
        setPosts(data || [])
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Ошибка загрузки постов')
      } finally {
        setLoading(false)
      }
    }

    fetchPosts()
  }, [supabase])

  const createPost = async (post: Omit<Post, 'id' | 'created_at' | 'updated_at' | 'likes_count' | 'comments_count'>) => {
    try {
      const { data, error } = await supabase
        .from('posts')
        .insert(post)
        .select(`
          *,
          profile:profiles(*)
        `)
        .single()

      if (error) throw error
      setPosts(prev => [data, ...prev])
      return data
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка создания поста')
      throw err
    }
  }

  const likePost = async (postId: string) => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    try {
      // Проверяем, лайкнул ли уже пользователь
      const { data: existingLike } = await supabase
        .from('post_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .single()

      if (existingLike) {
        // Убираем лайк
        await supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id)

        setPosts(prev => prev.map(post =>
          post.id === postId
            ? { ...post, likes_count: Math.max(0, post.likes_count - 1) }
            : post
        ))
      } else {
        // Добавляем лайк
        await supabase
          .from('post_likes')
          .insert({ post_id: postId, user_id: user.id })

        setPosts(prev => prev.map(post =>
          post.id === postId
            ? { ...post, likes_count: post.likes_count + 1 }
            : post
        ))
      }
    } catch (err) {
      console.error('Ошибка лайка:', err)
    }
  }

  return { posts, loading, error, createPost, likePost }
}
