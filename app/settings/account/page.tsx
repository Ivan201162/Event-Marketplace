import { createClient } from '@/utils/supabase/server'
import { redirect } from 'next/navigation'
import AccountSettingsForm from '@/components/settings/AccountSettingsForm'

export default async function AccountSettingsPage() {
  const supabase = await createClient()
  
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) {
    redirect('/auth/sign-in')
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-4xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-foreground">Настройки аккаунта</h1>
          <p className="text-muted-foreground mt-2">
            Управляйте безопасностью и настройками аккаунта
          </p>
        </div>

        <AccountSettingsForm />
      </div>
    </div>
  )
}