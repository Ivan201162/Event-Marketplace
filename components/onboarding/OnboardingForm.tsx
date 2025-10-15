'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { User, MapPin, FileText, Link as LinkIcon, Plus, X } from 'lucide-react'
import { cn } from '@/utils/cn'
import toast from 'react-hot-toast'

export default function OnboardingForm() {
  const [step, setStep] = useState(1)
  const [formData, setFormData] = useState({
    bio: '',
    city: '',
    skills: [] as string[],
    links: {
      website: '',
      instagram: '',
      telegram: '',
      vk: '',
    },
  })
  const [newSkill, setNewSkill] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const router = useRouter()
  const supabase = createClient()

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

  const handleSubmit = async () => {
    setIsLoading(true)

    try {
      const { error } = await supabase
        .from('profiles')
        .update({
          bio: formData.bio,
          city: formData.city,
          skills: formData.skills,
          links: formData.links,
          updated_at: new Date().toISOString(),
        })
        .eq('id', (await supabase.auth.getUser()).data.user?.id)

      if (error) {
        toast.error('Ошибка при сохранении профиля')
      } else {
        toast.success('Профиль успешно настроен!')
        router.push('/')
        router.refresh()
      }
    } catch (error) {
      toast.error('Произошла ошибка')
    } finally {
      setIsLoading(false)
    }
  }

  const nextStep = () => {
    if (step < 4) {
      setStep(step + 1)
    } else {
      handleSubmit()
    }
  }

  const prevStep = () => {
    if (step > 1) {
      setStep(step - 1)
    }
  }

  return (
    <div className="max-w-2xl mx-auto">
      {/* Progress Bar */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm text-muted-foreground">Шаг {step} из 4</span>
          <span className="text-sm text-muted-foreground">
            {Math.round((step / 4) * 100)}%
          </span>
        </div>
        <div className="w-full bg-secondary rounded-full h-2">
          <div
            className="bg-primary h-2 rounded-full transition-all duration-300"
            style={{ width: `${(step / 4) * 100}%` }}
          />
        </div>
      </div>

      {/* Step Content */}
      <div className="card p-6">
        {step === 1 && (
          <div className="space-y-6">
            <div className="text-center">
              <User className="h-12 w-12 text-primary mx-auto mb-4" />
              <h2 className="text-2xl font-bold text-foreground mb-2">
                Расскажите о себе
              </h2>
              <p className="text-muted-foreground">
                Добавьте краткое описание вашей деятельности
              </p>
            </div>

            <div>
              <label htmlFor="bio" className="block text-sm font-medium text-foreground mb-2">
                О себе
              </label>
              <textarea
                id="bio"
                value={formData.bio}
                onChange={(e) => handleInputChange('bio', e.target.value)}
                className="input min-h-[120px] resize-none"
                placeholder="Расскажите о своем опыте, специализации и достижениях..."
                maxLength={500}
              />
              <div className="text-right text-sm text-muted-foreground mt-1">
                {formData.bio.length}/500
              </div>
            </div>
          </div>
        )}

        {step === 2 && (
          <div className="space-y-6">
            <div className="text-center">
              <MapPin className="h-12 w-12 text-primary mx-auto mb-4" />
              <h2 className="text-2xl font-bold text-foreground mb-2">
                Ваше местоположение
              </h2>
              <p className="text-muted-foreground">
                Укажите город, где вы работаете
              </p>
            </div>

            <div>
              <label htmlFor="city" className="block text-sm font-medium text-foreground mb-2">
                Город
              </label>
              <input
                id="city"
                type="text"
                value={formData.city}
                onChange={(e) => handleInputChange('city', e.target.value)}
                className="input w-full"
                placeholder="Москва, Санкт-Петербург, Екатеринбург..."
              />
            </div>
          </div>
        )}

        {step === 3 && (
          <div className="space-y-6">
            <div className="text-center">
              <FileText className="h-12 w-12 text-primary mx-auto mb-4" />
              <h2 className="text-2xl font-bold text-foreground mb-2">
                Ваши навыки
              </h2>
              <p className="text-muted-foreground">
                Добавьте навыки и специализации
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-2">
                Навыки
              </label>
              <div className="flex space-x-2 mb-3">
                <input
                  type="text"
                  value={newSkill}
                  onChange={(e) => setNewSkill(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addSkill())}
                  className="input flex-1"
                  placeholder="Например: Ведущий, DJ, Фотограф..."
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
        )}

        {step === 4 && (
          <div className="space-y-6">
            <div className="text-center">
              <LinkIcon className="h-12 w-12 text-primary mx-auto mb-4" />
              <h2 className="text-2xl font-bold text-foreground mb-2">
                Социальные сети
              </h2>
              <p className="text-muted-foreground">
                Добавьте ссылки на ваши профили (необязательно)
              </p>
            </div>

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
        )}

        {/* Navigation Buttons */}
        <div className="flex justify-between mt-8">
          <button
            type="button"
            onClick={prevStep}
            disabled={step === 1}
            className="btn btn-outline"
          >
            Назад
          </button>

          <button
            type="button"
            onClick={nextStep}
            disabled={isLoading}
            className="btn btn-primary"
          >
            {isLoading ? 'Сохранение...' : step === 4 ? 'Завершить' : 'Далее'}
          </button>
        </div>
      </div>
    </div>
  )
}
