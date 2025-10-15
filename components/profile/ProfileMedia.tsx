'use client'

import { useEffect, useState } from 'react'
import Image from 'next/image'
import { createClient } from '@/lib/supabase/client'
import { Image as ImageIcon, Video, FileImage } from 'lucide-react'

interface ProfileMediaProps {
  profile: {
    id: string
    username: string
  }
}

interface MediaItem {
  id: string
  type: 'photo' | 'video'
  url: string
  created_at: string
}

export default function ProfileMedia({ profile }: ProfileMediaProps) {
  const [media, setMedia] = useState<MediaItem[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const supabase = createClient()

  useEffect(() => {
    const fetchMedia = async () => {
      try {
        const { data, error } = await supabase
          .from('posts')
          .select('id, type, media_urls, created_at')
          .eq('author_id', profile.id)
          .not('media_urls', 'is', null)
          .order('created_at', { ascending: false })

        if (error) {
          console.error('Error fetching media:', error)
        } else {
          const mediaItems: MediaItem[] = []
          data.forEach(post => {
            if (post.media_urls && Array.isArray(post.media_urls)) {
              post.media_urls.forEach((url: string) => {
                mediaItems.push({
                  id: `${post.id}-${url}`,
                  type: post.type === 'photo' ? 'photo' : 'video',
                  url,
                  created_at: post.created_at,
                })
              })
            }
          })
          setMedia(mediaItems)
        }
      } catch (error) {
        console.error('Error:', error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchMedia()
  }, [profile.id, supabase])

  if (isLoading) {
    return (
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
        {[...Array(8)].map((_, i) => (
          <div key={i} className="aspect-square bg-secondary rounded-lg animate-pulse" />
        ))}
      </div>
    )
  }

  if (media.length === 0) {
    return (
      <div className="text-center py-12">
        <FileImage className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
        <h3 className="text-lg font-medium text-foreground mb-2">
          Нет медиа
        </h3>
        <p className="text-muted-foreground">
          Этот пользователь еще не опубликовал ни одного фото или видео
        </p>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
      {media.map((item) => (
        <div key={item.id} className="group relative aspect-square rounded-lg overflow-hidden bg-secondary">
          {item.type === 'photo' ? (
            <Image
              src={item.url}
              alt="Media"
              fill
              className="object-cover group-hover:scale-105 transition-transform duration-200"
            />
          ) : (
            <div className="relative w-full h-full">
              <video
                src={item.url}
                className="w-full h-full object-cover"
                muted
              />
              <div className="absolute inset-0 flex items-center justify-center">
                <Video className="h-8 w-8 text-white drop-shadow-lg" />
              </div>
            </div>
          )}
          
          <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors duration-200" />
          
          <div className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
            {item.type === 'photo' ? (
              <ImageIcon className="h-4 w-4 text-white drop-shadow-lg" />
            ) : (
              <Video className="h-4 w-4 text-white drop-shadow-lg" />
            )}
          </div>
        </div>
      ))}
    </div>
  )
}
