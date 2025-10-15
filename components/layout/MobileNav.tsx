'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Home, Plus, Search, Trophy, User } from 'lucide-react'
import { cn } from '@/utils/cn'

interface MobileNavProps {
  user?: {
    id: string
    username: string
    name: string
    avatar_url?: string | null
  }
}

export default function MobileNav({ user }: MobileNavProps) {
  const pathname = usePathname()

  const navigation = [
    {
      name: 'Главная',
      href: '/',
      icon: Home,
    },
    {
      name: 'Создать',
      href: '/create',
      icon: Plus,
    },
    {
      name: 'Поиск',
      href: '/search',
      icon: Search,
    },
    {
      name: 'Лучшие',
      href: '/leaderboard',
      icon: Trophy,
    },
    {
      name: 'Профиль',
      href: user ? `/u/${user.username}` : '/auth/sign-in',
      icon: User,
    },
  ]

  if (!user) {
    return null
  }

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-card border-t md:hidden">
      <div className="flex items-center justify-around h-16">
        {navigation.map((item) => {
          const isActive = pathname === item.href
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                'flex flex-col items-center justify-center p-2 rounded-lg transition-colors min-w-0 flex-1',
                isActive
                  ? 'text-primary'
                  : 'text-muted-foreground hover:text-accent-foreground'
              )}
            >
              <item.icon
                className={cn(
                  'h-5 w-5 mb-1',
                  isActive ? 'text-primary' : 'text-muted-foreground'
                )}
              />
              <span className="text-xs truncate">{item.name}</span>
            </Link>
          )
        })}
      </div>
    </nav>
  )
}
