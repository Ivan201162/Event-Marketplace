'use client'

import { useState } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { User, MapPin, Calendar, Users, MessageCircle, Settings, Share } from 'lucide-react'
import { ProfileWithStats } from '@/types'
import ProfileTabs from './ProfileTabs'

interface ProfilePageProps {
  profile: ProfileWithStats
  currentUserId: string
}

export default function ProfilePage({ profile, currentUserId }: ProfilePageProps) {
  const [isFollowing, setIsFollowing] = useState(profile.is_following || false)
  const [followersCount, setFollowersCount] = useState(profile.followers_count)
  const isOwnProfile = profile.id === currentUserId

  const handleFollow = async () => {
    try {
      const response = await fetch(`/api/follow/${profile.username}`, {
        method: 'POST',
      })

      if (response.ok) {
        const data = await response.json()
        setIsFollowing(data.following)
        setFollowersCount(prev => data.following ? prev + 1 : prev - 1)
      }
    } catch (error) {
      console.error('Error following/unfollowing:', error)
    }
  }

  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          {/* Profile Header */}
          <div className="card p-8 mb-6">
            <div className="flex flex-col md:flex-row items-start md:items-center space-y-4 md:space-y-0 md:space-x-6">
              {/* Avatar */}
              <div className="flex-shrink-0">
                {profile.avatar_url ? (
                  <Image
                    src={profile.avatar_url}
                    alt={profile.name}
                    width={120}
                    height={120}
                    className="rounded-full"
                  />
                ) : (
                  <div className="h-30 w-30 rounded-full bg-primary flex items-center justify-center">
                    <User className="h-16 w-16 text-primary-foreground" />
                  </div>
                )}
              </div>

              {/* Profile Info */}
              <div className="flex-1 min-w-0">
                <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-4">
                  <div>
                    <h1 className="text-2xl font-bold text-foreground mb-1">
                      {profile.name}
                    </h1>
                    <p className="text-muted-foreground mb-2">
                      @{profile.username}
                    </p>
                  </div>

                  <div className="flex items-center space-x-2">
                    {!isOwnProfile && (
                      <>
                        <button
                          onClick={handleFollow}
                          className={`btn ${isFollowing ? 'btn-outline' : 'btn-primary'}`}
                        >
                          {isFollowing ? 'Отписаться' : 'Подписаться'}
                        </button>
                        
                        {profile.can_receive_messages && (
                          <button className="btn btn-outline">
                            <MessageCircle className="h-4 w-4 mr-2" />
                            Написать
                          </button>
                        )}
                      </>
                    )}

                    {isOwnProfile && (
                      <Link href="/settings/profile" className="btn btn-outline">
                        <Settings className="h-4 w-4 mr-2" />
                        Редактировать
                      </Link>
                    )}

                    <button className="btn btn-ghost">
                      <Share className="h-4 w-4" />
                    </button>
                  </div>
                </div>

                {/* Bio */}
                {profile.bio && (
                  <p className="text-foreground mb-4 whitespace-pre-wrap">
                    {profile.bio}
                  </p>
                )}

                {/* Location */}
                {profile.city && (
                  <div className="flex items-center space-x-1 mb-4">
                    <MapPin className="h-4 w-4 text-muted-foreground" />
                    <span className="text-muted-foreground">{profile.city}</span>
                  </div>
                )}

                {/* Stats */}
                <div className="flex items-center space-x-6 mb-4">
                  <div className="flex items-center space-x-1">
                    <Users className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm text-muted-foreground">
                      <span className="font-medium text-foreground">{followersCount}</span> подписчиков
                    </span>
                  </div>
                  
                  <div className="flex items-center space-x-1">
                    <Users className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm text-muted-foreground">
                      <span className="font-medium text-foreground">{profile.following_count}</span> подписок
                    </span>
                  </div>
                  
                  <div className="flex items-center space-x-1">
                    <Calendar className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm text-muted-foreground">
                      <span className="font-medium text-foreground">{profile.posts_count}</span> постов
                    </span>
                  </div>
                </div>

                {/* Skills */}
                {profile.skills && profile.skills.length > 0 && (
                  <div className="flex flex-wrap gap-2">
                    {profile.skills.map((skill, index) => (
                      <span
                        key={index}
                        className="inline-flex items-center px-3 py-1 rounded-full text-sm bg-primary/10 text-primary"
                      >
                        {skill}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Profile Tabs */}
          <ProfileTabs profile={profile} />
        </div>
      </div>
    </div>
  )
}
