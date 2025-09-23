# API Endpoints - Event Marketplace App

## 📋 Обзор

Event Marketplace App использует Firebase как backend-as-a-service, предоставляя REST API через Firestore, Firebase Auth, Firebase Storage и Cloud Functions. Этот документ описывает все доступные API endpoints и их использование.

## 🔗 Базовые URL

### Firebase Services
- **Firestore**: `https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents`
- **Firebase Auth**: `https://identitytoolkit.googleapis.com/v1/accounts`
- **Firebase Storage**: `https://firebasestorage.googleapis.com/v0/b/{bucket}/o`
- **Cloud Functions**: `https://{region}-{project-id}.cloudfunctions.net`

### Web App
- **Production**: `https://eventmarketplace.app`
- **Staging**: `https://staging.eventmarketplace.app`
- **Development**: `http://localhost:3000`

## 🔐 Аутентификация

### Firebase Auth Endpoints

#### Регистрация пользователя
```http
POST https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={API_KEY}
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "returnSecureToken": true
}
```

**Ответ:**
```json
{
  "kind": "identitytoolkit#SignUpNewUserResponse",
  "idToken": "eyJhbGciOiJSUzI1NiIs...",
  "email": "user@example.com",
  "refreshToken": "AE0u-8...",
  "expiresIn": "3600",
  "localId": "user123"
}
```

#### Вход пользователя
```http
POST https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "returnSecureToken": true
}
```

#### Восстановление пароля
```http
POST https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key={API_KEY}
Content-Type: application/json

{
  "requestType": "PASSWORD_RESET",
  "email": "user@example.com"
}
```

#### Обновление токена
```http
POST https://securetoken.googleapis.com/v1/token?key={API_KEY}
Content-Type: application/json

{
  "grant_type": "refresh_token",
  "refresh_token": "AE0u-8..."
}
```

## 👥 Пользователи (Users)

### Firestore Collection: `users`

#### Получить пользователя
```http
GET https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/users/{userId}
Authorization: Bearer {idToken}
```

**Ответ:**
```json
{
  "name": "projects/{project-id}/databases/(default)/documents/users/user123",
  "fields": {
    "email": {
      "stringValue": "user@example.com"
    },
    "displayName": {
      "stringValue": "Иван Иванов"
    },
    "role": {
      "stringValue": "customer"
    },
    "isActive": {
      "booleanValue": true
    },
    "createdAt": {
      "timestampValue": "2024-01-01T00:00:00Z"
    },
    "lastLoginAt": {
      "timestampValue": "2024-01-15T10:30:00Z"
    }
  }
}
```

#### Создать/обновить пользователя
```http
PATCH https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/users/{userId}
Authorization: Bearer {idToken}
Content-Type: application/json

{
  "fields": {
    "email": {
      "stringValue": "user@example.com"
    },
    "displayName": {
      "stringValue": "Иван Иванов"
    },
    "role": {
      "stringValue": "customer"
    },
    "phone": {
      "stringValue": "+7 (999) 123-45-67"
    },
    "location": {
      "stringValue": "Москва"
    },
    "updatedAt": {
      "timestampValue": "2024-01-15T10:30:00Z"
    }
  }
}
```

#### Получить список пользователей (только для админов)
```http
GET https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/users?pageSize=20&orderBy=createdAt desc
Authorization: Bearer {adminToken}
```

## 🎨 Специалисты (Specialists)

### Firestore Collection: `specialists`

#### Получить специалиста
```http
GET https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/specialists/{specialistId}
Authorization: Bearer {idToken}
```

**Ответ:**
```json
{
  "name": "projects/{project-id}/databases/(default)/documents/specialists/specialist123",
  "fields": {
    "userId": {
      "stringValue": "user123"
    },
    "name": {
      "stringValue": "Анна Петрова"
    },
    "description": {
      "stringValue": "Профессиональный фотограф с 5-летним опытом"
    },
    "category": {
      "stringValue": "photographer"
    },
    "hourlyRate": {
      "doubleValue": 5000.0
    },
    "rating": {
      "doubleValue": 4.8
    },
    "reviewCount": {
      "integerValue": "25"
    },
    "isAvailable": {
      "booleanValue": true
    },
    "isVerified": {
      "booleanValue": true
    },
    "serviceAreas": {
      "arrayValue": {
        "values": [
          {"stringValue": "Москва"},
          {"stringValue": "Московская область"}
        ]
      }
    },
    "portfolioImages": {
      "arrayValue": {
        "values": [
          {"stringValue": "https://storage.googleapis.com/portfolio/image1.jpg"},
          {"stringValue": "https://storage.googleapis.com/portfolio/image2.jpg"}
        ]
      }
    }
  }
}
```

