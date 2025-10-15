'use client'

import Image from 'next/image'
import Link from 'next/link'
import { Heart, MessageCircle, Share, MoreHorizontal } from 'lucide-react'
import { Post } from '@/lib/types'
import { formatDate } from '@/lib/utils'
import { usePosts } from '@/lib/hooks/use-posts'
import { useSupabase } from '@/lib/providers/supabase-provider'

interface PostCardProps {
  post: Post
}

export default function PostCard({ post }: PostCardProps) {
  const { likePost } = usePosts()
  const { user } = useSupabase()
  const isLiked = false // TODO: Implement like status check

  const handleLike = () => {
    if (user) {
      likePost(post.id)
    }
  }

  return (
    <div className="card p-4 mb-4">
      {/* Header */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-3">
          <Link href={`/u/${post.profile?.username}`}>
            <Image
              src={post.profile?.avatar_url || '/default-avatar.png'}
              alt={post.profile?.name || 'User'}
              width={40}
              height={40}
              className="rounded-full border border-neutral-700"
            />
          </Link>
          <div>
            <Link
              href={`/u/${post.profile?.username}`}
              className="text-white font-medium hover:text-primary-400 transition-colors"
            >
              {post.profile?.name || post.profile?.username}
            </Link>
            <p className="text-gray-400 text-sm">
              {formatDate(post.created_at)}
            </p>
          </div>
        </div>
        <button className="p-1 hover:bg-neutral-700 rounded-full transition-colors">
          <MoreHorizontal size={16} className="text-gray-400" />
        </button>
      </div>

      {/* Content */}
      {post.content && (
        <p className="text-white mb-3 whitespace-pre-wrap">
          {post.content}
        </p>
      )}

      {/* Media */}
      {post.media_urls.length > 0 && (
        <div className="mb-3">
          {post.type === 'photo' && (
            <div className="grid gap-2" style={{ gridTemplateColumns: `repeat(${Math.min(post.media_urls.length, 3)}, 1fr)` }}>
              {post.media_urls.slice(0, 4).map((url, index) => (
                <div key={index} className="relative aspect-square">
                  <Image
                    src={url}
                    alt={`Post media ${index + 1}`}
                    fill
                    className="object-cover rounded-lg"
                  />
                  {index === 3 && post.media_urls.length > 4 && (
                    <div className="absolute inset-0 bg-black bg-opacity-50 rounded-lg flex items-center justify-center">
                      <span className="text-white font-bold text-lg">
                        +{post.media_urls.length - 4}
                      </span>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
          {post.type === 'video' && (
            <video
              src={post.media_urls[0]}
              controls
              className="w-full rounded-lg"
            />
          )}
        </div>
      )}

      {/* Actions */}
      <div className="flex items-center gap-6 pt-3 border-t border-neutral-700">
        <button
          onClick={handleLike}
          className={`flex items-center gap-2 transition-colors ${isLiked ? 'text-red-500' : 'text-gray-400 hover:text-red-500'
            }`}
        >
          <Heart size={20} className={isLiked ? 'fill-current' : ''} />
          <span className="text-sm">{post.likes_count}</span>
        </button>

        <Link
          href={`/posts/${post.id}`}
          className="flex items-center gap-2 text-gray-400 hover:text-primary-400 transition-colors"
        >
          <MessageCircle size={20} />
          <span className="text-sm">{post.comments_count}</span>
        </Link>

        <button className="flex items-center gap-2 text-gray-400 hover:text-primary-400 transition-colors">
          <Share size={20} />
        </button>
      </div>
    </div>
  )
}
