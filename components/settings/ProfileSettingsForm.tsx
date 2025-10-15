'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { User, MapPin, FileText, Link as LinkIcon, Plus, X, Upload } from 'lucide-react'
import { cn } from '@/utils/cn'
import { Profile } from '@/types'
import toast from 'react-hot-toast'

interface ProfileSettingsFormProps {
  profile: Profile
}

export default function ProfileSettingsForm({ profile }: ProfileSettingsFormProps) {
  const [formData, setFormData] = useState({
    username: profile.username || '',
    name: profile.name || '',
    bio: profile.bio || '',
    city: profile.city || '',
    skills: profile.skills || [],
    links: profile.links || {
      website: '',
      instagram: '',
      telegram: '',
      vk: '',
    },
  })
  const [newSkill, setNewSkill] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const router = useRouter()

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }))
  }

  const handleLinkChange = (platform: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      links: {
        ...prev.links,
        [platform]: value,
      },
    }))
  }

  const addSkill = () => {
    if (newSkill.trim() && !formData.skills.includes(newSkill.trim())) {
      setFormData(prev => ({
        ...prev,
        skills: [...prev.skills, newSkill.trim()],
      }))
      setNewSkill('')
    }
  }

  const removeSkill = (skillToRemove: string) => {
    setFormData(prev => ({
      ...prev,
      skills: prev.skills.filter(skill => skill !== skillToRemove),
    }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)

    try {
      const response = await fetch('/api/profile', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      })

      if (response.ok) {
        toast.success('Профиль обновлен!')
        router.refresh()
      } else {
        const error = await response.json()
        toast.error(error.error || 'Ошибка при обновлении профиля')
      }
    } catch (error) {
      console.error('Error updating profile:', error)
      toast.error('Произошла ошибка')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto">
      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Basic Info */}
        <div className="card p-6">
          <h3 className="text-lg font-semibold text-foreground mb-4">
            Основная информация
          </h3>
          
          <div className="space-y-4">
            <div>
              <label htmlFor="username" className="block text-sm font-medium text-foreground mb-2">
                Username
              </label>
              <div className="relative">
                <User className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <input
                  id="username"
                  type="text"
                  required
                  value={formData.username}
                  onChange={(e) => handleInputChange('username', e.target.value)}
                  className="input pl-10 w-full"
                  placeholder="username"
                />
              </div>
            </div>

            <div>
              <label htmlFor="name" className="block text-sm font-medium text-foreground mb-2">
                Имя
              </label>
              <input
                id="name"
                type="text"
                required
                value={formData.name}
                onChange={(e) => handleInputChange('name', e.target.value)}
                className="input w-full"
                placeholder="Ваше имя"
              />
            </div>

            <div>
              <label htmlFor="bio" className="block text-sm font-medium text-foreground mb-2">
                О себе
              </label>
              <textarea
                id="bio"
                value={formData.bio}
                onChange={(e) => handleInputChange('bio', e.target.value)}
                className="input min-h-[100px] resize-none"
                placeholder="Расскажите о себе..."
                maxLength={500}
              />
              <div className="text-right text-sm text-muted-foreground mt-1">
                {formData.bio.length}/500
              </div>
            </div>

            <div>
              <label htmlFor="city" className="block text-sm font-medium text-foreground mb-2">
                Город
              </label>
              <div className="relative">
                <MapPin className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <input
                  id="city"
                  type="text"
                  value={formData.city}
                  onChange={(e) => handleInputChange('city', e.target.value)}
                  className="input pl-10 w-full"
                  placeholder="Ваш город"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Skills */}
        <div className="card p-6">
          <h3 className="text-lg font-semibold text-foreground mb-4">
            Навыки и специализации
          </h3>
          
          <div className="space-y-4">
            <div className="flex space-x-2">
              <input
                type="text"
                value={newSkill}
                onChange={(e) => setNewSkill(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addSkill())}
                className="input flex-1"
                placeholder="Добавить навык..."
              />
              <button
                type="button"
                onClick={addSkill}
                className="btn btn-primary px-4"
              >
                <Plus className="h-4 w-4" />
              </button>
            </div>

            {formData.skills.length > 0 && (
              <div className="flex flex-wrap gap-2">
                {formData.skills.map((skill, index) => (
                  <span
                    key={index}
                    className="inline-flex items-center px-3 py-1 rounded-full text-sm bg-primary/10 text-primary"
                  >
                    {skill}
                    <button
                      type="button"
                      onClick={() => removeSkill(skill)}
                      className="ml-2 hover:text-destructive"
                    >
                      <X className="h-3 w-3" />
                    </button>
                  </span>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Links */}
        <div className="card p-6">
          <h3 className="text-lg font-semibold text-foreground mb-4">
            Ссылки и контакты
          </h3>
          
          <div className="space-y-4">
            <div>
              <label htmlFor="website" className="block text-sm font-medium text-foreground mb-2">
                Веб-сайт
              </label>
              <input
                id="website"
                type="url"
                value={formData.links.website}
                onChange={(e) => handleLinkChange('website', e.target.value)}
                className="input w-full"
                placeholder="https://yourwebsite.com"
              />
            </div>

            <div>
              <label htmlFor="instagram" className="block text-sm font-medium text-foreground mb-2">
                Instagram
              </label>
              <input
                id="instagram"
                type="text"
                value={formData.links.instagram}
                onChange={(e) => handleLinkChange('instagram', e.target.value)}
                className="input w-full"
                placeholder="@username"
              />
            </div>

            <div>
              <label htmlFor="telegram" className="block text-sm font-medium text-foreground mb-2">
                Telegram
              </label>
              <input
                id="telegram"
                type="text"
                value={formData.links.telegram}
                onChange={(e) => handleLinkChange('telegram', e.target.value)}
                className="input w-full"
                placeholder="@username"
              />
            </div>

            <div>
              <label htmlFor="vk" className="block text-sm font-medium text-foreground mb-2">
                VK
              </label>
              <input
                id="vk"
                type="text"
                value={formData.links.vk}
                onChange={(e) => handleLinkChange('vk', e.target.value)}
                className="input w-full"
                placeholder="vk.com/username"
              />
            </div>
          </div>
        </div>

        {/* Submit Button */}
        <div className="flex justify-end">
          <button
            type="submit"
            disabled={isLoading}
            className="btn btn-primary"
          >
            {isLoading ? 'Сохранение...' : 'Сохранить изменения'}
          </button>
        </div>
      </form>
    </div>
  )
}
