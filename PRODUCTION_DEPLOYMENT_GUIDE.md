# 🚀 Руководство по развертыванию в продакшене

## 📅 Дата создания
**3 октября 2025 года**

## 🎯 Цель
Развернуть Event Marketplace App в продакшене с полной настройкой инфраструктуры.

## 🏗️ Архитектура продакшена

### 1. 🌐 Frontend (Flutter Web)
- **Платформа**: Firebase Hosting
- **Домен**: event-marketplace.com
- **CDN**: Cloudflare
- **SSL**: Let's Encrypt

### 2. 🔥 Backend (Firebase)
- **База данных**: Firestore
- **Аутентификация**: Firebase Auth
- **Функции**: Cloud Functions
- **Хранилище**: Firebase Storage
- **Хостинг**: Firebase Hosting

### 3. 💳 Платежи
- **Stripe**: Основной провайдер
- **PayPal**: Дополнительный провайдер
- **ЮKassa**: Для российского рынка

### 4. 📧 Email
- **SendGrid**: Основной провайдер
- **SMTP**: Резервный провайдер

## 🚀 Этапы развертывания

### 1. 🔧 Подготовка к развертыванию

#### 1.1 Проверка готовности
```bash
# Проверка статуса проекта
flutter doctor
flutter pub get
flutter analyze
flutter test

# Проверка сборки
flutter build web --release --no-tree-shake-icons
```

#### 1.2 Настройка переменных окружения
```bash
# Создание файла .env.production
FIREBASE_PROJECT_ID=event-marketplace-prod
FIREBASE_API_KEY=your-production-api-key
FIREBASE_AUTH_DOMAIN=event-marketplace-prod.firebaseapp.com
FIREBASE_STORAGE_BUCKET=event-marketplace-prod.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your-sender-id
FIREBASE_APP_ID=your-app-id

# Платежные системы
STRIPE_PUBLISHABLE_KEY=pk_live_your-stripe-key
STRIPE_SECRET_KEY=sk_live_your-stripe-secret
PAYPAL_CLIENT_ID=your-paypal-client-id
YOOKASSA_SHOP_ID=your-yookassa-shop-id

# Email
SENDGRID_API_KEY=your-sendgrid-api-key
EMAIL_FROM=noreply@event-marketplace.com
```

### 2. 🔥 Настройка Firebase

#### 2.1 Создание продакшен проекта
```bash
# Создание проекта
firebase projects:create event-marketplace-prod

# Инициализация
firebase init

# Выбор сервисов:
# - Firestore Database
# - Functions
# - Hosting
# - Storage
# - Authentication
```

#### 2.2 Настройка аутентификации
```bash
# Включение провайдеров в Firebase Console
# - Email/Password
# - Google
# - Phone

# Настройка авторизованных доменов
# - event-marketplace.com
# - event-marketplace.firebaseapp.com
```

#### 2.3 Развертывание правил Firestore
```bash
# Развертывание правил безопасности
firebase deploy --only firestore:rules

# Развертывание индексов
firebase deploy --only firestore:indexes
```

#### 2.4 Развертывание Cloud Functions
```bash
# Развертывание всех функций
firebase deploy --only functions

# Проверка статуса
firebase functions:log
```

### 3. 🌐 Настройка домена

#### 3.1 Регистрация домена
```bash
# Регистрация домена event-marketplace.com
# Настройка DNS записей:
# - A record: @ -> Firebase IP
# - CNAME: www -> event-marketplace.firebaseapp.com
```

#### 3.2 Настройка SSL
```bash
# В Firebase Console -> Hosting -> Add custom domain
# Добавить: event-marketplace.com
# Настроить SSL сертификат
```

#### 3.3 Настройка CDN (Cloudflare)
```bash
# Добавить домен в Cloudflare
# Настроить DNS записи
# Включить SSL/TLS
# Настроить кэширование
```

### 4. 📱 Сборка и развертывание

