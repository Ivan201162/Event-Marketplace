# Внешние зависимости и настройка Firebase

## Firebase Console настройки

### 1. Firebase Authentication

#### Google Sign-In
1. Перейдите в Firebase Console → Authentication → Sign-in method
2. Включите Google провайдер
3. Добавьте в Authorized domains:
   - `localhost`
   - `*.web.app`
   - `*.firebaseapp.com`
   - Ваш домен (если есть)

#### Anonymous Authentication
1. Включите Anonymous провайдер в Authentication → Sign-in method

### 2. Firestore Database

#### Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Пользователи могут читать/редактировать только свой документ
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Публичные данные доступны всем авторизованным пользователям
    match /specialists/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    match /events/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.organizerId;
    }
    
    // Чат доступен только участникам
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.users;
    }
    
    match /chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.users;
    }
  }
}
```

### 3. Cloud Functions

#### Переменные окружения
Установите переменные окружения для VK OAuth:
```bash
firebase functions:config:set vk.client_id="YOUR_VK_APP_ID"
firebase functions:config:set vk.client_secret="YOUR_VK_APP_SECRET"
firebase functions:config:set vk.redirect_uri="http://localhost:8080/vk-callback"
```

#### Деплой функций
```bash
cd functions
npm install
firebase deploy --only functions
```

### 4. VK OAuth настройка

#### Создание VK приложения
1. Перейдите на https://vk.com/apps?act=manage
2. Создайте новое приложение
3. Получите App ID и App Secret
4. Настройте redirect URI: `http://localhost:8080/vk-callback`

#### Настройка в коде
Обновите константы в `lib/services/vk_auth_service.dart`:
```dart
static const String _vkClientId = 'YOUR_VK_APP_ID';
static const String _vkRedirectUri = 'http://localhost:8080/vk-callback';
```

### 5. Firebase Storage

#### Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Пользователи могут загружать файлы в свою папку
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Публичные файлы доступны всем
    match /public/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Файлы чатов доступны только участникам
    match /chats/{chatId}/{allPaths=**} {
      allow read, write: if request.auth != null && 
        request.auth.uid in firestore.get(/databases/$(database)/documents/chats/$(chatId)).data.users;
    }
  }
}
```

### 6. Firebase Hosting (опционально)

#### Настройка для Web
```bash
firebase init hosting
```

#### Деплой
```bash
flutter build web
firebase deploy --only hosting
```

## Локальная разработка

### 1. Firebase Emulators
```bash
firebase emulators:start
```

### 2. Переменные окружения
Создайте файл `.env` в корне проекта:
```
VK_CLIENT_ID=your_vk_app_id
VK_CLIENT_SECRET=your_vk_app_secret
VK_REDIRECT_URI=http://localhost:8080/vk-callback
```

### 3. Тестирование
```bash
flutter run -d chrome --web-port=8080
```

## Troubleshooting

### 1. Google Sign-In не работает
- Проверьте, что Google провайдер включен в Firebase Console
- Убедитесь, что домен добавлен в Authorized domains
- Проверьте, что popup не блокируется браузером

### 2. VK OAuth не работает
- Проверьте правильность VK App ID и Secret
- Убедитесь, что redirect URI совпадает с настройками VK
- Проверьте, что Cloud Functions развернуты

### 3. Firestore Rules блокируют доступ
- Проверьте правила безопасности
- Убедитесь, что пользователь авторизован
- Проверьте права доступа к коллекциям

### 4. CORS ошибки
- Убедитесь, что CORS настроен в Cloud Functions
- Проверьте, что домен разрешен в Firebase Console
