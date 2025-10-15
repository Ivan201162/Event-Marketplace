import Link from 'next/link'
import { ArrowLeft } from 'lucide-react'

export default function TermsPage() {
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

        <div className="prose prose-gray max-w-none">
          <h1 className="text-3xl font-bold text-foreground mb-8">
            Условия использования
          </h1>

          <div className="space-y-6 text-foreground">
            <section>
              <h2 className="text-2xl font-semibold mb-4">1. Принятие условий</h2>
              <p className="text-muted-foreground leading-relaxed">
                Добро пожаловать на платформу Event Marketplace! Используя наш сервис, вы соглашаетесь 
                с настоящими Условиями использования. Если вы не согласны с какими-либо условиями, 
                пожалуйста, не используйте наш сервис.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">2. Описание сервиса</h2>
              <p className="text-muted-foreground leading-relaxed">
                Event Marketplace — это платформа для поиска и взаимодействия с специалистами 
                в области организации мероприятий. Мы предоставляем инструменты для создания профилей, 
                публикации контента, общения и поиска специалистов.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">3. Регистрация и аккаунт</h2>
              <div className="text-muted-foreground leading-relaxed space-y-3">
                <p>Для использования сервиса вы должны:</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li>Предоставить точную и актуальную информацию</li>
                  <li>Поддерживать безопасность вашего аккаунта</li>
                  <li>Нести ответственность за все действия под вашим аккаунтом</li>
                  <li>Немедленно уведомлять нас о любых нарушениях безопасности</li>
                </ul>
              </div>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">4. Правила поведения</h2>
              <div className="text-muted-foreground leading-relaxed space-y-3">
                <p>При использовании платформы запрещается:</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li>Публиковать незаконный, вредоносный или оскорбительный контент</li>
                  <li>Нарушать права интеллектуальной собственности</li>
                  <li>Спамить или рассылать нежелательные сообщения</li>
                  <li>Создавать фальшивые аккаунты или выдавать себя за других</li>
                  <li>Использовать автоматизированные системы для взаимодействия с платформой</li>
                  <li>Нарушать работу сервиса или пытаться получить несанкционированный доступ</li>
                </ul>
              </div>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">5. Контент пользователей</h2>
              <div className="text-muted-foreground leading-relaxed space-y-3">
                <p>Вы сохраняете права на контент, который публикуете, но предоставляете нам лицензию на:</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li>Отображение вашего контента на платформе</li>
                  <li>Распространение контента в рамках сервиса</li>
                  <li>Модификацию контента для технических целей</li>
                  <li>Использование контента для улучшения сервиса</li>
                </ul>
              </div>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">6. Интеллектуальная собственность</h2>
              <p className="text-muted-foreground leading-relaxed">
                Платформа Event Marketplace и все связанные с ней технологии, дизайн, текст, 
                графика, логотипы и другие материалы защищены авторскими правами и другими 
                правами интеллектуальной собственности. Вы не можете использовать их без 
                нашего письменного разрешения.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">7. Отказ от ответственности</h2>
              <p className="text-muted-foreground leading-relaxed">
                Сервис предоставляется "как есть" без каких-либо гарантий. Мы не несем 
                ответственности за точность, полноту или полезность информации, размещенной 
                пользователями. Мы также не гарантируем бесперебойную работу сервиса.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">8. Ограничение ответственности</h2>
              <p className="text-muted-foreground leading-relaxed">
                В максимальной степени, разрешенной законом, мы не несем ответственности за 
                любые косвенные, случайные, специальные или последующие убытки, возникающие 
                в результате использования или невозможности использования нашего сервиса.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">9. Прекращение действия</h2>
              <p className="text-muted-foreground leading-relaxed">
                Мы можем приостановить или прекратить ваш доступ к сервису в любое время 
                без предварительного уведомления за нарушение настоящих Условий. Вы также 
                можете прекратить использование сервиса в любое время.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">10. Изменения условий</h2>
              <p className="text-muted-foreground leading-relaxed">
                Мы оставляем за собой право изменять настоящие Условия в любое время. 
                О существенных изменениях мы уведомим пользователей через платформу. 
                Продолжение использования сервиса после изменений означает согласие с новыми условиями.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">11. Применимое право</h2>
              <p className="text-muted-foreground leading-relaxed">
                Настоящие Условия регулируются и толкуются в соответствии с законодательством 
                Российской Федерации. Любые споры подлежат рассмотрению в судах по месту 
                нахождения нашей компании.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">12. Контактная информация</h2>
              <p className="text-muted-foreground leading-relaxed">
                Если у вас есть вопросы по поводу настоящих Условий использования, 
                пожалуйста, свяжитесь с нами через форму обратной связи в приложении 
                или по email: legal@eventmarketplace.com
              </p>
            </section>

            <div className="mt-8 pt-6 border-t border-border">
              <p className="text-sm text-muted-foreground">
                Последнее обновление: {new Date().toLocaleDateString('ru-RU')}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