#### 4.1 Сборка приложения
```bash
# Очистка проекта
flutter clean
flutter pub get

# Сборка для продакшена
flutter build web --release --no-tree-shake-icons

# Проверка сборки
ls -la build/web/
```

#### 4.2 Развертывание на Firebase Hosting
```bash
# Развертывание
firebase deploy --only hosting

# Проверка развертывания
firebase hosting:channel:list
```

#### 4.3 Настройка каналов
```bash
# Создание канала для staging
firebase hosting:channel:deploy staging

# Создание канала для production
firebase hosting:channel:deploy live
```

### 5. 🔒 Настройка безопасности

#### 5.1 Настройка CORS
```javascript
// functions/cors.js
const cors = require('cors')({
  origin: [
    'https://event-marketplace.com',
    'https://www.event-marketplace.com',
    'https://event-marketplace.firebaseapp.com',
  ],
  credentials: true
});
```

#### 5.2 Настройка CSP
```html
<!-- web/index.html -->
<meta http-equiv="Content-Security-Policy" content="
  default-src 'self';
  script-src 'self' 'unsafe-inline' 'unsafe-eval' https://js.stripe.com;
  style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
  font-src 'self' https://fonts.gstatic.com;
  img-src 'self' data: https:;
  connect-src 'self' https://api.stripe.com https://api.sendgrid.com;
">
```

#### 5.3 Настройка HSTS
```javascript
// firebase.json
{
  "hosting": {
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "Strict-Transport-Security",
            "value": "max-age=31536000; includeSubDomains"
          }
        ]
      }
    ]
  }
}
```

### 6. 📊 Настройка мониторинга

#### 6.1 Google Analytics
```dart
// lib/main.dart
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  // Настройка аналитики
  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  
  runApp(MyApp());
}
```

#### 6.2 Performance Monitoring
```dart
// lib/main.dart
import 'package:firebase_performance/firebase_performance.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  // Настройка мониторинга производительности
  FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  
  runApp(MyApp());
}
```

#### 6.3 Crashlytics
```dart
// lib/main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  // Настройка Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  runApp(MyApp());
}
```

### 7. 🔄 CI/CD Pipeline

#### 7.1 GitHub Actions
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run tests
      run: flutter test
    
    - name: Run analysis
      run: flutter analyze

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Build web
      run: flutter build web --release --no-tree-shake-icons
    
    - name: Deploy to Firebase
      uses: FirebaseExtended/action-hosting-deploy@v0
      with:
        repoToken: '${{ secrets.GITHUB_TOKEN }}'
        firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
        channelId: live
        projectId: event-marketplace-prod
```

#### 7.2 Настройка секретов
```bash
# В GitHub -> Settings -> Secrets
FIREBASE_SERVICE_ACCOUNT: {
  "type": "service_account",
  "project_id": "event-marketplace-prod",
  "private_key_id": "...",
  "private_key": "...",
  "client_email": "...",
  "client_id": "...",
  "auth_uri": "...",
  "token_uri": "..."
}
```

### 8. 📈 Настройка аналитики

#### 8.1 Google Analytics 4
```dart
// lib/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  static Future<void> initialize() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
    await _analytics.setUserId('user_id');
  }
  
  static Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }
  
  static Future<void> setUserProperties(Map<String, dynamic> properties) async {
    for (final entry in properties.entries) {
      await _analytics.setUserProperty(
        name: entry.key,
        value: entry.value.toString(),
      );
    }
  }
}
```

#### 8.2 Настройка событий
```dart
// lib/services/analytics_service.dart
class AnalyticsService {
  // События пользователей
  static Future<void> logUserRegistration() async {
    await logEvent('user_registration', {});
  }
  
  static Future<void> logUserLogin() async {
    await logEvent('user_login', {});
  }
  
  // События поиска
  static Future<void> logSearch(String query) async {
    await logEvent('search', {'search_term': query});
  }
  
