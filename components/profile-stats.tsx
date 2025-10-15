'use client'

import { useState, useEffect } from 'react'
import { useSupabase } from '@/lib/providers/supabase-provider'

interface ProfileStatsProps {
  userId: string
  className?: string
}

interface Stats {
  postsCount: number
  followersCount: number
  followingCount: number
}

export default function ProfileStats({ userId, className = '' }: ProfileStatsProps) {
  const [stats, setStats] = useState<Stats>({
    postsCount: 0,
    followersCount: 0,
    followingCount: 0,
  })
  const [loading, setLoading] = useState(true)
  const supabase = useSupabase()

  useEffect(() => {
    fetchStats()
  }, [userId])

  const fetchStats = async () => {
    try {
      // Fetch posts count
      const { count: postsCount } = await supabase
        .from('posts')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId)

      // Fetch followers count
      const { count: followersCount } = await supabase
        .from('follows')
        .select('*', { count: 'exact', head: true })
        .eq('following_id', userId)

      // Fetch following count
      const { count: followingCount } = await supabase
        .from('follows')
        .select('*', { count: 'exact', head: true })
        .eq('follower_id', userId)

      setStats({
        postsCount: postsCount || 0,
        followersCount: followersCount || 0,
        followingCount: followingCount || 0,
      })
    } catch (error) {
      console.error('Error fetching stats:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className={`grid grid-cols-3 gap-4 text-center ${className}`}>
        {[1, 2, 3].map((i) => (
          <div key={i}>
            <div className="animate-pulse bg-neutral-700 h-6 rounded mb-1"></div>
            <div className="animate-pulse bg-neutral-700 h-4 rounded w-16 mx-auto"></div>
          </div>
        ))}
      </div>
    )
  }

  return (
    <div className={`grid grid-cols-3 gap-4 text-center ${className}`}>
      <div>
        <p className="text-2xl font-bold text-white">{stats.postsCount}</p>
        <p className="text-gray-400 text-sm">Постов</p>
      </div>
      <div>
        <p className="text-2xl font-bold text-white">{stats.followersCount}</p>
        <p className="text-gray-400 text-sm">Подписчиков</p>
      </div>
      <div>
        <p className="text-2xl font-bold text-white">{stats.followingCount}</p>
        <p className="text-gray-400 text-sm">Подписок</p>
      </div>
    </div>
  )
}
