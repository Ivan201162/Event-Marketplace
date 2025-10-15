'use client'

import { useState, useEffect } from 'react'
import { Bell, Heart, MessageCircle, UserPlus, ArrowLeft } from 'lucide-react'
import { useRouter } from 'next/navigation'
import { useSupabase } from '@/lib/providers/supabase-provider'
import { formatDate } from '@/lib/utils'

interface Notification {
  id: string
  type: 'like' | 'comment' | 'follow' | 'mention'
  title: string
  message: string
  is_read: boolean
  created_at: string
  user_id?: string
  post_id?: string
}

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [loading, setLoading] = useState(true)
  const router = useRouter()
  const { user } = useSupabase()

  useEffect(() => {
    if (user) {
      fetchNotifications()
    }
  }, [user])

  const fetchNotifications = async () => {
    // TODO: Implement real notifications from database
    // For now, showing mock data
    setNotifications([
      {
        id: '1',
        type: 'like',
        title: 'Новый лайк',
        message: 'Анна Петрова поставила лайк вашему посту',
        is_read: false,
        created_at: new Date().toISOString(),
        user_id: 'user1',
        post_id: 'post1'
      },
      {
        id: '2',
        type: 'comment',
        title: 'Новый комментарий',
        message: 'Иван Сидоров прокомментировал ваш пост',
        is_read: false,
        created_at: new Date(Date.now() - 3600000).toISOString(),
        user_id: 'user2',
        post_id: 'post1'
      },
      {
        id: '3',
        type: 'follow',
        title: 'Новый подписчик',
        message: 'Мария Козлова подписалась на вас',
        is_read: true,
        created_at: new Date(Date.now() - 7200000).toISOString(),
        user_id: 'user3'
      }
    ])
    setLoading(false)
  }

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'like':
        return <Heart size={20} className="text-red-500" />
      case 'comment':
        return <MessageCircle size={20} className="text-blue-500" />
      case 'follow':
        return <UserPlus size={20} className="text-green-500" />
      default:
        return <Bell size={20} className="text-gray-500" />
    }
  }

  const markAsRead = async (notificationId: string) => {
    // TODO: Implement mark as read
    setNotifications(prev =>
      prev.map(notif =>
        notif.id === notificationId
          ? { ...notif, is_read: true }
          : notif
      )
    )
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-neutral-900 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
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
          <h1 className="text-lg font-semibold text-white">Уведомления</h1>
        </div>
      </div>

      <div className="p-4">
        {notifications.length === 0 ? (
          <div className="text-center py-8">
            <Bell size={48} className="text-gray-600 mx-auto mb-4" />
            <p className="text-gray-400">Пока нет уведомлений</p>
          </div>
        ) : (
          <div className="space-y-3">
            {notifications.map((notification) => (
              <div
                key={notification.id}
                className={`card p-4 cursor-pointer transition-colors ${!notification.is_read
                    ? 'bg-primary-900/20 border-primary-700'
                    : 'hover:bg-neutral-700'
                  }`}
                onClick={() => markAsRead(notification.id)}
              >
                <div className="flex items-start gap-3">
                  <div className="flex-shrink-0">
                    {getNotificationIcon(notification.type)}
                  </div>
                  <div className="flex-1">
                    <h3 className="text-white font-medium mb-1">
                      {notification.title}
                    </h3>
                    <p className="text-gray-300 text-sm mb-2">
                      {notification.message}
                    </p>
                    <p className="text-gray-400 text-xs">
                      {formatDate(notification.created_at)}
                    </p>
                  </div>
                  {!notification.is_read && (
                    <div className="w-2 h-2 bg-primary-500 rounded-full flex-shrink-0 mt-2"></div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