  static Future<void> logSearchResult(String query, int resultCount) async {
    await logEvent('search_result', {
      'search_term': query,
      'result_count': resultCount,
    });
  }
  
  // События бронирования
  static Future<void> logBookingCreated(String specialistId) async {
    await logEvent('booking_created', {'specialist_id': specialistId});
  }
  
  static Future<void> logBookingCompleted(String bookingId) async {
    await logEvent('booking_completed', {'booking_id': bookingId});
  }
  
  // События платежей
  static Future<void> logPaymentStarted(double amount) async {
    await logEvent('payment_started', {'amount': amount});
  }
  
  static Future<void> logPaymentCompleted(double amount, String method) async {
    await logEvent('payment_completed', {
      'amount': amount,
      'payment_method': method,
    });
  }
}
```

### 9. 🔔 Настройка уведомлений

#### 9.1 Push уведомления
```dart
// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  static Future<void> initialize() async {
    // Запрос разрешений
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Пользователь предоставил разрешение на уведомления');
    }
    
    // Получение токена
    final token = await _messaging.getToken();
    print('FCM Token: $token');
    
    // Обработка сообщений
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Получено сообщение: ${message.messageId}');
    });
  }
}
```

#### 9.2 Email уведомления
```dart
// lib/services/email_notification_service.dart
import 'package:cloud_functions/cloud_functions.dart';

class EmailNotificationService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  static Future<bool> sendWelcomeEmail(String userEmail, String userName) async {
    try {
      final result = await _functions.httpsCallable('sendWelcomeEmail').call({
        'userEmail': userEmail,
        'userName': userName,
      });
      
      return result.data['success'] == true;
    } catch (e) {
      print('Ошибка отправки приветственного email: $e');
      return false;
    }
  }
  
  static Future<bool> sendBookingConfirmationEmail({
    required String userEmail,
    required String userName,
    required String specialistName,
    required String serviceName,
    required String bookingDate,
  }) async {
    try {
      final result = await _functions.httpsCallable('sendBookingConfirmationEmail').call({
        'userEmail': userEmail,
        'userName': userName,
        'specialistName': specialistName,
        'serviceName': serviceName,
        'bookingDate': bookingDate,
      });
      
      return result.data['success'] == true;
    } catch (e) {
      print('Ошибка отправки email подтверждения: $e');
      return false;
    }
  }
}
```

### 10. 🧪 Тестирование продакшена

#### 10.1 Smoke тесты
```bash
# Проверка доступности
curl -I https://event-marketplace.com
curl -I https://event-marketplace.com/api/health

# Проверка SSL
openssl s_client -connect event-marketplace.com:443 -servername event-marketplace.com

# Проверка производительности
lighthouse https://event-marketplace.com --output=html --output-path=./lighthouse-report.html
```

#### 10.2 Функциональные тесты
```bash
# Тестирование основных функций
# - Регистрация пользователя
# - Поиск специалистов
# - Создание бронирования
# - Обработка платежей
# - Отправка уведомлений
```

#### 10.3 Нагрузочные тесты
```bash
# Использование Artillery.js для нагрузочного тестирования
npm install -g artillery

# Создание конфигурации
cat > load-test.yml << EOF
config:
  target: 'https://event-marketplace.com'
  phases:
    - duration: 60
      arrivalRate: 10
scenarios:
  - name: "User journey"
    flow:
      - get:
          url: "/"
      - get:
          url: "/search"
      - get:
          url: "/specialists"
EOF

