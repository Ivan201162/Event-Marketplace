'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import Header from '@/components/layout/Header'
import Sidebar from '@/components/layout/Sidebar'
import MobileNav from '@/components/layout/MobileNav'
import PostsFeed from '@/components/posts/PostsFeed'
import QuickPostForm from '@/components/posts/QuickPostForm'
import LeaderboardWidget from '@/components/leaderboard/LeaderboardWidget'
import { Profile } from '@/types'

export default function HomePage() {
  const [user, setUser] = useState<Profile | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const supabase = createClient()

  useEffect(() => {
    const getUser = async () => {
      try {
        const { data: { user: authUser } } = await supabase.auth.getUser()
        
        if (authUser) {
          const { data: profile } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', authUser.id)
            .single()
          
          setUser(profile)
        }
      } catch (error) {
        console.error('Error fetching user:', error)
      } finally {
        setIsLoading(false)
      }
    }

    getUser()
  }, [supabase])

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background">
      <Header user={user} />
      
      <div className="flex">
        <Sidebar user={user} />
        
        <main className="flex-1 md:ml-64">
          <div className="container mx-auto px-4 py-8">
            <div className="max-w-4xl mx-auto">
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Main Content */}
                <div className="lg:col-span-2 space-y-6">
                  {user && <QuickPostForm user={user} />}
                  <PostsFeed />
                </div>

                {/* Sidebar */}
                <div className="space-y-6">
                  <LeaderboardWidget />
                </div>
              </div>
            </div>
          </div>
        </main>
      </div>

      <MobileNav user={user} />
    </div>
  )
}
