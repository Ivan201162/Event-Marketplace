'use client'

import useSWR from 'swr'
import Image from 'next/image'
import Link from 'next/link'
import { WeeklyStats } from '@/lib/types'

const fetcher = (url: string) => fetch(url).then(r => r.json())

export default function BestSpecialists() {
  const { data, error } = useSWR<WeeklyStats[]>('/api/leaderboard', fetcher)

  if (error) return null
  if (!data || data.length === 0) return null

  return (
    <div className="px-4 py-3 bg-neutral-900 border-b border-neutral-800">
      <h2 className="text-white font-semibold mb-3 flex items-center gap-2">
        🏆 Лучшие специалисты недели
      </h2>
      <div className="flex overflow-x-auto gap-4 pb-2 scrollbar-hide">
        {data.map((user) => (
          <Link
            href={`/u/${user.username}`}
            key={user.user_id}
            className="flex-shrink-0 w-20 text-center group"
          >
            <div className="relative">
              <Image
                src={user.avatar_url || '/default-avatar.png'}
                alt={user.username}
                width={64}
                height={64}
                className="rounded-full mx-auto mb-2 border-2 border-neutral-700 group-hover:border-primary-500 transition-colors"
              />
              <div className="absolute -top-1 -right-1 bg-primary-600 text-white text-xs rounded-full w-6 h-6 flex items-center justify-center font-bold">
                {data.indexOf(user) + 1}
              </div>
            </div>
            <p className="text-sm text-white truncate font-medium">
              {user.name || user.username}
            </p>
            <p className="text-xs text-gray-400">
              {user.score_7d} очков
            </p>
          </Link>
        ))}
      </div>
    </div>
  )
}