#### Поиск специалистов
```http
GET https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/specialists?where=category==photographer&where=isAvailable==true&orderBy=rating desc&pageSize=20
Authorization: Bearer {idToken}
```

#### Создать профиль специалиста
```http
POST https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/specialists
Authorization: Bearer {idToken}
Content-Type: application/json

{
  "fields": {
    "userId": {
      "stringValue": "user123"
    },
    "name": {
      "stringValue": "Анна Петрова"
    },
    "description": {
      "stringValue": "Профессиональный фотограф"
    },
    "category": {
      "stringValue": "photographer"
    },
    "hourlyRate": {
      "doubleValue": 5000.0
    },
    "serviceAreas": {
      "arrayValue": {
        "values": [
          {"stringValue": "Москва"}
        ]
      }
    },
    "isAvailable": {
      "booleanValue": true
    },
    "isVerified": {
      "booleanValue": false
    },
    "createdAt": {
      "timestampValue": "2024-01-15T10:30:00Z"
    },
    "updatedAt": {
      "timestampValue": "2024-01-15T10:30:00Z"
    }
  }
}
```

## 📅 Бронирования (Bookings)

### Firestore Collection: `bookings`

#### Создать бронирование
```http
POST https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/bookings
Authorization: Bearer {idToken}
Content-Type: application/json

{
  "fields": {
    "userId": {
      "stringValue": "user123"
    },
    "userName": {
      "stringValue": "Иван Иванов"
    },
    "userEmail": {
      "stringValue": "user@example.com"
    },
    "specialistId": {
      "stringValue": "specialist123"
    },
    "specialistName": {
      "stringValue": "Анна Петрова"
    },
    "eventDate": {
      "timestampValue": "2024-02-14T18:00:00Z"
    },
    "duration": {
      "integerValue": "4"
    },
    "location": {
      "stringValue": "Москва, Красная площадь"
    },
    "totalPrice": {
      "doubleValue": 20000.0
    },
    "status": {
      "stringValue": "pending"
    },
    "specialRequests": {
      "stringValue": "Свадебная фотосессия"
    },
    "createdAt": {
      "timestampValue": "2024-01-15T10:30:00Z"
    },
    "updatedAt": {
      "timestampValue": "2024-01-15T10:30:00Z"
    }
  }
}
```

#### Получить бронирования пользователя
```http
GET https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/bookings?where=userId==user123&orderBy=createdAt desc
Authorization: Bearer {idToken}
```

#### Обновить статус бронирования
```http
PATCH https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/bookings/{bookingId}
Authorization: Bearer {specialistToken}
Content-Type: application/json

{
  "fields": {
    "status": {
      "stringValue": "confirmed"
    },
    "updatedAt": {
      "timestampValue": "2024-01-15T11:00:00Z"
    }
  }
}
```

## 💬 Чаты (Chats)

### Firestore Collection: `chats`

#### Создать чат
```http
POST https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/chats
Authorization: Bearer {idToken}
Content-Type: application/json

{
  "fields": {
    "participants": {
      "arrayValue": {
        "values": [
          {"stringValue": "user123"},
          {"stringValue": "specialist123"}
        ]
      }
    },
    "lastMessage": {
      "stringValue": "Здравствуйте! Интересует ваша услуга"
    },
    "lastMessageAt": {
      "timestampValue": "2024-01-15T10:30:00Z"
    },
    "createdAt": {
      "timestampValue": "2024-01-15T10:30:00Z"
    },
    "updatedAt": {
      "timestampValue": "2024-01-15T10:30:00Z"
    }
  }
}
```

#### Получить чаты пользователя
```http
GET https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/chats?where=participants array-contains user123&orderBy=lastMessageAt desc
Authorization: Bearer {idToken}
```