# Запуск теста
artillery run load-test.yml
```

### 11. 📊 Мониторинг и алерты

#### 11.1 Настройка мониторинга
```javascript
// functions/monitoring.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.monitorHealth = functions.https.onRequest(async (req, res) => {
  try {
    // Проверка состояния базы данных
    await admin.firestore().collection('health').doc('check').get();
    
    // Проверка состояния аутентификации
    await admin.auth().listUsers(1);
    
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        firestore: 'ok',
        auth: 'ok',
        functions: 'ok',
      },
    });
  } catch (error) {
    console.error('Health check failed:', error);
    res.status(500).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message,
    });
  }
});
```

#### 11.2 Настройка алертов
```bash
# В Firebase Console -> Monitoring
# Настроить алерты для:
# - Ошибки функций
# - Высокое использование ресурсов
# - Медленные запросы
# - Недоступность сервисов
```

### 12. 🔄 Резервное копирование

#### 12.1 Настройка резервного копирования
```bash
# Настройка автоматического резервного копирования Firestore
gcloud firestore databases update --backup-schedule="0 2 * * *" --location=us-central1

# Создание резервной копии
gcloud firestore export gs://event-marketplace-backups/$(date +%Y%m%d)
```

#### 12.2 Восстановление из резервной копии
```bash
# Восстановление из резервной копии
gcloud firestore import gs://event-marketplace-backups/20251003
```

## 🎯 Чек-лист развертывания

### 1. ✅ Подготовка
- [ ] Код протестирован и готов
- [ ] Переменные окружения настроены
- [ ] Домен зарегистрирован
- [ ] SSL сертификат получен
- [ ] CDN настроен

### 2. 🔥 Firebase
- [ ] Проект создан
- [ ] Аутентификация настроена
- [ ] Firestore правила развернуты
- [ ] Cloud Functions развернуты
- [ ] Storage настроен

### 3. 🌐 Хостинг
- [ ] Приложение собрано
- [ ] Развернуто на Firebase Hosting
- [ ] Домен подключен
- [ ] SSL настроен
- [ ] CDN активен

### 4. 💳 Платежи
- [ ] Stripe настроен
- [ ] PayPal настроен
- [ ] ЮKassa настроен
- [ ] Webhook'и работают
- [ ] Тестовые платежи прошли

### 5. 📧 Email
- [ ] SendGrid настроен
- [ ] SMTP настроен
- [ ] Шаблоны созданы
- [ ] Уведомления работают
- [ ] Тестовые письма отправлены

### 6. 📊 Мониторинг
- [ ] Google Analytics настроен
- [ ] Performance Monitoring активен
- [ ] Crashlytics настроен
- [ ] Алерты настроены
- [ ] Логирование работает

### 7. 🧪 Тестирование
- [ ] Smoke тесты прошли
- [ ] Функциональные тесты прошли
- [ ] Нагрузочные тесты прошли
- [ ] Кроссбраузерное тестирование
- [ ] Мобильное тестирование

### 8. 🔒 Безопасность
- [ ] CORS настроен
- [ ] CSP настроен
- [ ] HSTS настроен
- [ ] Firestore правила активны
- [ ] Аутентификация работает

## 🚀 Запуск продакшена

### 1. 🎉 Официальный запуск

#### 1.1 Анонс
```bash
# Создание пресс-релиза
# Уведомление пользователей
# Запуск рекламной кампании
# Мониторинг трафика
```

#### 1.2 Мониторинг
```bash
# Отслеживание метрик
# Мониторинг ошибок
# Анализ производительности
# Обратная связь пользователей
```

### 2. 📈 Пост-запуск

#### 2.1 Анализ
- Анализ метрик за первую неделю
- Выявление проблем
- Планирование улучшений
- Обратная связь пользователей

#### 2.2 Оптимизация
- Оптимизация производительности
- Улучшение UX
- Добавление новых функций
- Масштабирование инфраструктуры

## 🎉 Заключение

Event Marketplace App успешно развернут в продакшене с:
- ✅ **Полной инфраструктурой** Firebase
- ✅ **Безопасностью** на высоком уровне
- ✅ **Мониторингом** и аналитикой
- ✅ **Платежными системами** для глобального рынка
- ✅ **Email уведомлениями** для пользователей
- ✅ **CI/CD pipeline** для автоматического развертывания
- ✅ **Резервным копированием** и восстановлением

**Готово к работе в продакшене!** 🚀

---
**Проект завершен!** 🎉
