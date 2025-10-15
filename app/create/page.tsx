'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Type, X } from 'lucide-react'
import { usePosts } from '@/lib/hooks/use-posts'
import { useCurrentProfile } from '@/lib/hooks/use-profile'
import MediaUpload from '@/components/media-upload'
import toast from 'react-hot-toast'

export default function CreatePostPage() {
  const [postType, setPostType] = useState<'text' | 'photo' | 'video'>('text')
  const [content, setContent] = useState('')
  const [mediaUrls, setMediaUrls] = useState<string[]>([])
  const [loading, setLoading] = useState(false)
  const router = useRouter()
  const { createPost } = usePosts()
  const { profile } = useCurrentProfile()

  const handleMediaUpload = (urls: string[]) => {
    setMediaUrls(urls)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!profile) return

    if (postType !== 'text' && mediaUrls.length === 0) {
      toast.error('Добавьте медиа файлы')
      return
    }

    if (postType === 'text' && !content.trim()) {
      toast.error('Введите текст поста')
      return
    }

    setLoading(true)

    try {
      await createPost({
        user_id: profile.id,
        type: postType,
        content: content.trim() || undefined,
        media_urls: mediaUrls,
        likes_count: 0,
        comments_count: 0,
      })

      toast.success('Пост создан!')
      router.push('/')
    } catch (error) {
      toast.error('Ошибка создания поста')
    } finally {
      setLoading(false)
    }
  }

  if (!profile) {
    return (
      <div className="min-h-screen bg-neutral-900 flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-white mb-2">Доступ запрещен</h1>
          <p className="text-gray-400">Войдите в аккаунт для создания постов</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-neutral-900">
      <div className="sticky top-0 bg-neutral-900 border-b border-neutral-800 p-4">
        <div className="flex items-center justify-between">
          <button
            onClick={() => router.back()}
            className="text-gray-400 hover:text-white"
          >
            <X size={24} />
          </button>
          <h1 className="text-lg font-semibold text-white">Создать пост</h1>
          <button
            onClick={handleSubmit}
            disabled={loading}
            className="btn-primary"
          >
            {loading ? 'Публикация...' : 'Опубликовать'}
          </button>
        </div>
      </div>

      <div className="p-4">
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Post Type Selector */}
          <div className="flex gap-2">
            {[
              { id: 'text', label: 'Текст', icon: Type },
              { id: 'photo', label: 'Фото', icon: ImageIcon },
              { id: 'video', label: 'Видео', icon: Video },
            ].map((type) => (
              <button
                key={type.id}
                type="button"
                onClick={() => setPostType(type.id as any)}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg transition-colors ${postType === type.id
                  ? 'bg-primary-600 text-white'
                  : 'bg-neutral-800 text-gray-400 hover:text-white'
                  }`}
              >
                <type.icon size={16} />
                <span>{type.label}</span>
              </button>
            ))}
          </div>

          {/* Content */}
          {postType === 'text' && (
            <div>
              <textarea
                value={content}
                onChange={(e) => setContent(e.target.value)}
                className="input-field w-full h-32 resize-none"
                placeholder="Что нового?"
                maxLength={2000}
              />
              <p className="text-gray-400 text-sm mt-1">
                {content.length}/2000 символов
              </p>
            </div>
          )}

          {/* Media Upload */}
          {(postType === 'photo' || postType === 'video') && (
            <MediaUpload
              onUpload={handleMediaUpload}
              type={postType}
              multiple={postType === 'photo'}
              maxFiles={postType === 'photo' ? 10 : 1}
            />
          )}

          {/* Mixed Content */}
          {postType !== 'text' && (
            <div>
              <textarea
                value={content}
                onChange={(e) => setContent(e.target.value)}
                className="input-field w-full h-24 resize-none"
                placeholder="Добавить описание..."
                maxLength={1000}
              />
              <p className="text-gray-400 text-sm mt-1">
                {content.length}/1000 символов
              </p>
            </div>
          )}
        </form>
      </div>
    </div>
  )
}