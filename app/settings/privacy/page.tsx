import { createClient } from '@/utils/supabase/server'
import { redirect } from 'next/navigation'
import PrivacySettingsForm from '@/components/settings/PrivacySettingsForm'

export default async function PrivacySettingsPage() {
  const supabase = await createClient()
  
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) {
    redirect('/auth/sign-in')
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-4xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-foreground">Настройки приватности</h1>
          <p className="text-muted-foreground mt-2">
            Управляйте видимостью профиля и настройками уведомлений
          </p>
        </div>

        <PrivacySettingsForm />
      </div>
    </div>
  )
}