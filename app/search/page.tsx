'use client'

import { useState, useEffect } from 'react'
import { useSearchParams } from 'next/navigation'
import Image from 'next/image'
import Link from 'next/link'
import { Search, MapPin, User } from 'lucide-react'
import { SearchResult } from '@/lib/types'

export default function SearchPage() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState<SearchResult[]>([])
  const [loading, setLoading] = useState(false)
  const searchParams = useSearchParams()

  useEffect(() => {
    const initialQuery = searchParams.get('q')
    if (initialQuery) {
      setQuery(initialQuery)
      searchProfiles(initialQuery)
    }
  }, [searchParams])

  const searchProfiles = async (searchQuery: string) => {
    if (searchQuery.length < 2) {
      setResults([])
      return
    }

    setLoading(true)
    try {
      const response = await fetch(`/api/search?q=${encodeURIComponent(searchQuery)}`)
      const data = await response.json()
      setResults(data)
    } catch (error) {
      console.error('Search error:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    searchProfiles(query)
  }

  return (
    <div className="min-h-screen bg-neutral-900">
      <div className="sticky top-0 bg-neutral-900 border-b border-neutral-800 p-4">
        <form onSubmit={handleSearch} className="flex gap-3">
          <div className="flex flex-1 items-center bg-neutral-800 rounded-lg px-3 py-2 border border-neutral-700">
            <Search size={18} className="text-gray-400 mr-2 flex-shrink-0" />
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="bg-transparent text-white flex-1 outline-none placeholder-gray-400"
              placeholder="Найти специалиста..."
              autoFocus
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="btn-primary px-6"
          >
            {loading ? 'Поиск...' : 'Найти'}
          </button>
        </form>
      </div>

      <div className="p-4">
        {loading && (
          <div className="flex items-center justify-center py-8">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
          </div>
        )}

        {!loading && results.length === 0 && query && (
          <div className="text-center py-8">
            <p className="text-gray-400">Ничего не найдено</p>
          </div>
        )}

        {!loading && results.length > 0 && (
          <div className="space-y-4">
            <p className="text-gray-400 text-sm">
              Найдено {results.length} специалистов
            </p>
            {results.map((profile) => (
              <Link
                key={profile.id}
                href={`/u/${profile.username}`}
                className="card p-4 block hover:bg-neutral-700 transition-colors"
              >
                <div className="flex items-start gap-4">
                  <Image
                    src={profile.avatar_url || '/default-avatar.png'}
                    alt={profile.name}
                    width={60}
                    height={60}
                    className="rounded-full border border-neutral-700"
                  />
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="text-white font-medium">{profile.name}</h3>
                      <span className="text-gray-400 text-sm">@{profile.username}</span>
                    </div>

                    {profile.city && (
                      <div className="flex items-center gap-1 text-gray-400 text-sm mb-2">
                        <MapPin size={14} />
                        <span>{profile.city}</span>
                      </div>
                    )}

                    {profile.bio && (
                      <p className="text-gray-300 text-sm mb-2 line-clamp-2">
                        {profile.bio}
                      </p>
                    )}

                    {profile.skills.length > 0 && (
                      <div className="flex flex-wrap gap-1">
                        {profile.skills.slice(0, 3).map((skill, index) => (
                          <span
                            key={index}
                            className="bg-primary-600 text-white px-2 py-1 rounded text-xs"
                          >
                            {skill}
                          </span>
                        ))}
                        {profile.skills.length > 3 && (
                          <span className="text-gray-400 text-xs">
                            +{profile.skills.length - 3} еще
                          </span>
                        )}
                      </div>
                    )}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}

        {!loading && !query && (
          <div className="text-center py-8">
            <User size={48} className="text-gray-600 mx-auto mb-4" />
            <p className="text-gray-400">Введите запрос для поиска специалистов</p>
          </div>
        )}
      </div>
    </div>
  )
}