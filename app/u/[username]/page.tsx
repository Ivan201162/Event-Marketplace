'use client'

import { useState } from 'react'
import { useParams } from 'next/navigation'
import Image from 'next/image'
import Link from 'next/link'
import { MapPin, Link as LinkIcon, UserPlus, MessageCircle, Heart, Share } from 'lucide-react'
import { useProfile } from '@/lib/hooks/use-profile'
import { useSupabase } from '@/lib/providers/supabase-provider'
import { formatDate } from '@/lib/utils'
import ProfileStats from '@/components/profile-stats'
import toast from 'react-hot-toast'

export default function ProfilePage() {
  const params = useParams()
  const username = params.username as string
  const { profile, loading, error } = useProfile(username)
  const { user } = useSupabase()
  const [isFollowing, setIsFollowing] = useState(false)
  const [activeTab, setActiveTab] = useState<'posts' | 'about' | 'media'>('posts')

  const isOwnProfile = user?.id === profile?.id

  const handleFollow = async () => {
    if (!user || !profile) return

    try {
      // TODO: Implement follow/unfollow logic
      setIsFollowing(!isFollowing)
      toast.success(isFollowing ? 'Отписались' : 'Подписались')
    } catch (error) {
      toast.error('Ошибка подписки')
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-neutral-900 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
      </div>
    )
  }

  if (error || !profile) {
    return (
      <div className="min-h-screen bg-neutral-900 flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-white mb-2">Профиль не найден</h1>
          <p className="text-gray-400 mb-4">Пользователь с таким username не существует</p>
          <Link href="/" className="btn-primary">
            На главную
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-neutral-900">
      {/* Header */}
      <div className="bg-neutral-800 border-b border-neutral-700">
        <div className="px-4 py-6">
          <div className="flex items-start gap-4">
            <Image
              src={profile.avatar_url || '/default-avatar.png'}
              alt={profile.name}
              width={100}
              height={100}
              className="rounded-full border-4 border-neutral-700"
            />
            <div className="flex-1">
              <h1 className="text-2xl font-bold text-white mb-1">{profile.name}</h1>
              <p className="text-gray-400 mb-2">@{profile.username}</p>

              {profile.city && (
                <div className="flex items-center gap-1 text-gray-400 mb-2">
                  <MapPin size={16} />
                  <span>{profile.city}</span>
                </div>
              )}

              {profile.bio && (
                <p className="text-gray-300 mb-4">{profile.bio}</p>
              )}

              <div className="flex gap-3">
                {isOwnProfile ? (
                  <Link href="/settings/profile" className="btn-primary">
                    Редактировать профиль
                  </Link>
                ) : (
                  <>
                    <button
                      onClick={handleFollow}
                      className={`px-4 py-2 rounded-lg font-medium transition-colors ${isFollowing
                        ? 'bg-neutral-700 text-white hover:bg-neutral-600'
                        : 'bg-primary-600 text-white hover:bg-primary-700'
                        }`}
                    >
                      {isFollowing ? 'Отписаться' : 'Подписаться'}
                    </button>
                    <button className="btn-secondary flex items-center gap-2">
                      <MessageCircle size={16} />
                      Сообщение
                    </button>
                  </>
                )}
                <button className="btn-secondary">
                  <Share size={16} />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="bg-neutral-800 border-b border-neutral-700">
        <div className="px-4 py-4">
          <ProfileStats userId={profile.id} />
        </div>
      </div>

      {/* Tabs */}
      <div className="bg-neutral-800 border-b border-neutral-700">
        <div className="flex">
          {[
            { id: 'posts', label: 'Посты' },
            { id: 'about', label: 'О специалисте' },
            { id: 'media', label: 'Медиа' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`px-6 py-3 font-medium transition-colors ${activeTab === tab.id
                ? 'text-primary-400 border-b-2 border-primary-400'
                : 'text-gray-400 hover:text-white'
                }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="p-4">
        {activeTab === 'posts' && (
          <div className="text-center py-8">
            <p className="text-gray-400">Пока нет постов</p>
          </div>
        )}

        {activeTab === 'about' && (
          <div className="space-y-6">
            {profile.skills.length > 0 && (
              <div>
                <h3 className="text-white font-semibold mb-3">Навыки</h3>
                <div className="flex flex-wrap gap-2">
                  {profile.skills.map((skill, index) => (
                    <span
                      key={index}
                      className="bg-primary-600 text-white px-3 py-1 rounded-full text-sm"
                    >
                      {skill}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {profile.links.length > 0 && (
              <div>
                <h3 className="text-white font-semibold mb-3">Ссылки</h3>
                <div className="space-y-2">
                  {profile.links.map((link, index) => (
                    <a
                      key={index}
                      href={link}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center gap-2 text-primary-400 hover:text-primary-300 transition-colors"
                    >
                      <LinkIcon size={16} />
                      <span className="truncate">{link}</span>
                    </a>
                  ))}
                </div>
              </div>
            )}

            <div>
              <h3 className="text-white font-semibold mb-3">Информация</h3>
              <div className="space-y-2 text-gray-400">
                <p>Зарегистрирован: {formatDate(profile.created_at)}</p>
                <p>Последнее обновление: {formatDate(profile.updated_at)}</p>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'media' && (
          <div className="text-center py-8">
            <p className="text-gray-400">Пока нет медиа</p>
          </div>
        )}
      </div>
    </div>
  )
}