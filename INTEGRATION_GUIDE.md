# Руководство по интеграции системы предложений специалистов

## Быстрый старт

### 1. Добавление маршрутов
Добавьте следующие маршруты в ваш `main.dart` или файл маршрутизации:

```dart
// В MaterialApp или GetMaterialApp
routes: {
  '/proposals': (context) => const ProposalsScreen(),
  '/organizer-proposals': (context) => const OrganizerProposalsScreen(),
  '/notifications': (context) => const NotificationsScreen(),
  '/specialist-selection': (context) => const SpecialistSelectionScreen(
    customerId: '', // Передается через arguments
    eventId: '', // Передается через arguments
  ),
},
```

### 2. Интеграция в чат
Замените ваш существующий чат на `ChatWithProposalButton`:

```dart
import 'package:your_app/widgets/chat_integration_example.dart';

// В вашем экране чата
ChatWithProposalButton(
  customerId: customerId,
  eventId: eventId,
  chatMessages: YourExistingChatWidget(),
)
```

### 3. Добавление бейджа уведомлений
Используйте `NotificationBadge` в AppBar:

```dart
import 'package:your_app/widgets/notification_badge.dart';

AppBar(
  title: Text('Заголовок'),
  actions: [
    NotificationBadge(
      child: IconButton(
        onPressed: () => Navigator.pushNamed(context, '/notifications'),
        icon: Icon(Icons.notifications),
      ),
    ),
  ],
)
```

## Детальная интеграция

### 1. Модель данных
Модель `SpecialistProposal` уже готова к использованию. Убедитесь, что у вас есть:
- Firestore коллекция `specialist_proposals`
- Индексы для запросов по `customerId`, `organizerId`, `status`

### 2. Сервисы
Все сервисы готовы к использованию:
- `ProposalService` - основная логика предложений
- `NotificationService` - уведомления
- `SpecialistService` - должен быть уже реализован

### 3. UI компоненты
Все экраны и виджеты готовы:
- `ProposalsScreen` - для заказчиков
- `OrganizerProposalsScreen` - для организаторов
- `SpecialistSelectionScreen` - выбор специалистов
- `NotificationsScreen` - уведомления
- `ProposeSpecialistsButton` - кнопка в чате
- `NotificationBadge` - счетчик уведомлений

## Настройка Firestore

### 1. Правила безопасности
Добавьте в `firestore.rules`:

```javascript
// Правила для предложений специалистов
match /specialist_proposals/{proposalId} {
  allow read, write: if request.auth != null && 
    (request.auth.uid == resource.data.organizerId || 
     request.auth.uid == resource.data.customerId);
  
  allow create: if request.auth != null && 
    request.auth.uid == request.resource.data.organizerId;
}

// Правила для уведомлений
match /notifications/{notificationId} {
  allow read, write: if request.auth != null && 
    request.auth.uid == resource.data.data.customerId;
  
  allow create: if request.auth != null;
}
```

### 2. Индексы
Создайте индексы в Firestore:

```json
{
  "indexes": [
    {
      "collectionGroup": "specialist_proposals",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "customerId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "specialist_proposals",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "organizerId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "specialist_proposals",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "customerId", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "data.customerId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    }
  ]
}
```

## Настройка уведомлений

### 1. Firebase Cloud Messaging
Убедитесь, что у вас настроен FCM:
- Добавлен `firebase_messaging` в `pubspec.yaml`
- Настроены токены устройств
- Сохранение FCM токенов в Firestore

### 2. Обработка уведомлений
Добавьте обработку уведомлений в `main.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

// Обработка уведомлений в фоне
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

// Обработка уведомлений в foreground
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Показать уведомление в приложении
});

// Обработка нажатия на уведомление
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Навигация к соответствующему экрану
});
```

## Тестирование

### 1. Создание тестовых данных
Создайте тестовые предложения:

```dart
// В тестовом файле или консоли
await ProposalService.createProposal(
  customerId: 'test_customer_id',
  eventId: 'test_event_id',
  specialistIds: ['specialist1', 'specialist2'],
  message: 'Тестовое предложение',
);
```

### 2. Проверка функциональности
1. Создайте предложение от организатора
2. Проверьте получение уведомления заказчиком
3. Примите/отклоните предложение
4. Проверьте бронирование специалистов

## Возможные проблемы и решения

### 1. Ошибки линтера
Если возникают ошибки линтера:
- Проверьте импорты
- Убедитесь, что все зависимости добавлены в `pubspec.yaml`
- Проверьте совместимость версий

### 2. Ошибки Firestore
- Проверьте правила безопасности
- Убедитесь, что индексы созданы
- Проверьте права доступа пользователей

### 3. Проблемы с уведомлениями
- Проверьте настройки FCM
- Убедитесь, что токены сохраняются
- Проверьте обработку уведомлений

## Расширение функциональности

### 1. Дополнительные статусы
Добавьте новые статусы в `SpecialistProposal`:
- `partially_accepted` - частично принято
- `expired` - истекло
- `cancelled` - отменено

### 2. Улучшения UI
- Добавьте фильтры и поиск
- Реализуйте пагинацию
- Добавьте анимации

### 3. Аналитика
- Отслеживайте статистику предложений
- Добавьте метрики использования
- Реализуйте отчеты

## Поддержка

При возникновении проблем:
1. Проверьте логи в консоли
2. Убедитесь в правильности настройки Firestore
3. Проверьте права доступа пользователей
4. Обратитесь к документации Firebase
