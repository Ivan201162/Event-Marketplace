'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'
import { User, MapPin, FileText, Link as LinkIcon, Plus, X } from 'lucide-react'
import toast from 'react-hot-toast'
import { useCurrentProfile } from '@/lib/hooks/use-profile'

export default function OnboardingPage() {
  const [formData, setFormData] = useState({
    name: '',
    username: '',
    city: '',
    bio: '',
    skills: [] as string[],
    links: [] as string[],
  })
  const [skillInput, setSkillInput] = useState('')
  const [linkInput, setLinkInput] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()
  const supabase = createClientComponentClient()
  const { profile, loading: profileLoading } = useCurrentProfile()

  useEffect(() => {
    if (profile) {
      setFormData({
        name: profile.name,
        username: profile.username,
        city: profile.city || '',
        bio: profile.bio || '',
        skills: profile.skills,
        links: profile.links,
      })
    }
  }, [profile])

  const addSkill = () => {
    if (skillInput.trim() && !formData.skills.includes(skillInput.trim())) {
      setFormData(prev => ({
        ...prev,
        skills: [...prev.skills, skillInput.trim()]
      }))
      setSkillInput('')
    }
  }

  const removeSkill = (skill: string) => {
    setFormData(prev => ({
      ...prev,
      skills: prev.skills.filter(s => s !== skill)
    }))
  }

  const addLink = () => {
    if (linkInput.trim() && !formData.links.includes(linkInput.trim())) {
      setFormData(prev => ({
        ...prev,
        links: [...prev.links, linkInput.trim()]
      }))
      setLinkInput('')
    }
  }

  const removeLink = (link: string) => {
    setFormData(prev => ({
      ...prev,
      links: prev.links.filter(l => l !== link)
    }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      const { error } = await supabase
        .from('profiles')
        .update({
          name: formData.name,
          username: formData.username,
          city: formData.city,
          bio: formData.bio,
          skills: formData.skills,
          links: formData.links,
          updated_at: new Date().toISOString(),
        })
        .eq('id', profile?.id)

      if (error) throw error

      toast.success('Профиль обновлен!')
      router.push('/')
    } catch (error) {
      toast.error('Ошибка обновления профиля: ' + (error as Error).message)
    } finally {
      setLoading(false)
    }
  }

  if (profileLoading) {
    return (
      <div className="min-h-screen bg-neutral-900 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-neutral-900 flex items-center justify-center px-4">
      <div className="w-full max-w-2xl">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-white mb-2">Завершите настройку профиля</h1>
          <p className="text-gray-400">Расскажите о себе и своих навыках</p>
        </div>

        <div className="card p-6">
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Имя
                </label>
                <div className="relative">
                  <User size={20} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                  <input
                    type="text"
                    value={formData.name}
                    onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                    className="input-field pl-10 w-full"
                    placeholder="Ваше имя"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Username
                </label>
                <div className="relative">
                  <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400">@</span>
                  <input
                    type="text"
                    value={formData.username}
                    onChange={(e) => setFormData(prev => ({ ...prev, username: e.target.value }))}
                    className="input-field pl-8 w-full"
                    placeholder="username"
                    required
                  />
                </div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Город
              </label>
              <div className="relative">
                <MapPin size={20} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  value={formData.city}
                  onChange={(e) => setFormData(prev => ({ ...prev, city: e.target.value }))}
                  className="input-field pl-10 w-full"
                  placeholder="Москва"
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                О себе
              </label>
              <div className="relative">
                <FileText size={20} className="absolute left-3 top-3 text-gray-400" />
                <textarea
                  value={formData.bio}
                  onChange={(e) => setFormData(prev => ({ ...prev, bio: e.target.value }))}
                  className="input-field pl-10 w-full h-24 resize-none"
                  placeholder="Расскажите о себе и своих услугах..."
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Навыки
              </label>
              <div className="flex gap-2 mb-2">
                <input
                  type="text"
                  value={skillInput}
                  onChange={(e) => setSkillInput(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addSkill())}
                  className="input-field flex-1"
                  placeholder="Добавить навык"
                />
                <button
                  type="button"
                  onClick={addSkill}
                  className="btn-primary px-3"
                >
                  <Plus size={16} />
                </button>
              </div>
              <div className="flex flex-wrap gap-2">
                {formData.skills.map((skill, index) => (
                  <span
                    key={index}
                    className="bg-primary-600 text-white px-3 py-1 rounded-full text-sm flex items-center gap-2"
                  >
                    {skill}
                    <button
                      type="button"
                      onClick={() => removeSkill(skill)}
                      className="hover:text-red-300"
                    >
                      <X size={14} />
                    </button>
                  </span>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Ссылки
              </label>
              <div className="flex gap-2 mb-2">
                <input
                  type="url"
                  value={linkInput}
                  onChange={(e) => setLinkInput(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addLink())}
                  className="input-field flex-1"
                  placeholder="https://example.com"
                />
                <button
                  type="button"
                  onClick={addLink}
                  className="btn-primary px-3"
                >
                  <Plus size={16} />
                </button>
              </div>
              <div className="space-y-2">
                {formData.links.map((link, index) => (
                  <div
                    key={index}
                    className="bg-neutral-700 text-white px-3 py-2 rounded-lg text-sm flex items-center justify-between"
                  >
                    <div className="flex items-center gap-2">
                      <LinkIcon size={14} />
                      <span className="truncate">{link}</span>
                    </div>
                    <button
                      type="button"
                      onClick={() => removeLink(link)}
                      className="hover:text-red-300"
                    >
                      <X size={14} />
                    </button>
                  </div>
                ))}
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="btn-primary w-full"
            >
              {loading ? 'Сохранение...' : 'Завершить настройку'}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}