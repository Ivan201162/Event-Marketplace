# Настройка продакшн Firebase для Event Marketplace App

## Пошаговая инструкция

### Шаг 1: Создание проекта Firebase

1. Перейдите на [Firebase Console](https://console.firebase.google.com/)
2. Нажмите "Создать проект"
3. Введите название проекта: `event-marketplace-prod` (или любое другое)
4. Включите Google Analytics (рекомендуется)
5. Выберите аккаунт Google Analytics
6. Нажмите "Создать проект"

### Шаг 2: Настройка аутентификации

1. В левом меню выберите "Authentication"
2. Перейдите на вкладку "Sign-in method"
3. Включите следующие провайдеры:

#### Email/Password
- Нажмите "Email/Password"
- Включите "Email/Password" и "Email link (passwordless sign-in)"
- Нажмите "Сохранить"

#### Phone
- Нажмите "Phone"
- Включите "Phone"
- Нажмите "Сохранить"

#### Google
- Нажмите "Google"
- Включите "Google"
- Выберите проект поддержки (тот же проект)
- Нажмите "Сохранить"

### Шаг 3: Настройка Firestore Database

1. В левом меню выберите "Firestore Database"
2. Нажмите "Создать базу данных"
3. Выберите режим: "Начать в тестовом режиме" (для начала)
4. Выберите регион: "europe-west1" (ближайший к России)
5. Нажмите "Готово"

### Шаг 4: Настройка Storage

1. В левом меню выберите "Storage"
2. Нажмите "Начать"
3. Выберите режим: "Начать в тестовом режиме"
4. Выберите регион: "europe-west1"
5. Нажмите "Готово"

### Шаг 5: Получение конфигурационных файлов

#### Для Android:
1. В настройках проекта нажмите на иконку Android
2. Введите package name: `com.example.event_marketplace_app`
3. Введите название приложения: `Event Marketplace`
4. Нажмите "Зарегистрировать приложение"
5. Скачайте `google-services.json`
6. Поместите файл в `android/app/`

#### Для Web:
1. В настройках проекта нажмите на иконку Web
2. Введите название приложения: `Event Marketplace Web`
3. Включите "Настроить Firebase Hosting" (опционально)
4. Нажмите "Зарегистрировать приложение"
5. Скопируйте конфигурацию Firebase

#### Для iOS (если нужно):
1. В настройках проекта нажмите на иконку iOS
2. Введите bundle ID: `com.example.eventMarketplaceApp`
3. Введите название приложения: `Event Marketplace`
4. Нажмите "Зарегистрировать приложение"
5. Скачайте `GoogleService-Info.plist`
6. Поместите файл в `ios/Runner/`

### Шаг 6: Обновление конфигурации в коде

1. Откройте `lib/firebase_options.dart`
2. Замените тестовые значения на реальные из Firebase Console:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_REAL_WEB_API_KEY',
  appId: 'YOUR_REAL_WEB_APP_ID',
  messagingSenderId: 'YOUR_REAL_MESSAGING_SENDER_ID',
  projectId: 'your-real-project-id',
  authDomain: 'your-real-project-id.firebaseapp.com',
  storageBucket: 'your-real-project-id.appspot.com',
  measurementId: 'YOUR_REAL_MEASUREMENT_ID',
);
```

### Шаг 7: Настройка правил безопасности

#### Firestore Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Пользователи могут читать и писать только свои данные
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Специалисты - публичные данные для чтения
    match /specialists/{specialistId} {
      allow read: if true;
      allow write: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Бронирования - только участники могут читать
    match /bookings/{bookingId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         request.auth.uid == resource.data.specialistId);
    }
    
    // Сторис - публичные для чтения
    match /stories/{storyId} {
      allow read: if resource.data.isPublic == true;
      allow write: if request.auth != null && request.auth.uid == resource.data.authorId;
    }
    
    // Чат сообщения - только участники чата
    match /chat_messages/{messageId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.senderId || 
         request.auth.uid == resource.data.receiverId);
    }
  }
}
```

#### Storage Rules:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Шаг 8: Настройка доменов для авторизации

1. В Firebase Console перейдите в "Authentication" → "Settings"
2. В разделе "Authorized domains" добавьте:
   - `localhost` (для разработки)
   - Ваш домен (для продакшн)
   - `your-project-id.firebaseapp.com`

### Шаг 9: Настройка уведомлений

1. В левом меню выберите "Cloud Messaging"
2. Нажмите "Начать"
3. Скопируйте Server Key для отправки уведомлений
4. Настройте поддержку push-уведомлений в приложении

### Шаг 10: Мониторинг и аналитика

1. Настройте Crashlytics для отслеживания ошибок
2. Включите Performance Monitoring
3. Настройте Google Analytics для отслеживания пользователей

## Безопасность

⚠️ **ВАЖНО**: 
- Никогда не коммитьте реальные ключи Firebase в публичные репозитории
- Используйте переменные окружения для продакшн
- Настройте `.gitignore` для исключения конфигурационных файлов
- Используйте Firebase App Check для защиты от злоупотреблений

## Проверка настройки

После настройки проверьте:
1. Авторизация работает (email, phone, Google)
2. Firestore читает и записывает данные
3. Storage загружает и скачивает файлы
4. Push-уведомления приходят
5. Правила безопасности работают корректно

## Поддержка

Если возникли проблемы:
1. Проверьте логи в Firebase Console
2. Убедитесь, что все ключи скопированы правильно
3. Проверьте правила безопасности
4. Обратитесь к [документации Firebase](https://firebase.google.com/docs)


























