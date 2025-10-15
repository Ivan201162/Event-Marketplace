'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { Search, User, MapPin, Tag } from 'lucide-react'
import { SearchResult } from '@/types'

interface SearchResultsProps {
  query: string
}

export default function SearchResults({ query }: SearchResultsProps) {
  const [results, setResults] = useState<SearchResult[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [hasSearched, setHasSearched] = useState(false)

  useEffect(() => {
    if (query.trim()) {
      searchProfiles(query.trim())
    } else {
      setResults([])
      setHasSearched(false)
    }
  }, [query])

  const searchProfiles = async (searchQuery: string) => {
    setIsLoading(true)
    setHasSearched(true)

    try {
      const response = await fetch(`/api/search?q=${encodeURIComponent(searchQuery)}`)
      if (response.ok) {
        const data = await response.json()
        setResults(data)
      }
    } catch (error) {
      console.error('Error searching profiles:', error)
    } finally {
      setIsLoading(false)
    }
  }

  if (!hasSearched) {
    return (
      <div className="text-center py-12">
        <Search className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
        <h3 className="text-lg font-medium text-foreground mb-2">
          Найдите специалистов
        </h3>
        <p className="text-muted-foreground">
          Введите имя, username или навык для поиска
        </p>
      </div>
    )
  }

  if (isLoading) {
    return (
      <div className="space-y-4">
        {[...Array(5)].map((_, i) => (
          <div key={i} className="card p-6 animate-pulse">
            <div className="flex items-center space-x-4">
              <div className="h-12 w-12 bg-secondary rounded-full" />
              <div className="flex-1 space-y-2">
                <div className="h-4 bg-secondary rounded w-1/3" />
                <div className="h-3 bg-secondary rounded w-1/2" />
                <div className="h-3 bg-secondary rounded w-2/3" />
              </div>
            </div>
          </div>
        ))}
      </div>
    )
  }

  if (results.length === 0) {
    return (
      <div className="text-center py-12">
        <Search className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
        <h3 className="text-lg font-medium text-foreground mb-2">
          Ничего не найдено
        </h3>
        <p className="text-muted-foreground">
          Попробуйте изменить поисковый запрос
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between mb-4">
        <p className="text-sm text-muted-foreground">
          Найдено {results.length} специалистов
        </p>
      </div>

      {results.map((profile) => (
        <div key={profile.id} className="card p-6">
          <div className="flex items-start space-x-4">
            <Link href={`/u/${profile.username}`}>
              {profile.avatar_url ? (
                <Image
                  src={profile.avatar_url}
                  alt={profile.name}
                  width={48}
                  height={48}
                  className="rounded-full"
                />
              ) : (
                <div className="h-12 w-12 rounded-full bg-primary flex items-center justify-center">
                  <User className="h-6 w-6 text-primary-foreground" />
                </div>
              )}
            </Link>

            <div className="flex-1 min-w-0">
              <div className="flex items-center space-x-2 mb-1">
                <Link
                  href={`/u/${profile.username}`}
                  className="font-semibold text-foreground hover:underline"
                >
                  {profile.name}
                </Link>
                <span className="text-sm text-muted-foreground">
                  @{profile.username}
                </span>
              </div>

              {profile.city && (
                <div className="flex items-center space-x-1 mb-2">
                  <MapPin className="h-3 w-3 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">
                    {profile.city}
                  </span>
                </div>
              )}

              {profile.bio && (
                <p className="text-sm text-foreground mb-3 line-clamp-2">
                  {profile.bio}
                </p>
              )}

              {profile.skills && profile.skills.length > 0 && (
                <div className="flex flex-wrap gap-1">
                  {profile.skills.slice(0, 5).map((skill, index) => (
                    <span
                      key={index}
                      className="inline-flex items-center px-2 py-1 rounded-full text-xs bg-primary/10 text-primary"
                    >
                      <Tag className="h-3 w-3 mr-1" />
                      {skill}
                    </span>
                  ))}
                  {profile.skills.length > 5 && (
                    <span className="text-xs text-muted-foreground">
                      +{profile.skills.length - 5} еще
                    </span>
                  )}
                </div>
              )}
            </div>

            <Link
              href={`/u/${profile.username}`}
              className="btn btn-outline"
            >
              Посмотреть профиль
            </Link>
          </div>
        </div>
      ))}
    </div>
  )
}
