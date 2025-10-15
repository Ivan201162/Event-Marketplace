'use client'

import { usePosts } from '@/lib/hooks/use-posts'
import PostCard from './post-card'
import { Plus } from 'lucide-react'
import Link from 'next/link'

export default function Feed() {
  const { posts, loading, error } = usePosts()

  if (loading) {
    return (
      <div className="flex items-center justify-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="text-center py-8">
        <p className="text-red-400 mb-4">Ошибка загрузки постов</p>
        <button
          onClick={() => window.location.reload()}
          className="btn-primary"
        >
          Попробовать снова
        </button>
      </div>
    )
  }

  if (posts.length === 0) {
    return (
      <div className="text-center py-8">
        <p className="text-gray-400 mb-4">Пока нет постов</p>
        <Link href="/create" className="btn-primary inline-flex items-center gap-2">
          <Plus size={16} />
          Создать первый пост
        </Link>
      </div>
    )
  }

  return (
    <div className="px-4 py-4">
      {posts.map((post) => (
        <PostCard key={post.id} post={post} />
      ))}
    </div>
  )
}
