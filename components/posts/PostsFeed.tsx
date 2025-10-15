'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import PostCard from './PostCard'
import { PostWithAuthor } from '@/types'

export default function PostsFeed() {
  const [posts, setPosts] = useState<PostWithAuthor[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [hasMore, setHasMore] = useState(true)
  const supabase = createClient()

  const fetchPosts = async (pageNum: number = 1, append: boolean = false) => {
    try {
      const response = await fetch(`/api/posts?page=${pageNum}&limit=10`)
      
      if (response.ok) {
        const newPosts = await response.json()
        
        if (append) {
          setPosts(prev => [...prev, ...newPosts])
        } else {
          setPosts(newPosts)
        }
        
        setHasMore(newPosts.length === 10)
      }
    } catch (error) {
      console.error('Error fetching posts:', error)
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchPosts(1, false)
  }, [])

  const loadMore = () => {
    if (!isLoading && hasMore) {
      const nextPage = page + 1
      setPage(nextPage)
      fetchPosts(nextPage, true)
    }
  }

  if (isLoading && posts.length === 0) {
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
      <div className="card p-8 text-center">
        <h3 className="text-lg font-medium text-foreground mb-2">
          Пока нет постов
        </h3>
        <p className="text-muted-foreground">
          Станьте первым, кто поделится своими идеями!
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {posts.map((post) => (
        <PostCard key={post.id} post={post} />
      ))}
      
      {hasMore && (
        <div className="text-center">
          <button
            onClick={loadMore}
            disabled={isLoading}
            className="btn btn-outline"
          >
            {isLoading ? 'Загрузка...' : 'Загрузить еще'}
          </button>
        </div>
      )}
    </div>
  )
}
