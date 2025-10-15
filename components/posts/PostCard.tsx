'use client'

import { useState } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { Heart, MessageCircle, Share, MoreHorizontal, User } from 'lucide-react'
import { formatDate } from '@/utils/format'
import { PostWithAuthor } from '@/types'
import PostComments from './PostComments'

interface PostCardProps {
  post: PostWithAuthor
}

export default function PostCard({ post }: PostCardProps) {
  const [isLiked, setIsLiked] = useState(post.is_liked || false)
  const [likesCount, setLikesCount] = useState(post.likes_count)
  const [showComments, setShowComments] = useState(false)
  const [isLoading, setIsLoading] = useState(false)

  const handleLike = async () => {
    if (isLoading) return

    setIsLoading(true)
    const previousLiked = isLiked
    const previousCount = likesCount

    // Optimistic update
    setIsLiked(!isLiked)
    setLikesCount(isLiked ? likesCount - 1 : likesCount + 1)

    try {
      const response = await fetch(`/api/posts/${post.id}/like`, {
        method: 'POST',
      })

      if (!response.ok) {
        // Revert on error
        setIsLiked(previousLiked)
        setLikesCount(previousCount)
      }
    } catch (error) {
      // Revert on error
      setIsLiked(previousLiked)
      setLikesCount(previousCount)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="card p-6">
      {/* Post Header */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center space-x-3">
          <Link href={`/u/${post.author.username}`}>
            {post.author.avatar_url ? (
              <Image
                src={post.author.avatar_url}
                alt={post.author.name}
                width={40}
                height={40}
                className="rounded-full"
              />
            ) : (
              <div className="h-10 w-10 rounded-full bg-primary flex items-center justify-center">
                <User className="h-5 w-5 text-primary-foreground" />
              </div>
            )}
          </Link>
          
          <div>
            <Link 
              href={`/u/${post.author.username}`}
              className="font-medium text-foreground hover:underline"
            >
              {post.author.name}
            </Link>
            <p className="text-sm text-muted-foreground">
              @{post.author.username} • {formatDate(post.created_at)}
            </p>
          </div>
        </div>

        <button className="btn btn-ghost p-2">
          <MoreHorizontal className="h-4 w-4" />
        </button>
      </div>

      {/* Post Content */}
      {post.content && (
        <div className="mb-4">
          <p className="text-foreground whitespace-pre-wrap">{post.content}</p>
        </div>
      )}

      {/* Post Media */}
      {post.media_urls && post.media_urls.length > 0 && (
        <div className="mb-4">
          {post.type === 'photo' && (
            <div className="grid grid-cols-1 gap-2">
              {post.media_urls.map((url, index) => (
                <div key={index} className="relative rounded-lg overflow-hidden">
                  <Image
                    src={url}
                    alt={`Post image ${index + 1}`}
                    width={600}
                    height={400}
                    className="w-full h-auto object-cover"
                  />
                </div>
              ))}
            </div>
          )}
          
          {post.type === 'video' && (
            <div className="relative rounded-lg overflow-hidden">
              <video
                src={post.media_urls[0]}
                controls
                className="w-full h-auto"
              >
                Ваш браузер не поддерживает видео.
              </video>
            </div>
          )}
        </div>
      )}

      {/* Post Actions */}
      <div className="flex items-center justify-between pt-4 border-t">
        <div className="flex items-center space-x-6">
          <button
            onClick={handleLike}
            disabled={isLoading}
            className={`flex items-center space-x-2 hover:text-primary transition-colors ${
              isLiked ? 'text-primary' : 'text-muted-foreground'
            }`}
          >
            <Heart className={`h-5 w-5 ${isLiked ? 'fill-current' : ''}`} />
            <span>{likesCount}</span>
          </button>

          <button
            onClick={() => setShowComments(!showComments)}
            className="flex items-center space-x-2 text-muted-foreground hover:text-primary transition-colors"
          >
            <MessageCircle className="h-5 w-5" />
            <span>{post.comments_count}</span>
          </button>

          <button className="flex items-center space-x-2 text-muted-foreground hover:text-primary transition-colors">
            <Share className="h-5 w-5" />
            <span>Поделиться</span>
          </button>
        </div>
      </div>

      {/* Comments Section */}
      {showComments && (
        <div className="mt-4 pt-4 border-t">
          <PostComments postId={post.id} />
        </div>
      )}
    </div>
  )
}