### Firestore Subcollection: `chats/{chatId}/messages`

#### Отправить сообщение
```http
POST https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/chats/{chatId}/messages
Authorization: Bearer {idToken}
Content-Type: application/json

{
  "fields": {
    "senderId": {
      "stringValue": "user123"
    },
    "senderName": {
      "stringValue": "Иван Иванов"
    },
    "text": {
      "stringValue": "Здравствуйте! Интересует ваша услуга"
    },
    "timestamp": {
      "timestampValue": "2024-01-15T10:30:00Z"
    },
    "isRead": {
      "booleanValue": false
    }
  }
}
```

#### Получить сообщения чата
```http
GET https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/chats/{chatId}/messages?orderBy=timestamp asc&pageSize=50
Authorization: Bearer {idToken}
```

## ⭐ Отзывы (Reviews)

### Firestore Collection: `reviews`

#### Создать отзыв
```http
POST https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/reviews
Authorization: Bearer {idToken}
Content-Type: application/json

{
  "fields": {
    "userId": {
      "stringValue": "user123"
    },
    "userName": {
      "stringValue": "Иван Иванов"
    },
    "specialistId": {
      "stringValue": "specialist123"
    },
    "bookingId": {
      "stringValue": "booking123"
    },
    "rating": {
      "integerValue": "5"
    },
    "text": {
      "stringValue": "Отличный фотограф! Очень доволен результатом."
    },
    "createdAt": {
      "timestampValue": "2024-01-15T10:30:00Z"
    },
    "updatedAt": {
      "timestampValue": "2024-01-15T10:30:00Z"
    }
  }
}
```

#### Получить отзывы специалиста
```http
GET https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/reviews?where=specialistId==specialist123&orderBy=createdAt desc
Authorization: Bearer {idToken}
```

## 💳 Платежи (Payments)

### Cloud Functions

#### Создать платеж
```http
POST https://{region}-{project-id}.cloudfunctions.net/createPayment
Authorization: Bearer {idToken}
Content-Type: application/json

{
  "bookingId": "booking123",
  "amount": 20000.0,
  "currency": "RUB",
  "paymentMethod": "card"
}
```

**Ответ:**
```json
{
  "success": true,
  "paymentId": "payment123",
  "paymentUrl": "https://payment.gateway.com/pay/payment123",
  "status": "pending"
}
```

#### Проверить статус платежа
```http
GET https://{region}-{project-id}.cloudfunctions.net/checkPaymentStatus?paymentId=payment123
Authorization: Bearer {idToken}
```

**Ответ:**
```json
{
  "success": true,
  "paymentId": "payment123",
  "status": "completed",
  "amount": 20000.0,
  "currency": "RUB",
  "completedAt": "2024-01-15T10:35:00Z"
}
```

#### Возврат платежа
```http
POST https://{region}-{project-id}.cloudfunctions.net/refundPayment
Authorization: Bearer {adminToken}
Content-Type: application/json

{
  "paymentId": "payment123",
  "amount": 20000.0,
  "reason": "Отмена заказа"
}
```

## 📁 Файлы (Storage)

### Firebase Storage

#### Загрузить изображение профиля
```http
POST https://firebasestorage.googleapis.com/v0/b/{bucket}/o?name=profile_images/{userId}/avatar.jpg
Authorization: Bearer {idToken}
Content-Type: image/jpeg

[Binary image data]
```

#### Загрузить изображение портфолио
```http
POST https://firebasestorage.googleapis.com/v0/b/{bucket}/o?name=portfolio/{specialistId}/image_{timestamp}.jpg
Authorization: Bearer {idToken}
Content-Type: image/jpeg

[Binary image data]
```

#### Получить URL файла
```http
GET https://firebasestorage.googleapis.com/v0/b/{bucket}/o/profile_images%2F{userId}%2Favatar.jpg?alt=media
Authorization: Bearer {idToken}
```

## 🔔 Уведомления (Notifications)

### Cloud Functions

#### Отправить push-уведомление
```http
POST https://{region}-{project-id}.cloudfunctions.net/sendNotification
Authorization: Bearer {systemToken}
Content-Type: application/json

{
  "userId": "user123",
  "title": "Новое сообщение",
  "body": "У вас новое сообщение от специалиста",
  "type": "chat_message",
  "data": {
    "chatId": "chat123",
    "senderId": "specialist123"
  }
}
```

