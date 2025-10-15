'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Home, Plus, Search, Trophy, User } from 'lucide-react'
import { cn } from '@/utils/cn'

interface SidebarProps {
  user?: {
    id: string
    username: string
    name: string
    avatar_url?: string | null
  }
}

export default function Sidebar({ user }: SidebarProps) {
  const pathname = usePathname()

  const navigation = [
    {
      name: 'Главная',
      href: '/',
      icon: Home,
    },
    {
      name: 'Создать пост',
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
  ]

  if (!user) {
    return null
  }

  return (
    <aside className="hidden md:flex md:w-64 md:flex-col md:fixed md:inset-y-0 md:pt-16">
      <div className="flex-1 flex flex-col min-h-0 bg-card border-r">
        <div className="flex-1 flex flex-col pt-5 pb-4 overflow-y-auto">
          <nav className="mt-5 flex-1 px-2 space-y-1">
            {navigation.map((item) => {
              const isActive = pathname === item.href
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={cn(
                    'group flex items-center px-2 py-2 text-sm font-medium rounded-md transition-colors',
                    isActive
                      ? 'bg-primary text-primary-foreground'
                      : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
                  )}
                >
                  <item.icon
                    className={cn(
                      'mr-3 flex-shrink-0 h-5 w-5',
                      isActive ? 'text-primary-foreground' : 'text-muted-foreground group-hover:text-accent-foreground'
                    )}
                  />
                  {item.name}
                </Link>
              )
            })}
          </nav>
        </div>
      </div>
    </aside>
  )
}
