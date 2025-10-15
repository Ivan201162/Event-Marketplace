'use client'

import { useState } from 'react'
import { Grid, User, Image as ImageIcon } from 'lucide-react'
import { ProfileWithStats } from '@/types'
import ProfilePosts from './ProfilePosts'
import ProfileAbout from './ProfileAbout'
import ProfileMedia from './ProfileMedia'

interface ProfileTabsProps {
  profile: ProfileWithStats
}

export default function ProfileTabs({ profile }: ProfileTabsProps) {
  const [activeTab, setActiveTab] = useState('posts')

  const tabs = [
    {
      id: 'posts',
      label: 'Посты',
      icon: Grid,
    },
    {
      id: 'about',
      label: 'О специалисте',
      icon: User,
    },
    {
      id: 'media',
      label: 'Медиа',
      icon: ImageIcon,
    },
  ]

  return (
    <div>
      {/* Tab Navigation */}
      <div className="border-b border-border">
        <nav className="flex space-x-8">
          {tabs.map((tab) => {
            const Icon = tab.icon
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center space-x-2 py-4 px-1 border-b-2 font-medium text-sm transition-colors ${
                  activeTab === tab.id
                    ? 'border-primary text-primary'
                    : 'border-transparent text-muted-foreground hover:text-foreground hover:border-border'
                }`}
              >
                <Icon className="h-4 w-4" />
                <span>{tab.label}</span>
              </button>
            )
          })}
        </nav>
      </div>

      {/* Tab Content */}
      <div className="mt-6">
        {activeTab === 'posts' && <ProfilePosts profile={profile} />}
        {activeTab === 'about' && <ProfileAbout profile={profile} />}
        {activeTab === 'media' && <ProfileMedia profile={profile} />}
      </div>
    </div>
  )
}
