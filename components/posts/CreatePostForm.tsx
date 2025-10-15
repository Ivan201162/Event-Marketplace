'use client'

import { useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Upload, X, Image as ImageIcon, Video, Type } from 'lucide-react'
import { cn } from '@/utils/cn'
import toast from 'react-hot-toast'

export default function CreatePostForm() {
  const [content, setContent] = useState('')
  const [type, setType] = useState<'text' | 'photo' | 'video' | 'reel'>('text')
  const [mediaFiles, setMediaFiles] = useState<File[]>([])
  const [mediaUrls, setMediaUrls] = useState<string[]>([])
  const [isUploading, setIsUploading] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const router = useRouter()
  const searchParams = useSearchParams()
  const supabase = createClient()

  // Set type from URL params
  useState(() => {
    const typeParam = searchParams.get('type')
    if (typeParam && ['text', 'photo', 'video', 'reel'].includes(typeParam)) {
      setType(typeParam as any)
    }
  })

  const handleFileUpload = async (files: FileList | null) => {
    if (!files || files.length === 0) return

    setIsUploading(true)

    try {
      const uploadPromises = Array.from(files).map(async (file) => {
        const fileExt = file.name.split('.').pop()
        const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`
        const filePath = `posts/${fileName}`

        const { error: uploadError } = await supabase.storage
          .from('media')
          .upload(filePath, file)

        if (uploadError) {
          throw uploadError
        }

        const { data } = supabase.storage
          .from('media')
          .getPublicUrl(filePath)

        return data.publicUrl
      })

      const urls = await Promise.all(uploadPromises)
      setMediaUrls(prev => [...prev, ...urls])
      setMediaFiles(prev => [...prev, ...Array.from(files)])
    } catch (error) {
      console.error('Error uploading files:', error)
      toast.error('Ошибка при загрузке файлов')
    } finally {
      setIsUploading(false)
    }
  }

  const removeMedia = (index: number) => {
    setMediaUrls(prev => prev.filter((_, i) => i !== index))
    setMediaFiles(prev => prev.filter((_, i) => i !== index))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!content.trim() && mediaUrls.length === 0) {
      toast.error('Добавьте текст или медиа')
      return
    }

    setIsSubmitting(true)

    try {
      const response = await fetch('/api/posts', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          content: content.trim() || null,
          type,
          media_urls: mediaUrls.length > 0 ? mediaUrls : null,
        }),
      })

      if (response.ok) {
        toast.success('Пост опубликован!')
        router.push('/')
      } else {
        toast.error('Ошибка при публикации поста')
      }
    } catch (error) {
      console.error('Error creating post:', error)
      toast.error('Произошла ошибка')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto">
      <div className="card p-6">
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Post Type Selector */}
          <div>
            <label className="block text-sm font-medium text-foreground mb-3">
              Тип поста
            </label>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              {[
                { value: 'text', label: 'Текст', icon: Type },
                { value: 'photo', label: 'Фото', icon: ImageIcon },
                { value: 'video', label: 'Видео', icon: Video },
                { value: 'reel', label: 'Reel', icon: Video },
              ].map(({ value, label, icon: Icon }) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => setType(value as any)}
                  className={cn(
                    'flex flex-col items-center p-3 rounded-lg border transition-colors',
                    type === value
                      ? 'border-primary bg-primary/10 text-primary'
                      : 'border-border hover:bg-accent'
                  )}
                >
                  <Icon className="h-5 w-5 mb-1" />
                  <span className="text-sm">{label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Content */}
          <div>
            <label htmlFor="content" className="block text-sm font-medium text-foreground mb-2">
              Содержание
            </label>
            <textarea
              id="content"
              value={content}
              onChange={(e) => setContent(e.target.value)}
              className="input min-h-[120px] resize-none"
              placeholder="Поделитесь своими мыслями..."
              maxLength={2000}
            />
            <div className="text-right text-sm text-muted-foreground mt-1">
              {content.length}/2000
            </div>
          </div>

          {/* Media Upload */}
          {(type === 'photo' || type === 'video' || type === 'reel') && (
            <div>
              <label className="block text-sm font-medium text-foreground mb-2">
                Медиа файлы
              </label>
              
              <div className="border-2 border-dashed border-border rounded-lg p-6 text-center">
                <input
                  type="file"
                  multiple
                  accept={type === 'photo' ? 'image/*' : 'video/*'}
                  onChange={(e) => handleFileUpload(e.target.files)}
                  className="hidden"
                  id="media-upload"
                />
                <label
                  htmlFor="media-upload"
                  className="cursor-pointer flex flex-col items-center space-y-2"
                >
                  <Upload className="h-8 w-8 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">
                    {isUploading ? 'Загрузка...' : 'Нажмите для загрузки файлов'}
                  </span>
                </label>
              </div>

              {/* Media Preview */}
              {mediaUrls.length > 0 && (
                <div className="mt-4 space-y-3">
                  {mediaUrls.map((url, index) => (
                    <div key={index} className="relative group">
                      {type === 'photo' ? (
                        <img
                          src={url}
                          alt={`Upload ${index + 1}`}
                          className="w-full h-48 object-cover rounded-lg"
                        />
                      ) : (
                        <video
                          src={url}
                          controls
                          className="w-full h-48 object-cover rounded-lg"
                        />
                      )}
                      <button
                        type="button"
                        onClick={() => removeMedia(index)}
                        className="absolute top-2 right-2 p-1 bg-destructive text-destructive-foreground rounded-full opacity-0 group-hover:opacity-100 transition-opacity"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Submit Button */}
          <div className="flex justify-end space-x-3">
            <button
              type="button"
              onClick={() => router.back()}
              className="btn btn-outline"
            >
              Отмена
            </button>
            <button
              type="submit"
              disabled={isSubmitting || isUploading || (!content.trim() && mediaUrls.length === 0)}
              className="btn btn-primary"
            >
              {isSubmitting ? 'Публикация...' : 'Опубликовать'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
