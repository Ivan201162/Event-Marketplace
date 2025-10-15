# 🚀 Руководство по деплою Event Marketplace

## Подготовка к деплою

### 1. Настройка Supabase

1. **Создайте проект в Supabase**
   - Перейдите на [supabase.com](https://supabase.com)
   - Создайте новый проект
   - Дождитесь завершения инициализации

2. **Выполните SQL схему**
   ```sql
   -- Скопируйте и выполните содержимое файла supabase-schema.sql
   -- в SQL Editor в Supabase Dashboard
   ```

3. **Настройте Storage**
   - Перейдите в Storage в Supabase Dashboard
   - Создайте bucket с именем `posts`
   - Установите публичный доступ

4. **Настройте OAuth провайдеров**
   - Перейдите в Authentication > Providers
   - Включите Google, GitHub, VK
   - Добавьте redirect URLs для каждого провайдера

### 2. Настройка переменных окружения

Создайте файл `.env.local` с следующими переменными:

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# OAuth Providers
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
VK_CLIENT_ID=your_vk_client_id
VK_CLIENT_SECRET=your_vk_client_secret
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret

# App
NEXT_PUBLIC_APP_URL=https://your-domain.com
```

## Деплой на Vercel (Рекомендуется)

### 1. Подготовка

1. **Установите Vercel CLI**
   ```bash
   npm i -g vercel
   ```

2. **Войдите в Vercel**
   ```bash
   vercel login
   ```

### 2. Деплой

1. **Инициализируйте проект**
   ```bash
   vercel
   ```

2. **Добавьте переменные окружения**
   - Перейдите в Vercel Dashboard
   - Откройте ваш проект
   - Перейдите в Settings > Environment Variables
   - Добавьте все переменные из `.env.local`

3. **Деплой**
   ```bash
   vercel --prod
   ```

### 3. Настройка домена

1. **Добавьте домен в Vercel**
   - Перейдите в Settings > Domains
   - Добавьте ваш домен
   - Настройте DNS записи

2. **Обновите переменные окружения**
   - Обновите `NEXT_PUBLIC_APP_URL` с новым доменом
   - Обновите redirect URLs в OAuth провайдерах

## Деплой на Netlify

### 1. Подготовка

1. **Создайте `netlify.toml`**
   ```toml
   [build]
     command = "npm run build"
     publish = ".next"
   
   [build.environment]
     NODE_VERSION = "18"
   ```

2. **Создайте `_redirects` в `public/`**
   ```
   /*    /index.html   200
   ```

### 2. Деплой

1. **Подключите репозиторий к Netlify**
   - Войдите в Netlify Dashboard
   - Нажмите "New site from Git"
   - Выберите ваш репозиторий

2. **Настройте переменные окружения**
   - Перейдите в Site settings > Environment variables
   - Добавьте все переменные

3. **Деплой**
   - Netlify автоматически задеплоит при push в main ветку

## Деплой на Railway

### 1. Подготовка

1. **Создайте `railway.json`**
   ```json
   {
     "build": {
       "builder": "NIXPACKS"
     },
     "deploy": {
       "startCommand": "npm start",
       "healthcheckPath": "/"
     }
   }
   ```

### 2. Деплой

1. **Подключите репозиторий**
   - Войдите в Railway Dashboard
   - Нажмите "New Project"
   - Выберите "Deploy from GitHub repo"

2. **Настройте переменные**
   - Перейдите в Variables
   - Добавьте все переменные окружения

## Деплой на DigitalOcean App Platform

### 1. Подготовка

1. **Создайте `.do/app.yaml`**
   ```yaml
   name: event-marketplace
   services:
   - name: web
     source_dir: /
     github:
       repo: your-username/event-marketplace
       branch: main
     run_command: npm start
     environment_slug: node-js
     instance_count: 1
     instance_size_slug: basic-xxs
     envs:
     - key: NODE_ENV
       value: production
   ```

### 2. Деплой

1. **Создайте приложение**
   - Войдите в DigitalOcean Dashboard
   - Перейдите в Apps
   - Нажмите "Create App"
   - Выберите GitHub репозиторий

2. **Настройте переменные**
   - Добавьте все переменные окружения

## Проверка после деплоя

### 1. Функциональные тесты

- [ ] Регистрация и вход работают
- [ ] OAuth провайдеры работают
- [ ] Создание постов работает
- [ ] Загрузка медиа работает
- [ ] Поиск работает
- [ ] Профили отображаются корректно

### 2. Производительность

- [ ] Страницы загружаются быстро
- [ ] Изображения оптимизированы
- [ ] API отвечает быстро

### 3. SEO

- [ ] Мета-теги настроены
- [ ] Sitemap доступен
- [ ] Robots.txt настроен

## Мониторинг

### 1. Логи

- Настройте мониторинг ошибок (Sentry, LogRocket)
- Отслеживайте производительность (Vercel Analytics, Google Analytics)

### 2. База данных

- Мониторьте использование Supabase
- Настройте алерты на превышение лимитов

### 3. Безопасность

- Регулярно обновляйте зависимости
- Мониторьте подозрительную активность
- Настройте rate limiting

## Обновления

### 1. Автоматические обновления

- Настройте автоматический деплой при push в main
- Используйте staging окружение для тестирования

### 2. Ручные обновления

```bash
# Обновите зависимости
npm update

# Проверьте безопасность
npm audit

# Задеплойте
vercel --prod
```

## Резервное копирование

### 1. База данных

- Настройте автоматические бэкапы в Supabase
- Экспортируйте данные регулярно

### 2. Медиа файлы

- Настройте репликацию Storage
- Регулярно проверяйте целостность файлов

## Поддержка

При возникновении проблем:

1. Проверьте логи в Vercel/Netlify/Railway
2. Проверьте статус Supabase
3. Проверьте переменные окружения
4. Обратитесь к документации провайдеров
