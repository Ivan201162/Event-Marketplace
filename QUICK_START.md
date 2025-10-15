# 🚀 Быстрый старт Event Marketplace

## Установка и запуск

### 1. Клонирование и установка

```bash
# Клонируйте репозиторий
git clone <repository-url>
cd event-marketplace

# Установите зависимости
npm install
```

### 2. Настройка Supabase

1. **Создайте проект в Supabase**
   - Перейдите на [supabase.com](https://supabase.com)
   - Создайте новый проект
   - Дождитесь завершения инициализации

2. **Выполните SQL схему**
   - Откройте SQL Editor в Supabase Dashboard
   - Скопируйте и выполните содержимое `supabase-schema.sql`

3. **Настройте Storage**
   - Перейдите в Storage
   - Создайте bucket с именем `posts`
   - Установите публичный доступ

### 3. Настройка переменных окружения

```bash
# Скопируйте пример файла
cp env.example .env.local
```

Заполните `.env.local`:

```env
# Supabase (найдите в Settings > API)
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# App URL
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### 4. Запуск приложения

```bash
# Запустите в режиме разработки
npm run dev
```

Откройте [http://localhost:3000](http://localhost:3000) в браузере.

## Основные функции

### ✅ Что работает из коробки

- **Авторизация**: Email/пароль, OAuth (Google, GitHub, VK)
- **Профили**: Создание, редактирование, просмотр
- **Посты**: Текстовые, фото, видео посты
- **Поиск**: Поиск специалистов по имени и навыкам
- **Лайки и комментарии**: Взаимодействие с постами
- **Подписки**: Подписка на других пользователей
- **Лидерборд**: Топ специалистов недели
- **Настройки**: Управление профилем и уведомлениями

### 🎨 UI/UX

- **Адаптивный дизайн**: Работает на всех устройствах
- **Темная тема**: Современный темный интерфейс
- **Анимации**: Плавные переходы и эффекты
- **Мобильная навигация**: Удобная навигация на мобильных

## Структура проекта

```
├── app/                    # Next.js App Router
│   ├── auth/              # Авторизация
│   ├── api/               # API роуты
│   ├── settings/          # Настройки
│   ├── u/[username]/      # Профили
│   └── ...
├── components/            # React компоненты
├── lib/                   # Утилиты и хуки
│   ├── supabase.ts        # Supabase клиент
│   ├── utils.ts           # Утилиты
│   ├── types.ts           # TypeScript типы
│   └── ...
└── public/                # Статические файлы
```

## API Endpoints

### Авторизация
- `POST /auth/sign-in` - Вход
- `POST /auth/sign-up` - Регистрация
- `POST /auth/sign-out` - Выход

### Профили
- `GET /api/profile` - Получить профиль
- `PUT /api/profile` - Обновить профиль
- `GET /api/search` - Поиск профилей

### Посты
- `GET /api/posts` - Получить посты
- `POST /api/posts` - Создать пост
- `POST /api/posts/[id]/like` - Лайк поста
- `GET /api/posts/[id]/comments` - Комментарии
- `POST /api/posts/[id]/comments` - Добавить комментарий

### Подписки
- `POST /api/follow/[username]` - Подписаться/отписаться
- `GET /api/follow/[username]` - Статус подписки

### Лидерборд
- `GET /api/leaderboard` - Топ специалистов

## База данных

### Основные таблицы

- `profiles` - Профили пользователей
- `posts` - Посты
- `post_likes` - Лайки постов
- `post_comments` - Комментарии
- `follows` - Подписки

### View

- `weekly_stats` - Статистика за неделю для лидерборда

## OAuth настройка (опционально)

### Google OAuth

1. Создайте проект в [Google Cloud Console](https://console.cloud.google.com)
2. Включите Google+ API
3. Создайте OAuth 2.0 credentials
4. Добавьте redirect URI: `https://your-project.supabase.co/auth/v1/callback`

### GitHub OAuth

1. Создайте OAuth App в [GitHub Settings](https://github.com/settings/developers)
2. Добавьте redirect URI: `https://your-project.supabase.co/auth/v1/callback`

### VK OAuth

1. Создайте приложение в [VK Developers](https://vk.com/dev)
2. Настройте OAuth
3. Добавьте redirect URI: `https://your-project.supabase.co/auth/v1/callback`

## Команды разработки

```bash
# Запуск в режиме разработки
npm run dev

# Сборка для продакшна
npm run build

# Запуск продакшн версии
npm start

# Линтинг
npm run lint

# Проверка типов
npm run type-check
```

## Деплой

См. подробное руководство в [DEPLOYMENT.md](./DEPLOYMENT.md)

### Быстрый деплой на Vercel

```bash
# Установите Vercel CLI
npm i -g vercel

# Войдите в Vercel
vercel login

# Деплой
vercel

# Добавьте переменные окружения в Vercel Dashboard
# Деплой в продакшн
vercel --prod
```

## Поддержка

- 📖 Документация: [README.md](./README.md)
- 🚀 Деплой: [DEPLOYMENT.md](./DEPLOYMENT.md)
- 🐛 Issues: Создайте issue в репозитории

## Лицензия

MIT License