import Link from 'next/link'
import { ArrowLeft } from 'lucide-react'

export default function PrivacyPage() {
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
            Политика конфиденциальности
          </h1>

          <div className="space-y-6 text-foreground">
            <section>
              <h2 className="text-2xl font-semibold mb-4">1. Общие положения</h2>
              <p className="text-muted-foreground leading-relaxed">
                Настоящая Политика конфиденциальности определяет порядок обработки персональных данных 
                пользователей платформы Event Marketplace. Мы серьезно относимся к защите вашей 
                конфиденциальности и обязуемся защищать ваши персональные данные.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">2. Какие данные мы собираем</h2>
              <div className="text-muted-foreground leading-relaxed space-y-3">
                <p>Мы собираем следующие типы информации:</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li>Основная информация профиля (имя, username, email, телефон)</li>
                  <li>Информация о профиле (биография, навыки, город, ссылки на социальные сети)</li>
                  <li>Контент, который вы создаете (посты, комментарии, лайки)</li>
                  <li>Данные об использовании платформы (активность, предпочтения)</li>
                  <li>Техническая информация (IP-адрес, тип браузера, устройство)</li>
                </ul>
              </div>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">3. Как мы используем ваши данные</h2>
              <div className="text-muted-foreground leading-relaxed space-y-3">
                <p>Ваши данные используются для:</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li>Предоставления и улучшения наших услуг</li>
                  <li>Персонализации вашего опыта</li>
                  <li>Обеспечения безопасности платформы</li>
                  <li>Связи с вами по вопросам сервиса</li>
                  <li>Аналитики и улучшения функциональности</li>
                </ul>
              </div>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">4. Передача данных третьим лицам</h2>
              <p className="text-muted-foreground leading-relaxed">
                Мы не продаем и не передаем ваши персональные данные третьим лицам, за исключением 
                случаев, когда это необходимо для предоставления услуг или требуется по закону. 
                Мы можем делиться данными с поставщиками услуг, которые помогают нам работать 
                (например, хостинг, аналитика), при условии соблюдения ими строгих требований 
                конфиденциальности.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">5. Безопасность данных</h2>
              <p className="text-muted-foreground leading-relaxed">
                Мы применяем современные меры безопасности для защиты ваших данных от несанкционированного 
                доступа, изменения, раскрытия или уничтожения. Это включает шифрование данных, 
                регулярные аудиты безопасности и ограничение доступа к персональным данным.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">6. Ваши права</h2>
              <div className="text-muted-foreground leading-relaxed space-y-3">
                <p>Вы имеете право:</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li>Получать информацию о том, какие данные мы о вас храним</li>
                  <li>Исправлять неточные или неполные данные</li>
                  <li>Удалять ваши данные</li>
                  <li>Ограничивать обработку ваших данных</li>
                  <li>Переносить ваши данные</li>
                  <li>Возражать против обработки ваших данных</li>
                </ul>
              </div>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">7. Cookies и отслеживание</h2>
              <p className="text-muted-foreground leading-relaxed">
                Мы используем cookies и аналогичные технологии для улучшения функциональности 
                платформы, анализа использования и персонализации контента. Вы можете управлять 
                настройками cookies в вашем браузере.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">8. Изменения в политике</h2>
              <p className="text-muted-foreground leading-relaxed">
                Мы можем обновлять эту Политику конфиденциальности время от времени. О существенных 
                изменениях мы уведомим вас через платформу или по email. Рекомендуем периодически 
                проверять эту страницу.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold mb-4">9. Контактная информация</h2>
              <p className="text-muted-foreground leading-relaxed">
                Если у вас есть вопросы по поводу этой Политики конфиденциальности или обработки 
                ваших персональных данных, пожалуйста, свяжитесь с нами через форму обратной связи 
                в приложении или по email: privacy@eventmarketplace.com
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
