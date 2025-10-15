'use client'

import Image from 'next/image'
import { useRouter } from 'next/navigation'
import { useSupabase } from '@/lib/providers/supabase-provider'
import { Bell, Settings, Search } from 'lucide-react'

export default function HomeHeader() {
  const router = useRouter()
  const { user } = useSupabase()

  const avatar = user?.user_metadata?.avatar_url || '/default-avatar.png'
  const username = user?.user_metadata?.username || ''

  return (
    <div className="flex items-center gap-4 px-4 py-3 bg-neutral-900 border-b border-neutral-800">
      <button
        onClick={() => router.push(`/u/${username}`)}
        className="flex-shrink-0"
      >
        <Image
          src={avatar}
          width={40}
          height={40}
          className="rounded-full border-2 border-neutral-700"
          alt="Avatar"
        />
      </button>

      <div className="flex flex-1 items-center bg-neutral-800 rounded-lg px-3 py-2 border border-neutral-700">
        <Search size={18} className="text-gray-400 mr-2 flex-shrink-0" />
        <input
          type="text"
          placeholder="Найти специалиста..."
          className="bg-transparent text-white flex-1 outline-none placeholder-gray-400"
          onFocus={() => router.push('/search')}
        />
      </div>

      <button
        onClick={() => router.push('/notifications')}
        className="p-2 hover:bg-neutral-800 rounded-lg transition-colors"
      >
        <Bell size={20} className="text-white" />
      </button>

      <button
        onClick={() => router.push('/settings')}
        className="p-2 hover:bg-neutral-800 rounded-lg transition-colors"
      >
        <Settings size={20} className="text-white" />
      </button>
    </div>
  )
}