#### Получить уведомления пользователя
```http
GET https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/notifications?where=userId==user123&orderBy=createdAt desc&pageSize=20
Authorization: Bearer {idToken}
```

## 📊 Аналитика (Analytics)

### Cloud Functions

#### Отправить событие аналитики
```http
POST https://{region}-{project-id}.cloudfunctions.net/trackEvent
Authorization: Bearer {idToken}
Content-Type: application/json

{
  "eventName": "specialist_viewed",
  "parameters": {
    "specialistId": "specialist123",
    "category": "photographer",
    "location": "Москва"
  },
  "userId": "user123",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### Получить аналитику (только для админов)
```http
GET https://{region}-{project-id}.cloudfunctions.net/getAnalytics?startDate=2024-01-01&endDate=2024-01-31&metrics=users,bookings,revenue
Authorization: Bearer {adminToken}
```

**Ответ:**
```json
{
  "success": true,
  "data": {
    "totalUsers": 1250,
    "totalSpecialists": 180,
    "totalBookings": 340,
    "totalRevenue": 6800000.0,
    "averageRating": 4.6,
    "topCategories": [
      {"category": "photographer", "count": 120},
      {"category": "videographer", "count": 85},
      {"category": "host", "count": 60}
    ],
    "topCities": [
      {"city": "Москва", "count": 450},
      {"city": "Санкт-Петербург", "count": 280},
      {"city": "Новосибирск", "count": 120}
    ]
  }
}
```

## 🔍 Поиск

### Cloud Functions

#### Поиск специалистов
```http
POST https://{region}-{project-id}.cloudfunctions.net/searchSpecialists
Authorization: Bearer {idToken}
Content-Type: application/json

{
  "query": "фотограф",
  "filters": {
    "category": "photographer",
    "location": "Москва",
    "minRating": 4.0,
    "maxPrice": 10000.0,
    "isAvailable": true,
    "isVerified": true
  },
  "sortBy": "rating",
  "sortOrder": "desc",
  "page": 1,
  "pageSize": 20
}
```

**Ответ:**
```json
{
  "success": true,
  "results": [
    {
      "id": "specialist123",
      "name": "Анна Петрова",
      "category": "photographer",
      "rating": 4.8,
      "reviewCount": 25,
      "hourlyRate": 5000.0,
      "location": "Москва",
      "isAvailable": true,
      "isVerified": true,
      "portfolioImages": ["https://storage.googleapis.com/portfolio/image1.jpg"]
    }
  ],
  "totalCount": 45,
  "page": 1,
  "pageSize": 20,
  "hasMore": true
}
```

## 🛡️ Административные функции

### Управление пользователями

#### Получить всех пользователей (только для админов)
```http
GET https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/users?pageSize=100&orderBy=createdAt desc
Authorization: Bearer {adminToken}
```

#### Заблокировать пользователя
```http
PATCH https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/users/{userId}
Authorization: Bearer {adminToken}
Content-Type: application/json

{
  "fields": {
    "isActive": {
      "booleanValue": false
    },
    "banReason": {
      "stringValue": "Нарушение правил сообщества"
    },
    "bannedAt": {
      "timestampValue": "2024-01-15T10:30:00Z"
    },
    "updatedAt": {
      "timestampValue": "2024-01-15T10:30:00Z"
    }
  }
}
```

### Модерация контента

#### Получить жалобы
```http
GET https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/reports?where=isResolved==false&orderBy=createdAt desc
Authorization: Bearer {adminToken}
```

#### Решить жалобу
```http
PATCH https://firestore.googleapis.com/v1/projects/{project-id}/databases/(default)/documents/reports/{reportId}
Authorization: Bearer {adminToken}
Content-Type: application/json

{
  "fields": {
    "isResolved": {
      "booleanValue": true
    },
    "resolution": {
      "stringValue": "Жалоба рассмотрена, нарушений не найдено"
    },
    "resolvedAt": {
      "timestampValue": "2024-01-15T10:30:00Z"
    },
    "resolvedBy": {
      "stringValue": "admin123"
    }
  }
}
```

## 📱 Мобильные API

### Push-уведомления

#### Регистрация FCM токена
```http
POST https://{region}-{project-id}.cloudfunctions.net/registerFCMToken
Authorization: Bearer {idToken}
Content-Type: application/json

