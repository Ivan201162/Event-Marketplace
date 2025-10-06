# Настройка Firebase для Event Marketplace App

## 1. Создание проекта Firebase

1. Перейдите на [Firebase Console](https://console.firebase.google.com/)
2. Нажмите "Создать проект"
3. Введите название проекта: `event-marketplace-app`
4. Включите Google Analytics (рекомендуется)
5. Выберите аккаунт Google Analytics

## 2. Настройка аутентификации

1. В левом меню выберите "Authentication"
2. Перейдите на вкладку "Sign-in method"
3. Включите следующие провайдеры:
   - **Email/Password** - для регистрации по email
   - **Phone** - для регистрации по телефону
   - **Google** - для входа через Google
4. Настройте домены для авторизации

## 3. Настройка Firestore Database

1. В левом меню выберите "Firestore Database"
2. Нажмите "Создать базу данных"
3. Выберите режим: "Начать в тестовом режиме" (для разработки)
4. Выберите регион: "europe-west1" (ближайший к России)

### Структура коллекций:
```
users/
  - {userId}/
    - email: string
    - displayName: string
    - role: string (customer/specialist/organizer)
    - createdAt: timestamp
    - updatedAt: timestamp

specialists/
  - {specialistId}/
    - userId: string
    - name: string
    - category: string
    - hourlyRate: number
    - rating: number
    - isVerified: boolean
    - createdAt: timestamp

bookings/
  - {bookingId}/
    - userId: string
    - specialistId: string
    - status: string
    - totalPrice: number
    - createdAt: timestamp

stories/
  - {storyId}/
    - authorId: string
    - content: string
    - mediaUrl: string
    - isPublic: boolean
    - createdAt: timestamp
```

## 4. Настройка Storage

1. В левом меню выберите "Storage"
2. Нажмите "Начать"
3. Выберите режим: "Начать в тестовом режиме"
4. Выберите регион: "europe-west1"

### Правила безопасности:
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

## 5. Настройка Cloud Functions (опционально)

1. В левом меню выберите "Functions"
2. Нажмите "Начать"
3. Установите Firebase CLI: `npm install -g firebase-tools`
4. Инициализируйте проект: `firebase init functions`

## 6. Получение конфигурационных файлов

### Для Android:
1. В настройках проекта нажмите на иконку Android
2. Введите package name: `com.example.event_marketplace_app`
3. Скачайте `google-services.json`
4. Поместите файл в `android/app/`

### Для Web:
1. В настройках проекта нажмите на иконку Web
2. Введите название приложения
3. Скопируйте конфигурацию Firebase

### Для iOS:
1. В настройках проекта нажмите на иконку iOS
2. Введите bundle ID: `com.example.eventMarketplaceApp`
3. Скачайте `GoogleService-Info.plist`
4. Поместите файл в `ios/Runner/`

## 7. Обновление конфигурации в коде

Замените тестовые ключи в `lib/firebase_options.dart` на реальные из Firebase Console.

## 8. Настройка правил безопасности Firestore

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
  }
}
```

## 9. Настройка уведомлений

1. В левом меню выберите "Cloud Messaging"
2. Настройте серверный ключ для отправки уведомлений
3. Добавьте поддержку push-уведомлений в приложение

## 10. Мониторинг и аналитика

1. Настройте Crashlytics для отслеживания ошибок
2. Включите Performance Monitoring
3. Настройте Google Analytics для отслеживания пользователей

## Безопасность

⚠️ **ВАЖНО**: Никогда не коммитьте реальные ключи Firebase в публичные репозитории!
- Используйте переменные окружения
- Настройте `.gitignore` для исключения конфигурационных файлов
- Используйте Firebase App Check для защиты от злоупотреблений








