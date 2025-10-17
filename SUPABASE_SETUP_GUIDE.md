# 🗄️ Руководство по настройке Supabase для Event Marketplace

## 📋 Пошаговая инструкция

### 1. Создание проекта Supabase

1. **Перейдите на [supabase.com](https://supabase.com)**
2. **Войдите в аккаунт** или создайте новый
3. **Нажмите "New Project"**
4. **Заполните данные проекта:**
   - **Name**: `event-marketplace-app`
   - **Database Password**: создайте надежный пароль (сохраните его!)
   - **Region**: выберите ближайший к вам регион
   - **Pricing Plan**: Free (достаточно для разработки)

### 2. Настройка базы данных

1. **Откройте SQL Editor** в панели Supabase
2. **Скопируйте и выполните** содержимое файла `supabase/social_schema.sql`
3. **Проверьте создание таблиц** в разделе "Table Editor"

### 3. Получение конфигурации

1. **Перейдите в Settings → API**
2. **Скопируйте следующие данные:**
   - **Project URL**
   - **anon public key**
   - **service_role key** (для админских операций)

### 4. Настройка RLS (Row Level Security)

RLS политики уже включены в схему, но убедитесь что они активны:

```sql
-- Проверка статуса RLS
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

### 5. Настройка аутентификации

1. **Перейдите в Authentication → Settings**
2. **Включите Email authentication**
3. **Настройте URL redirects** (для веб-версии):
   - `http://localhost:3000/auth/callback`
   - `https://yourdomain.com/auth/callback`

### 6. Настройка Storage (опционально)

1. **Перейдите в Storage**
2. **Создайте bucket** `avatars` для аватаров пользователей
3. **Настройте политики доступа**

## 🔧 Конфигурация приложения

### 1. Создание файла конфигурации

Создайте файл `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_ANON_KEY';
  static const String serviceRoleKey = 'YOUR_SERVICE_ROLE_KEY';
}
```

### 2. Инициализация Supabase

Обновите `lib/main.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  runApp(const ProviderScope(child: EventMarketplaceApp()));
}
```

## 📊 Добавление тестовых данных

### 1. Создание тестовых пользователей

Выполните в SQL Editor:

```sql
-- Вставка тестовых профилей
INSERT INTO profiles (id, username, name, avatar_url, city, bio, skills) VALUES
('user1', 'alex_photographer', 'Александр Фотографов', 'https://example.com/avatar1.jpg', 'Москва', 'Профессиональный фотограф с 5-летним опытом', ARRAY['Фотография', 'Свадьбы', 'Портреты']),
('user2', 'maria_dj', 'Мария DJ', 'https://example.com/avatar2.jpg', 'Санкт-Петербург', 'DJ и ведущая мероприятий', ARRAY['DJ', 'Ведущая', 'Музыка']),
('user3', 'dmitry_video', 'Дмитрий Видеограф', 'https://example.com/avatar3.jpg', 'Казань', 'Видеограф и монтажер', ARRAY['Видеосъемка', 'Монтаж', 'Аэросъемка']);

-- Вставка еженедельной статистики
INSERT INTO weekly_stats (user_id, score_7d) VALUES
('user1', 150),
('user2', 120),
('user3', 100);

-- Вставка подписок
INSERT INTO follows (follower_id, following_id) VALUES
('user2', 'user1'),
('user3', 'user1'),
('user1', 'user2');
```

### 2. Создание тестовых чатов

```sql
-- Создание чата
INSERT INTO chats (id) VALUES ('chat1');

-- Добавление участников
INSERT INTO chat_participants (chat_id, user_id) VALUES
('chat1', 'user1'),
('chat1', 'user2');

-- Добавление сообщений
INSERT INTO messages (chat_id, sender_id, text) VALUES
('chat1', 'user1', 'Привет! Интересует фотосъемка свадьбы'),
('chat1', 'user2', 'Здравствуйте! Расскажите подробнее о мероприятии'),
('chat1', 'user1', 'Свадьба 15 июня, около 50 гостей');
```

## 🔍 Проверка настройки

### 1. Проверка таблиц

```sql
-- Проверка всех таблиц
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

### 2. Проверка данных

```sql
-- Проверка профилей
SELECT * FROM profiles;

-- Проверка статистики
SELECT * FROM weekly_stats;

-- Проверка подписок
SELECT * FROM follows;
```

### 3. Тестирование функций

```sql
-- Тест функции получения лидеров
SELECT * FROM get_weekly_leaders('Москва', 5);

-- Тест функции создания чата
SELECT get_or_create_chat('user1', 'user3');
```

## 🚨 Важные замечания

### Безопасность
- **Никогда не коммитьте** ключи API в репозиторий
- **Используйте переменные окружения** для продакшена
- **Регулярно ротируйте** ключи API

### Производительность
- **Мониторьте** использование ресурсов
- **Настройте индексы** для часто используемых запросов
- **Используйте пагинацию** для больших списков

### Резервное копирование
- **Настройте автоматические бэкапы**
- **Тестируйте восстановление** данных
- **Документируйте** структуру данных

## 📱 Тестирование приложения

### 1. Локальное тестирование
```bash
flutter run --debug
```

### 2. Тестирование на устройстве
```bash
flutter run -d <device_id> --debug
```

### 3. Проверка функций
- ✅ Регистрация/авторизация
- ✅ Просмотр профилей
- ✅ Подписка/отписка
- ✅ Создание чатов
- ✅ Отправка сообщений
- ✅ Realtime обновления

## 🎯 Следующие шаги

1. **Настройте Supabase проект** по инструкции выше
2. **Добавьте конфигурацию** в приложение
3. **Загрузите тестовые данные**
4. **Протестируйте все функции**
5. **Настройте мониторинг** и логирование

---

**Готово!** Ваше социальное приложение Event Marketplace готово к использованию! 🎉