{
  "fcmToken": "fcm_token_here",
  "platform": "android",
  "appVersion": "1.0.0"
}
```

#### Отписаться от уведомлений
```http
DELETE https://{region}-{project-id}.cloudfunctions.net/unregisterFCMToken
Authorization: Bearer {idToken}
Content-Type: application/json

{
  "fcmToken": "fcm_token_here"
}
```

### Геолокация

#### Обновить местоположение
```http
POST https://{region}-{project-id}.cloudfunctions.net/updateLocation
Authorization: Bearer {idToken}
Content-Type: application/json

{
  "latitude": 55.7558,
  "longitude": 37.6176,
  "city": "Москва",
  "region": "Московская область",
  "country": "Россия"
}
```

## 🔧 Системные API

### Health Check
```http
GET https://{region}-{project-id}.cloudfunctions.net/health
```

**Ответ:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0",
  "services": {
    "firestore": "healthy",
    "auth": "healthy",
    "storage": "healthy",
    "functions": "healthy"
  }
}
```

### Версия API
```http
GET https://{region}-{project-id}.cloudfunctions.net/version
```

**Ответ:**
```json
{
  "version": "1.0.0",
  "buildNumber": "1",
  "buildDate": "2024-01-15T10:30:00Z",
  "environment": "production"
}
```

## 📋 Коды ошибок

### HTTP Status Codes
- **200** - Успешный запрос
- **201** - Ресурс создан
- **400** - Неверный запрос
- **401** - Не авторизован
- **403** - Доступ запрещен
- **404** - Ресурс не найден
- **409** - Конфликт (например, email уже используется)
- **429** - Слишком много запросов
- **500** - Внутренняя ошибка сервера

### Firebase Error Codes
- **auth/user-not-found** - Пользователь не найден
- **auth/wrong-password** - Неверный пароль
- **auth/email-already-in-use** - Email уже используется
- **auth/weak-password** - Слабый пароль
- **auth/invalid-email** - Неверный формат email
- **auth/user-disabled** - Пользователь заблокирован
- **auth/too-many-requests** - Слишком много попыток

### Firestore Error Codes
- **permission-denied** - Недостаточно прав доступа
- **not-found** - Документ не найден
- **already-exists** - Документ уже существует
- **failed-precondition** - Предварительное условие не выполнено
- **aborted** - Операция прервана
- **out-of-range** - Значение вне допустимого диапазона
- **unimplemented** - Функция не реализована
- **internal** - Внутренняя ошибка
- **unavailable** - Сервис недоступен
- **data-loss** - Потеря данных

## 🔒 Безопасность

### Аутентификация
Все API endpoints (кроме публичных) требуют аутентификации через Firebase Auth токен:

```http
Authorization: Bearer {idToken}
```

### Авторизация
Права доступа контролируются через Firestore Security Rules и проверяются в Cloud Functions.

### Rate Limiting
- **Публичные API**: 100 запросов в минуту на IP
- **Аутентифицированные API**: 1000 запросов в минуту на пользователя
- **Административные API**: 10000 запросов в минуту на админа

### Валидация данных
Все входящие данные валидируются на уровне Cloud Functions:
- Проверка типов данных
- Проверка обязательных полей
- Санитизация строковых данных
- Проверка размеров файлов

## 📊 Мониторинг

### Логирование
Все API вызовы логируются с метаданными:
- Время запроса
- IP адрес
- User ID (если аутентифицирован)
- Endpoint
- Статус ответа
- Время выполнения

### Метрики
- Количество запросов по endpoint
- Время ответа
- Процент ошибок
- Использование ресурсов

### Алерты
- Высокий процент ошибок (>5%)
- Медленное время ответа (>2 секунды)
- Необычная активность
- Превышение лимитов

---

Этот API обеспечивает полную функциональность Event Marketplace App для всех регионов России, включая аутентификацию, управление пользователями, бронирования, чаты, платежи и аналитику.




