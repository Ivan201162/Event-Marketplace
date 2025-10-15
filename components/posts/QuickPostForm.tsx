'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Image from 'next/image'
import { Plus, Image as ImageIcon, Video, Type } from 'lucide-react'
import { cn } from '@/utils/cn'
import { Profile } from '@/types'

interface QuickPostFormProps {
  user: Profile
}

export default function QuickPostForm({ user }: QuickPostFormProps) {
  const [content, setContent] = useState('')
  const [isExpanded, setIsExpanded] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const router = useRouter()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!content.trim()) return

    setIsLoading(true)

    try {
      const response = await fetch('/api/posts', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          content: content.trim(),
          type: 'text',
        }),
      })

      if (response.ok) {
        setContent('')
        setIsExpanded(false)
        router.refresh()
      }
    } catch (error) {
      console.error('Error creating post:', error)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="card p-6">
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="flex items-start space-x-3">
          {user.avatar_url ? (
            <Image
              src={user.avatar_url}
              alt={user.name}
              width={40}
              height={40}
              className="rounded-full"
            />
          ) : (
            <div className="h-10 w-10 rounded-full bg-primary flex items-center justify-center">
              <span className="text-primary-foreground font-medium text-sm">
                {user.name.charAt(0).toUpperCase()}
              </span>
            </div>
          )}

          <div className="flex-1">
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              onFocus={() => setIsExpanded(true)}
              placeholder="Поделитесь своими мыслями..."
              className="input min-h-[40px] max-h-[120px] resize-none border-0 p-0 focus:ring-0 focus:border-0"
              rows={isExpanded ? 3 : 1}
            />
          </div>
        </div>

        {isExpanded && (
          <div className="flex items-center justify-between pt-4 border-t">
            <div className="flex items-center space-x-2">
              <button
                type="button"
                onClick={() => router.push('/create?type=photo')}
                className="btn btn-ghost p-2"
                title="Добавить фото"
              >
                <ImageIcon className="h-5 w-5" />
              </button>
              
              <button
                type="button"
                onClick={() => router.push('/create?type=video')}
                className="btn btn-ghost p-2"
                title="Добавить видео"
              >
                <Video className="h-5 w-5" />
              </button>
              
              <button
                type="button"
                onClick={() => router.push('/create')}
                className="btn btn-ghost p-2"
                title="Расширенный редактор"
              >
                <Type className="h-5 w-5" />
              </button>
            </div>

            <div className="flex items-center space-x-2">
              <button
                type="button"
                onClick={() => {
                  setContent('')
                  setIsExpanded(false)
                }}
                className="btn btn-ghost"
              >
                Отмена
              </button>
              
              <button
                type="submit"
                disabled={!content.trim() || isLoading}
                className="btn btn-primary"
              >
                {isLoading ? 'Публикация...' : 'Опубликовать'}
              </button>
            </div>
          </div>
        )}
      </form>
    </div>
  )
}
