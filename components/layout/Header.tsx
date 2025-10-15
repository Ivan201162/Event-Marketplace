'use client'

import { useState } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Search, Plus, Trophy, User, LogOut, Settings } from 'lucide-react'
import { cn } from '@/utils/cn'
import toast from 'react-hot-toast'

interface HeaderProps {
  user?: {
    id: string
    username: string
    name: string
    avatar_url?: string | null
  }
}

export default function Header({ user }: HeaderProps) {
  const [searchQuery, setSearchQuery] = useState('')
  const [isSearchFocused, setIsSearchFocused] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    if (searchQuery.trim()) {
      router.push(`/search?q=${encodeURIComponent(searchQuery.trim())}`)
      setSearchQuery('')
    }
  }

  const handleSignOut = async () => {
    const { error } = await supabase.auth.signOut()
    if (error) {
      toast.error('Ошибка при выходе')
    } else {
      router.push('/auth/sign-in')
    }
  }

  if (!user) {
    return (
      <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto px-4">
          <div className="flex h-16 items-center justify-between">
            <Link href="/" className="flex items-center space-x-2">
              <div className="h-8 w-8 rounded-lg bg-primary flex items-center justify-center">
                <span className="text-primary-foreground font-bold text-sm">EM</span>
              </div>
              <span className="font-bold text-xl">Event Marketplace</span>
            </Link>
            
            <div className="flex items-center space-x-4">
              <Link 
                href="/auth/sign-in" 
                className="btn btn-ghost"
              >
                Войти
              </Link>
              <Link 
                href="/auth/sign-up" 
                className="btn btn-primary"
              >
                Регистрация
              </Link>
            </div>
          </div>
        </div>
      </header>
    )
  }

  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container mx-auto px-4">
        <div className="flex h-16 items-center justify-between">
          <Link href="/" className="flex items-center space-x-2">
            <div className="h-8 w-8 rounded-lg bg-primary flex items-center justify-center">
              <span className="text-primary-foreground font-bold text-sm">EM</span>
            </div>
            <span className="font-bold text-xl">Event Marketplace</span>
          </Link>

          {/* Search */}
          <form onSubmit={handleSearch} className="flex-1 max-w-md mx-8">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <input
                type="text"
                placeholder="Поиск специалистов..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onFocus={() => setIsSearchFocused(true)}
                onBlur={() => setIsSearchFocused(false)}
                className={cn(
                  "input pl-10 w-full",
                  isSearchFocused && "ring-2 ring-primary"
                )}
              />
            </div>
          </form>

          {/* Navigation */}
          <div className="flex items-center space-x-4">
            <Link 
              href="/create" 
              className="btn btn-ghost p-2"
              title="Создать пост"
            >
              <Plus className="h-5 w-5" />
            </Link>
            
            <Link 
              href="/leaderboard" 
              className="btn btn-ghost p-2"
              title="Лучшие за неделю"
            >
              <Trophy className="h-5 w-5" />
            </Link>

            {/* User Menu */}
            <div className="relative group">
              <button className="flex items-center space-x-2 p-2 rounded-lg hover:bg-accent">
                {user.avatar_url ? (
                  <Image
                    src={user.avatar_url}
                    alt={user.name}
                    width={32}
                    height={32}
                    className="rounded-full"
                  />
                ) : (
                  <div className="h-8 w-8 rounded-full bg-primary flex items-center justify-center">
                    <User className="h-4 w-4 text-primary-foreground" />
                  </div>
                )}
              </button>

              {/* Dropdown Menu */}
              <div className="absolute right-0 top-full mt-2 w-48 bg-card border rounded-lg shadow-lg opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200">
                <div className="p-2">
                  <Link 
                    href={`/u/${user.username}`}
                    className="flex items-center space-x-2 p-2 rounded hover:bg-accent w-full text-left"
                  >
                    <User className="h-4 w-4" />
                    <span>Мой профиль</span>
                  </Link>
                  
                  <Link 
                    href="/settings/profile"
                    className="flex items-center space-x-2 p-2 rounded hover:bg-accent w-full text-left"
                  >
                    <Settings className="h-4 w-4" />
                    <span>Настройки</span>
                  </Link>
                  
                  <hr className="my-2" />
                  
                  <button
                    onClick={handleSignOut}
                    className="flex items-center space-x-2 p-2 rounded hover:bg-accent w-full text-left text-destructive"
                  >
                    <LogOut className="h-4 w-4" />
                    <span>Выйти</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>
  )
}
