'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { Bell, ArrowLeft, Save } from 'lucide-react'
import toast from 'react-hot-toast'

interface NotificationSettings {
  likes: boolean
  comments: boolean
  follows: boolean
  mentions: boolean
  posts: boolean
  marketing: boolean
}

export default function NotificationSettingsPage() {
  const [settings, setSettings] = useState<NotificationSettings>({
    likes: true,
    comments: true,
    follows: true,
    mentions: true,
    posts: true,
    marketing: false,
  })
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  useEffect(() => {
    // Load saved settings from localStorage or API
    const savedSettings = localStorage.getItem('notification-settings')
    if (savedSettings) {
      setSettings(JSON.parse(savedSettings))
    }
  }, [])

  const handleSave = async () => {
    setLoading(true)

    try {
      // Save to localStorage (in real app, save to database)
      localStorage.setItem('notification-settings', JSON.stringify(settings))

      // TODO: Save to database via API

      toast.success('Настройки уведомлений сохранены')
    } catch (error) {
      toast.error('Ошибка сохранения настроек')
    } finally {
      setLoading(false)
    }
  }

  const toggleSetting = (key: keyof NotificationSettings) => {
    setSettings(prev => ({
      ...prev,
      [key]: !prev[key]
    }))
  }

  const notificationTypes = [
    {
      key: 'likes' as keyof NotificationSettings,
      title: 'Лайки',
      description: 'Уведомления о новых лайках ваших постов',
    },
    {
      key: 'comments' as keyof NotificationSettings,
      title: 'Комментарии',
      description: 'Уведомления о новых комментариях к вашим постам',
    },
    {
      key: 'follows' as keyof NotificationSettings,
      title: 'Подписки',
      description: 'Уведомления о новых подписчиках',
    },
    {
      key: 'mentions' as keyof NotificationSettings,
      title: 'Упоминания',
      description: 'Уведомления когда вас упоминают в постах',
    },
    {
      key: 'posts' as keyof NotificationSettings,
      title: 'Новые посты',
      description: 'Уведомления о новых постах от подписок',
    },
    {
      key: 'marketing' as keyof NotificationSettings,
      title: 'Маркетинг',
      description: 'Реклама и специальные предложения',
    },
  ]

  return (
    <div className="min-h-screen bg-neutral-900">
      <div className="sticky top-0 bg-neutral-900 border-b border-neutral-800 p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button
              onClick={() => router.back()}
              className="text-gray-400 hover:text-white"
            >
              <ArrowLeft size={24} />
            </button>
            <h1 className="text-lg font-semibold text-white">Уведомления</h1>
          </div>
          <button
            onClick={handleSave}
            disabled={loading}
            className="btn-primary flex items-center gap-2"
          >
            <Save size={16} />
            {loading ? 'Сохранение...' : 'Сохранить'}
          </button>
        </div>
      </div>

      <div className="p-4 space-y-6">
        {/* Header */}
        <div className="card p-6">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-primary-600 rounded-lg">
              <Bell size={20} className="text-white" />
            </div>
            <div>
              <h2 className="text-white font-semibold">Настройки уведомлений</h2>
              <p className="text-gray-400 text-sm">
                Выберите, какие уведомления вы хотите получать
              </p>
            </div>
          </div>
        </div>

        {/* Notification Types */}
        <div className="space-y-3">
          {notificationTypes.map((type) => (
            <div key={type.key} className="card p-4">
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <h3 className="text-white font-medium">{type.title}</h3>
                  <p className="text-gray-400 text-sm">{type.description}</p>
                </div>
                <button
                  onClick={() => toggleSetting(type.key)}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${settings[type.key] ? 'bg-primary-600' : 'bg-neutral-600'
                    }`}
                >
                  <span
                    className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${settings[type.key] ? 'translate-x-6' : 'translate-x-1'
                      }`}
                  />
                </button>
              </div>
            </div>
          ))}
        </div>

        {/* Additional Info */}
        <div className="card p-6">
          <h3 className="text-white font-semibold mb-3">Дополнительная информация</h3>
          <div className="space-y-2 text-gray-300 text-sm">
            <p>
              • Уведомления будут приходить в приложение и на email (если включены)
            </p>
            <p>
              • Вы можете изменить эти настройки в любое время
            </p>
            <p>
              • Некоторые уведомления могут приходить с задержкой
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
