'use client'

import { usePathname } from 'next/navigation'
import Link from 'next/link'
import { Home, Search, Plus, Bell, User } from 'lucide-react'
import { useSupabase } from '@/lib/providers/supabase-provider'

export default function MobileNav() {
  const pathname = usePathname()
  const { user } = useSupabase()

  const username = user?.user_metadata?.username || ''

  const navItems = [
    {
      href: '/',
      icon: Home,
      label: 'Главная',
    },
    {
      href: '/search',
      icon: Search,
      label: 'Поиск',
    },
    {
      href: '/create',
      icon: Plus,
      label: 'Создать',
    },
    {
      href: '/notifications',
      icon: Bell,
      label: 'Уведомления',
    },
    {
      href: `/u/${username}`,
      icon: User,
      label: 'Профиль',
    },
  ]

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-neutral-900 border-t border-neutral-800 md:hidden">
      <div className="flex items-center justify-around py-2">
        {navItems.map((item) => {
          const isActive = pathname === item.href
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex flex-col items-center gap-1 px-3 py-2 rounded-lg transition-colors ${isActive
                  ? 'text-primary-400'
                  : 'text-gray-400 hover:text-white'
                }`}
            >
              <item.icon size={20} />
              <span className="text-xs">{item.label}</span>
            </Link>
          )
        })}
      </div>
    </div>
  )
}
