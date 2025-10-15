'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'
import { User, Shield, Bell, LogOut, ArrowLeft } from 'lucide-react'
import Link from 'next/link'
import toast from 'react-hot-toast'

export default function SettingsPage() {
  const router = useRouter()
  const supabase = createClientComponentClient()

  const handleSignOut = async () => {
    try {
      await supabase.auth.signOut()
      toast.success('Вы вышли из аккаунта')
      router.push('/auth/sign-in')
    } catch (error) {
      toast.error('Ошибка выхода')
    }
  }

  const settingsItems = [
    {
      icon: User,
      title: 'Профиль',
      description: 'Редактировать данные профиля',
      href: '/settings/profile',
    },
    {
      icon: Shield,
      title: 'Безопасность',
      description: 'Пароль и безопасность аккаунта',
      href: '/settings/security',
    },
    {
      icon: Bell,
      title: 'Уведомления',
      description: 'Настройки уведомлений',
      href: '/settings/notifications',
    },
  ]

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
          <h1 className="text-lg font-semibold text-white">Настройки</h1>
        </div>
      </div>

      <div className="p-4 space-y-4">
        {settingsItems.map((item, index) => (
          <Link
            key={index}
            href={item.href}
            className="card p-4 block hover:bg-neutral-700 transition-colors"
          >
            <div className="flex items-center gap-4">
              <div className="p-2 bg-neutral-700 rounded-lg">
                <item.icon size={20} className="text-white" />
              </div>
              <div className="flex-1">
                <h3 className="text-white font-medium">{item.title}</h3>
                <p className="text-gray-400 text-sm">{item.description}</p>
              </div>
            </div>
          </Link>
        ))}

        <div className="pt-4 border-t border-neutral-800">
          <button
            onClick={handleSignOut}
            className="w-full card p-4 text-left hover:bg-red-900/20 transition-colors group"
          >
            <div className="flex items-center gap-4">
              <div className="p-2 bg-red-600 rounded-lg">
                <LogOut size={20} className="text-white" />
              </div>
              <div className="flex-1">
                <h3 className="text-red-400 font-medium group-hover:text-red-300">
                  Выйти из аккаунта
                </h3>
                <p className="text-gray-400 text-sm">
                  Завершить текущую сессию
                </p>
              </div>
            </div>
          </button>
        </div>
      </div>
    </div>
  )
}