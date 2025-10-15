'use client'

import { ExternalLink, MapPin, Calendar, Globe, Instagram, MessageCircle, Users } from 'lucide-react'
import { ProfileWithStats } from '@/types'

interface ProfileAboutProps {
  profile: ProfileWithStats
}

export default function ProfileAbout({ profile }: ProfileAboutProps) {
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('ru-RU', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    })
  }

  const getLinks = () => {
    const links = []
    if (profile.links) {
      const linkData = profile.links as any
      if (linkData.website) links.push({ type: 'website', url: linkData.website, label: 'Веб-сайт', icon: Globe })
      if (linkData.instagram) links.push({ type: 'instagram', url: linkData.instagram, label: 'Instagram', icon: Instagram })
      if (linkData.telegram) links.push({ type: 'telegram', url: linkData.telegram, label: 'Telegram', icon: MessageCircle })
      if (linkData.vk) links.push({ type: 'vk', url: linkData.vk, label: 'VK', icon: Users })
    }
    return links
  }

  const links = getLinks()

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {/* Basic Info */}
      <div className="card p-6">
        <h3 className="text-lg font-semibold text-foreground mb-4">
          Основная информация
        </h3>
        
        <div className="space-y-4">
          <div className="flex items-center space-x-3">
            <MapPin className="h-5 w-5 text-muted-foreground" />
            <div>
              <p className="text-sm text-muted-foreground">Местоположение</p>
              <p className="text-foreground">{profile.city || 'Не указано'}</p>
            </div>
          </div>

          <div className="flex items-center space-x-3">
            <Calendar className="h-5 w-5 text-muted-foreground" />
            <div>
              <p className="text-sm text-muted-foreground">На платформе с</p>
              <p className="text-foreground">{formatDate(profile.created_at)}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Skills */}
      {profile.skills && profile.skills.length > 0 && (
        <div className="card p-6">
          <h3 className="text-lg font-semibold text-foreground mb-4">
            Навыки и специализации
          </h3>
          
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
        </div>
      )}

      {/* Links */}
      {links.length > 0 && (
        <div className="card p-6 md:col-span-2">
          <h3 className="text-lg font-semibold text-foreground mb-4">
            Ссылки и контакты
          </h3>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {links.map((link, index) => {
              const Icon = link.icon
              return (
                <a
                  key={index}
                  href={link.url.startsWith('http') ? link.url : `https://${link.url}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center space-x-3 p-3 rounded-lg border hover:bg-accent transition-colors"
                >
                  <Icon className="h-5 w-5 text-muted-foreground" />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-foreground">{link.label}</p>
                    <p className="text-sm text-muted-foreground truncate">{link.url}</p>
                  </div>
                  <ExternalLink className="h-4 w-4 text-muted-foreground" />
                </a>
              )
            })}
          </div>
        </div>
      )}

      {/* Bio */}
      {profile.bio && (
        <div className="card p-6 md:col-span-2">
          <h3 className="text-lg font-semibold text-foreground mb-4">
            О специалисте
          </h3>
          <p className="text-foreground whitespace-pre-wrap">{profile.bio}</p>
        </div>
      )}
    </div>
  )
}
