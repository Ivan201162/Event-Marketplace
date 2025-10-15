'use client'

import { useState, useRef } from 'react'
import { Upload, X, Image as ImageIcon, Video, File } from 'lucide-react'
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'
import toast from 'react-hot-toast'

interface MediaUploadProps {
  onUpload: (urls: string[]) => void
  type: 'image' | 'video' | 'any'
  multiple?: boolean
  maxFiles?: number
  className?: string
}

export default function MediaUpload({
  onUpload,
  type,
  multiple = false,
  maxFiles = 5,
  className = ''
}: MediaUploadProps) {
  const [uploading, setUploading] = useState(false)
  const [previewUrls, setPreviewUrls] = useState<string[]>([])
  const fileInputRef = useRef<HTMLInputElement>(null)
  const supabase = createClientComponentClient()

  const handleFileSelect = async (files: FileList) => {
    if (files.length === 0) return

    const fileArray = Array.from(files)

    // Validate file types
    const validFiles = fileArray.filter(file => {
      if (type === 'image') {
        return file.type.startsWith('image/')
      } else if (type === 'video') {
        return file.type.startsWith('video/')
      }
      return true
    })

    if (validFiles.length !== fileArray.length) {
      toast.error(`Некоторые файлы не поддерживаются для типа ${type}`)
    }

    if (validFiles.length === 0) return

    // Check file count
    if (previewUrls.length + validFiles.length > maxFiles) {
      toast.error(`Максимум ${maxFiles} файлов`)
      return
    }

    setUploading(true)

    try {
      const uploadPromises = validFiles.map(async (file) => {
        const fileExt = file.name.split('.').pop()
        const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`

        const { data, error } = await supabase.storage
          .from('posts')
          .upload(fileName, file)

        if (error) throw error

        const { data: { publicUrl } } = supabase.storage
          .from('posts')
          .getPublicUrl(fileName)

        return publicUrl
      })

      const urls = await Promise.all(uploadPromises)
      const newPreviewUrls = [...previewUrls, ...urls]

      setPreviewUrls(newPreviewUrls)
      onUpload(newPreviewUrls)

      toast.success(`Загружено ${urls.length} файлов`)
    } catch (error) {
      console.error('Upload error:', error)
      toast.error('Ошибка загрузки файлов')
    } finally {
      setUploading(false)
    }
  }

  const removeFile = (index: number) => {
    const newUrls = previewUrls.filter((_, i) => i !== index)
    setPreviewUrls(newUrls)
    onUpload(newUrls)
  }

  const getFileIcon = (url: string) => {
    if (url.includes('image') || url.match(/\.(jpg|jpeg|png|gif|webp)$/i)) {
      return <ImageIcon size={20} className="text-blue-500" />
    } else if (url.includes('video') || url.match(/\.(mp4|mov|avi|mkv)$/i)) {
      return <Video size={20} className="text-red-500" />
    }
    return <File size={20} className="text-gray-500" />
  }

  return (
    <div className={className}>
      {/* Upload Button */}
      <div
        className="border-2 border-dashed border-neutral-700 rounded-lg p-6 text-center cursor-pointer hover:border-primary-500 transition-colors"
        onClick={() => fileInputRef.current?.click()}
      >
        <input
          ref={fileInputRef}
          type="file"
          accept={type === 'image' ? 'image/*' : type === 'video' ? 'video/*' : '*'}
          multiple={multiple}
          onChange={(e) => e.target.files && handleFileSelect(e.target.files)}
          className="hidden"
        />

        {uploading ? (
          <div className="flex flex-col items-center gap-2">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
            <span className="text-gray-400">Загрузка...</span>
          </div>
        ) : (
          <div className="flex flex-col items-center gap-2">
            <Upload size={32} className="text-gray-400" />
            <span className="text-gray-400">
              {type === 'image' ? 'Загрузить фото' :
                type === 'video' ? 'Загрузить видео' :
                  'Загрузить файлы'}
            </span>
            {multiple && (
              <span className="text-gray-500 text-sm">
                Максимум {maxFiles} файлов
              </span>
            )}
          </div>
        )}
      </div>

      {/* Preview */}
      {previewUrls.length > 0 && (
        <div className="mt-4">
          <div className="grid grid-cols-2 gap-2">
            {previewUrls.map((url, index) => (
              <div key={index} className="relative group">
                <div className="aspect-square bg-neutral-800 rounded-lg flex items-center justify-center">
                  {url.match(/\.(jpg|jpeg|png|gif|webp)$/i) ? (
                    <img
                      src={url}
                      alt={`Preview ${index + 1}`}
                      className="w-full h-full object-cover rounded-lg"
                    />
                  ) : (
                    <div className="flex flex-col items-center gap-2 text-gray-400">
                      {getFileIcon(url)}
                      <span className="text-xs">Файл {index + 1}</span>
                    </div>
                  )}
                </div>
                <button
                  onClick={() => removeFile(index)}
                  className="absolute top-2 right-2 bg-red-600 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  <X size={16} />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
