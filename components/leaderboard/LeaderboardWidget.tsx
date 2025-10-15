'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { Trophy, User } from 'lucide-react'
import { LeaderboardUser } from '@/types'

export default function LeaderboardWidget() {
  const [leaderboard, setLeaderboard] = useState<LeaderboardUser[]>([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchLeaderboard = async () => {
      try {
        const response = await fetch('/api/leaderboard')
        if (response.ok) {
          const data = await response.json()
          setLeaderboard(data)
        }
      } catch (error) {
        console.error('Error fetching leaderboard:', error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchLeaderboard()
  }, [])

  if (isLoading) {
    return (
      <div className="card p-6">
        <h3 className="text-lg font-semibold text-foreground mb-4 flex items-center">
          <Trophy className="h-5 w-5 mr-2 text-yellow-500" />
          Лучшие за неделю
        </h3>
        <div className="space-y-3">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="flex items-center space-x-3 animate-pulse">
              <div className="h-8 w-8 bg-secondary rounded-full" />
              <div className="flex-1 space-y-1">
                <div className="h-4 bg-secondary rounded w-3/4" />
                <div className="h-3 bg-secondary rounded w-1/2" />
              </div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="card p-6">
      <h3 className="text-lg font-semibold text-foreground mb-4 flex items-center">
        <Trophy className="h-5 w-5 mr-2 text-yellow-500" />
        Лучшие за неделю
      </h3>
      
      {leaderboard.length === 0 ? (
        <p className="text-muted-foreground text-sm">
          Пока нет данных для рейтинга
        </p>
      ) : (
        <div className="space-y-3">
          {leaderboard.slice(0, 10).map((user, index) => (
            <Link
              key={user.id}
              href={`/u/${user.username}`}
              className="flex items-center space-x-3 p-2 rounded-lg hover:bg-accent transition-colors"
            >
              <div className="flex items-center justify-center w-8 h-8 rounded-full bg-primary/10 text-primary font-semibold text-sm">
                {index + 1}
              </div>
              
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
              
              <div className="flex-1 min-w-0">
                <p className="font-medium text-foreground truncate">
                  {user.name}
                </p>
                <p className="text-sm text-muted-foreground truncate">
                  @{user.username}
                </p>
              </div>
              
              <div className="text-right">
                <p className="text-sm font-medium text-foreground">
                  {user.score}
                </p>
                <p className="text-xs text-muted-foreground">
                  очков
                </p>
              </div>
            </Link>
          ))}
        </div>
      )}
      
      <div className="mt-4 pt-4 border-t">
        <Link
          href="/leaderboard"
          className="text-sm text-primary hover:underline"
        >
          Посмотреть полный рейтинг
        </Link>
      </div>
    </div>
  )
}
