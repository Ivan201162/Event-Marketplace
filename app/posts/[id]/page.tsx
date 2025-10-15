'use client'

import { useState, useEffect } from 'react'
import { useParams } from 'next/navigation'
import Image from 'next/image'
import Link from 'next/link'
import { Heart, MessageCircle, Share, ArrowLeft, Send } from 'lucide-react'
import { useSupabase } from '@/lib/providers/supabase-provider'
import { formatDate } from '@/lib/utils'
import toast from 'react-hot-toast'

interface Post {
  id: string
  user_id: string
  type: 'text' | 'photo' | 'video' | 'reel'
  content?: string
  media_urls: string[]
  likes_count: number
  comments_count: number
  created_at: string
  profile?: {
    id: string
    username: string
    name: string
    avatar_url?: string
  }
}

interface Comment {
  id: string
  post_id: string
  user_id: string
  content: string
  created_at: string
  profile?: {
    id: string
    username: string
    name: string
    avatar_url?: string
  }
}

export default function PostPage() {
  const params = useParams()
  const postId = params.id as string
  const [post, setPost] = useState<Post | null>(null)
  const [comments, setComments] = useState<Comment[]>([])
  const [newComment, setNewComment] = useState('')
  const [loading, setLoading] = useState(true)
  const [commentLoading, setCommentLoading] = useState(false)
  const [isLiked, setIsLiked] = useState(false)
  const router = useRouter()
  const supabase = useSupabase()
  const { user } = useSupabase()

  useEffect(() => {
    if (postId) {
      fetchPost()
      fetchComments()
    }
  }, [postId])

  const fetchPost = async () => {
    try {
      const { data, error } = await supabase
        .from('posts')
        .select(`
          *,
          profile:profiles(id, username, name, avatar_url)
        `)
        .eq('id', postId)
        .single()

      if (error) throw error
      setPost(data)

      // Check if user liked this post
      if (user) {
        const { data: like } = await supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .single()

        setIsLiked(!!like)
      }
    } catch (error) {
      console.error('Error fetching post:', error)
      toast.error('Ошибка загрузки поста')
    } finally {
      setLoading(false)
    }
  }

  const fetchComments = async () => {
    try {
      const { data, error } = await supabase
        .from('post_comments')
        .select(`
          *,
          profile:profiles(id, username, name, avatar_url)
        `)
        .eq('post_id', postId)
        .order('created_at', { ascending: true })

      if (error) throw error
      setComments(data || [])
    } catch (error) {
      console.error('Error fetching comments:', error)
    }
  }

  const handleLike = async () => {
    if (!user || !post) return

    try {
      if (isLiked) {
        // Remove like
        await supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id)

        setPost(prev => prev ? {
          ...prev,
          likes_count: Math.max(0, prev.likes_count - 1)
        } : null)
        setIsLiked(false)
      } else {
        // Add like
        await supabase
          .from('post_likes')
          .insert({ post_id: postId, user_id: user.id })

        setPost(prev => prev ? {
          ...prev,
          likes_count: prev.likes_count + 1
        } : null)
        setIsLiked(true)
      }
    } catch (error) {
      console.error('Error toggling like:', error)
      toast.error('Ошибка лайка')
    }
  }

  const handleComment = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user || !newComment.trim()) return

    setCommentLoading(true)
    try {
      const { data, error } = await supabase
        .from('post_comments')
        .insert({
          post_id: postId,
          user_id: user.id,
          content: newComment.trim()
        })
        .select(`
          *,
          profile:profiles(id, username, name, avatar_url)
        `)
        .single()

      if (error) throw error

      setComments(prev => [...prev, data])
      setPost(prev => prev ? {
        ...prev,
        comments_count: prev.comments_count + 1
      } : null)
      setNewComment('')
    } catch (error) {
      console.error('Error adding comment:', error)
      toast.error('Ошибка добавления комментария')
    } finally {
      setCommentLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-neutral-900 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
      </div>
    )
  }

  if (!post) {
    return (
      <div className="min-h-screen bg-neutral-900 flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-white mb-2">Пост не найден</h1>
          <p className="text-gray-400 mb-4">Пост мог быть удален или не существует</p>
          <button onClick={() => router.back()} className="btn-primary">
            Назад
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-neutral-900">
      <div className="sticky top-0 bg-neutral-900 border-b border-neutral-800 p-4">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="text-gray-400 hover:text-white"
          >
            <ArrowLeft size={24} />
          </button>
          <h1 className="text-lg font-semibold text-white">Пост</h1>
        </div>
      </div>

      <div className="p-4">
        {/* Post Content */}
        <div className="card p-4 mb-6">
          {/* Header */}
          <div className="flex items-center gap-3 mb-3">
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

            <div className="flex items-center gap-2 text-gray-400">
              <MessageCircle size={20} />
              <span className="text-sm">{post.comments_count}</span>
            </div>

            <button className="flex items-center gap-2 text-gray-400 hover:text-primary-400 transition-colors">
              <Share size={20} />
            </button>
          </div>
        </div>

        {/* Comments */}
        <div className="space-y-4">
          <h2 className="text-white font-semibold">Комментарии</h2>

          {comments.length === 0 ? (
            <p className="text-gray-400 text-center py-4">Пока нет комментариев</p>
          ) : (
            <div className="space-y-3">
              {comments.map((comment) => (
                <div key={comment.id} className="card p-3">
                  <div className="flex items-start gap-3">
                    <Image
                      src={comment.profile?.avatar_url || '/default-avatar.png'}
                      alt={comment.profile?.name || 'User'}
                      width={32}
                      height={32}
                      className="rounded-full border border-neutral-700"
                    />
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-white font-medium text-sm">
                          {comment.profile?.name || comment.profile?.username}
                        </span>
                        <span className="text-gray-400 text-xs">
                          {formatDate(comment.created_at)}
                        </span>
                      </div>
                      <p className="text-gray-300 text-sm">
                        {comment.content}
                      </p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Add Comment */}
          {user && (
            <form onSubmit={handleComment} className="card p-3">
              <div className="flex gap-3">
                <Image
                  src={user.user_metadata?.avatar_url || '/default-avatar.png'}
                  alt="Your avatar"
                  width={32}
                  height={32}
                  className="rounded-full border border-neutral-700"
                />
                <div className="flex-1 flex gap-2">
                  <input
                    type="text"
                    value={newComment}
                    onChange={(e) => setNewComment(e.target.value)}
                    placeholder="Добавить комментарий..."
                    className="input-field flex-1"
                    maxLength={500}
                  />
                  <button
                    type="submit"
                    disabled={commentLoading || !newComment.trim()}
                    className="btn-primary px-3"
                  >
                    <Send size={16} />
                  </button>
                </div>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  )
}
