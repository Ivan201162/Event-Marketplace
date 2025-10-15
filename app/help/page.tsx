import Link from 'next/link'
import { ArrowLeft, HelpCircle, MessageCircle, Mail, Phone } from 'lucide-react'

export default function HelpPage() {
  const faqItems = [
    {
      question: "Как создать аккаунт?",
      answer: "Нажмите кнопку 'Регистрация' на главной странице, введите email и пароль, или войдите через социальные сети (Google, VK, GitHub). После регистрации заполните профиль в разделе 'О себе'."
    },
    {
      question: "Как найти специалиста?",
      answer: "Используйте поиск в верхней части страницы. Введите ключевые слова, связанные с нужной вам услугой. Также можете просматривать ленту постов и профили в разделе 'Лучшие за неделю'."
    },
    {
      question: "Как создать пост?",
      answer: "Нажмите кнопку '+' в верхней части страницы или используйте форму 'Быстрый пост' на главной странице. Добавьте описание, прикрепите фото или видео, выберите категорию и опубликуйте."
    },
    {
      question: "Как подписаться на пользователя?",
      answer: "Перейдите в профиль пользователя и нажмите кнопку 'Подписаться'. После подписки вы будете видеть посты этого пользователя в своей ленте."
    },
    {
      question: "Как изменить настройки профиля?",
      answer: "Нажмите на свой аватар в верхней части страницы, выберите 'Настройки' → 'Профиль'. Здесь вы можете изменить имя, биографию, навыки, город и ссылки на социальные сети."
    },
    {
      question: "Как изменить пароль?",
      answer: "Перейдите в 'Настройки' → 'Аккаунт' → 'Изменить пароль'. Введите текущий пароль и новый пароль дважды для подтверждения."
    },
    {
      question: "Как удалить аккаунт?",
      answer: "В разделе 'Настройки' → 'Аккаунт' найдите кнопку 'Удалить аккаунт'. Внимание: это действие нельзя отменить, все ваши данные будут удалены навсегда."
    },
    {
      question: "Как настроить уведомления?",
      answer: "Перейдите в 'Настройки' → 'Приватность' и настройте уведомления о новых подписчиках, сообщениях, лайках и комментариях."
    }
  ]

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-4xl mx-auto">
        <Link 
          href="/" 
          className="inline-flex items-center text-muted-foreground hover:text-foreground mb-8"
        >
          <ArrowLeft className="h-4 w-4 mr-2" />
          Назад
        </Link>

        <div className="mb-8">
          <h1 className="text-3xl font-bold text-foreground mb-4">
            Помощь и поддержка
          </h1>
          <p className="text-muted-foreground">
            Здесь вы найдете ответы на часто задаваемые вопросы и способы связаться с нами
          </p>
        </div>

        {/* FAQ Section */}
        <div className="mb-12">
          <h2 className="text-2xl font-semibold text-foreground mb-6">
            Часто задаваемые вопросы
          </h2>
          
          <div className="space-y-4">
            {faqItems.map((item, index) => (
              <div key={index} className="card p-6">
                <h3 className="font-semibold text-foreground mb-3 flex items-start">
                  <HelpCircle className="h-5 w-5 text-primary mr-2 mt-0.5 flex-shrink-0" />
                  {item.question}
                </h3>
                <p className="text-muted-foreground leading-relaxed pl-7">
                  {item.answer}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Contact Section */}
        <div className="mb-12">
          <h2 className="text-2xl font-semibold text-foreground mb-6">
            Связаться с нами
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="card p-6 text-center">
              <MessageCircle className="h-8 w-8 text-primary mx-auto mb-4" />
              <h3 className="font-semibold text-foreground mb-2">Чат поддержки</h3>
              <p className="text-muted-foreground text-sm mb-4">
                Быстрые ответы на ваши вопросы
              </p>
              <button className="btn btn-primary w-full">
                Открыть чат
              </button>
            </div>

            <div className="card p-6 text-center">
              <Mail className="h-8 w-8 text-primary mx-auto mb-4" />
              <h3 className="font-semibold text-foreground mb-2">Email поддержка</h3>
              <p className="text-muted-foreground text-sm mb-4">
                Подробные ответы в течение 24 часов
              </p>
              <a 
                href="mailto:support@eventmarketplace.com"
                className="btn btn-outline w-full"
              >
                Написать письмо
              </a>
            </div>

            <div className="card p-6 text-center">
              <Phone className="h-8 w-8 text-primary mx-auto mb-4" />
              <h3 className="font-semibold text-foreground mb-2">Телефон</h3>
              <p className="text-muted-foreground text-sm mb-4">
                Срочные вопросы и техническая поддержка
              </p>
              <a 
                href="tel:+7-800-123-45-67"
                className="btn btn-outline w-full"
              >
                Позвонить
              </a>
            </div>
          </div>
        </div>

        {/* Additional Resources */}
        <div>
          <h2 className="text-2xl font-semibold text-foreground mb-6">
            Дополнительные ресурсы
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Link 
              href="/privacy"
              className="card p-6 hover:bg-muted/50 transition-colors"
            >
              <h3 className="font-semibold text-foreground mb-2">
                Политика конфиденциальности
              </h3>
              <p className="text-muted-foreground text-sm">
                Как мы защищаем и обрабатываем ваши данные
              </p>
            </Link>

            <Link 
              href="/terms"
              className="card p-6 hover:bg-muted/50 transition-colors"
            >
              <h3 className="font-semibold text-foreground mb-2">
                Условия использования
              </h3>
              <p className="text-muted-foreground text-sm">
                Правила использования платформы
              </p>
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}
