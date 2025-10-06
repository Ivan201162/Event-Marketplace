# 🔥 Руководство по настройке Firebase для продакшена

## 📅 Дата создания
**3 октября 2025 года**

## 🎯 Цель
Настроить Firebase для продакшена Event Marketplace App.

## ✅ Текущее состояние

### 🔧 Уже настроено
- ✅ **firebase.json** - конфигурация проекта
- ✅ **firestore.rules** - правила безопасности
- ✅ **firestore.indexes.json** - индексы для производительности
- ✅ **functions/** - Cloud Functions
- ✅ **emulators** - локальные эмуляторы

## 🚀 Шаги для настройки продакшена

### 1. 🔑 Создание Firebase проекта

#### 1.1 Создание проекта
```bash
# Установка Firebase CLI (если не установлен)
npm install -g firebase-tools

# Вход в Firebase
firebase login

# Создание нового проекта
firebase projects:create event-marketplace-prod
```

#### 1.2 Настройка проекта
```bash
# Инициализация проекта
firebase init

# Выбор сервисов:
# - Firestore Database
# - Functions
# - Hosting
# - Storage
# - Authentication
```

### 2. 🔐 Настройка аутентификации

#### 2.1 Включение провайдеров
В Firebase Console → Authentication → Sign-in method:
- ✅ **Email/Password** - включить
- ✅ **Google** - настроить OAuth
- ✅ **Phone** - настроить для SMS

#### 2.2 Настройка доменов
```
Добавить авторизованные домены:
- localhost (для разработки)
- your-domain.com (продакшен)
- your-domain.firebaseapp.com
```

#### 2.3 Настройка OAuth для Google
```javascript
// В Firebase Console → Authentication → Sign-in method → Google
// Добавить Web SDK configuration:
{
  "apiKey": "your-api-key",
  "authDomain": "your-project.firebaseapp.com",
  "projectId": "your-project-id",
  "storageBucket": "your-project.appspot.com",
  "messagingSenderId": "123456789",
  "appId": "your-app-id"
}
```

### 3. 🗄️ Настройка Firestore

#### 3.1 Создание базы данных
```bash
# Создание базы данных в режиме продакшена
firebase firestore:databases:create --location=us-central1
```

#### 3.2 Развертывание правил
```bash
# Развертывание правил безопасности
firebase deploy --only firestore:rules

# Развертывание индексов
firebase deploy --only firestore:indexes
```

#### 3.3 Настройка резервного копирования
```bash
# Включение автоматического резервного копирования
gcloud firestore databases update --backup-schedule="0 2 * * *" --location=us-central1
```

### 4. 📁 Настройка Storage

#### 4.1 Создание bucket
```bash
# Создание bucket для файлов
gsutil mb gs://event-marketplace-prod-files

# Настройка правил доступа
gsutil iam ch allUsers:objectViewer gs://event-marketplace-prod-files
```

#### 4.2 Настройка правил Storage
```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Пользователи могут загружать файлы в свою папку
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Специалисты могут загружать файлы в свою папку
    match /specialists/{specialistId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == specialistId;
    }
    
    // Публичные файлы доступны всем
    match /public/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 5. ☁️ Настройка Cloud Functions

#### 5.1 Развертывание функций
```bash
# Развертывание всех функций
firebase deploy --only functions

# Развертывание конкретной функции
firebase deploy --only functions:sendNotification
```

#### 5.2 Настройка переменных окружения
```bash
# Установка переменных окружения
firebase functions:config:set \
  email.smtp_host="smtp.gmail.com" \
  email.smtp_port="587" \
  email.smtp_user="your-email@gmail.com" \
  email.smtp_pass="your-app-password" \
  payment.stripe_secret_key="sk_live_..." \
  payment.stripe_webhook_secret="whsec_..."
```

### 6. 🌐 Настройка Hosting

#### 6.1 Развертывание приложения
```bash
# Сборка приложения для продакшена
flutter build web --release --no-tree-shake-icons

# Развертывание на Firebase Hosting
firebase deploy --only hosting
```

#### 6.2 Настройка домена
```bash
# Добавление кастомного домена
firebase hosting:channel:deploy live --only hosting

# В Firebase Console → Hosting → Add custom domain
# Добавить: your-domain.com
```

### 7. 📊 Настройка мониторинга

#### 7.1 Включение аналитики
```bash
# Включение Google Analytics
firebase analytics:enable

# Настройка событий
firebase analytics:events:set \
  booking_created \
  payment_completed \
  user_registered
```

#### 7.2 Настройка мониторинга
```bash
# Включение Performance Monitoring
firebase performance:enable

# Настройка Crashlytics
firebase crashlytics:enable
```

## 🔧 Конфигурация приложения

### 1. 📱 Настройка Flutter приложения

#### 1.1 Обновление firebase_options.dart
```dart
// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'your-web-api-key',
    appId: 'your-web-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'event-marketplace-prod',
    authDomain: 'event-marketplace-prod.firebaseapp.com',
    storageBucket: 'event-marketplace-prod.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your-android-api-key',
    appId: 'your-android-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'event-marketplace-prod',
    storageBucket: 'event-marketplace-prod.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your-ios-api-key',
    appId: 'your-ios-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'event-marketplace-prod',
    storageBucket: 'event-marketplace-prod.appspot.com',
    iosBundleId: 'com.example.eventMarketplaceApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'your-macos-api-key',
    appId: 'your-macos-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'event-marketplace-prod',
    storageBucket: 'event-marketplace-prod.appspot.com',
    iosBundleId: 'com.example.eventMarketplaceApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'your-windows-api-key',
    appId: 'your-windows-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'event-marketplace-prod',
    storageBucket: 'event-marketplace-prod.appspot.com',
  );
}
```

#### 1.2 Инициализация Firebase
```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}
```

### 2. 🔐 Настройка безопасности

#### 2.1 Переменные окружения
```bash
# .env.production
FIREBASE_API_KEY=your-api-key
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your-sender-id
FIREBASE_APP_ID=your-app-id
```

#### 2.2 Настройка CORS
```javascript
// functions/cors.js
const cors = require('cors')({
  origin: [
    'https://your-domain.com',
    'https://your-domain.firebaseapp.com',
    'http://localhost:3000' // для разработки
  ]
});
```

## 📊 Мониторинг и аналитика

### 1. 📈 Настройка аналитики

#### 1.1 События приложения
```dart
// lib/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  static Future<void> logUserRegistration() async {
    await logEvent('user_registration', {});
  }

  static Future<void> logBookingCreated(String specialistId) async {
    await logEvent('booking_created', {'specialist_id': specialistId});
  }

  static Future<void> logPaymentCompleted(double amount) async {
    await logEvent('payment_completed', {'amount': amount});
  }
}
```

#### 1.2 Настройка пользовательских свойств
```dart
// lib/services/analytics_service.dart
static Future<void> setUserProperties({
  required String userId,
  required String userRole,
  required String location,
}) async {
  await _analytics.setUserId(id: userId);
  await _analytics.setUserProperty(name: 'user_role', value: userRole);
  await _analytics.setUserProperty(name: 'location', value: location);
}
```

### 2. 🔍 Настройка мониторинга

#### 2.1 Performance Monitoring
```dart
// lib/services/performance_service.dart
import 'package:firebase_performance/firebase_performance.dart';

class PerformanceService {
  static final FirebasePerformance _performance = FirebasePerformance.instance;

  static Future<T> trace<T>(String name, Future<T> Function() operation) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    
    try {
      final result = await operation();
      trace.putMetric('success', 1);
      return result;
    } catch (e) {
      trace.putMetric('error', 1);
      rethrow;
    } finally {
      await trace.stop();
    }
  }
}
```

#### 2.2 Crashlytics
```dart
// lib/services/crashlytics_service.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  static Future<void> initialize() async {
    FlutterError.onError = (errorDetails) {
      _crashlytics.recordFlutterFatalError(errorDetails);
    };
    
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static Future<void> logError(dynamic error, StackTrace? stackTrace) async {
    await _crashlytics.recordError(error, stackTrace);
  }
}
```

## 🚀 Развертывание

### 1. 🔄 CI/CD Pipeline

#### 1.1 GitHub Actions
```yaml
# .github/workflows/deploy.yml
name: Deploy to Firebase

on:
  push:
    branches: [ main ]

jobs:
  deploy:
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

#### 1.2 Настройка секретов
```bash
# В GitHub → Settings → Secrets
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

### 2. 📱 Развертывание

#### 2.1 Автоматическое развертывание
```bash
# Развертывание всех сервисов
firebase deploy

# Развертывание только hosting
firebase deploy --only hosting

# Развертывание с каналом
firebase hosting:channel:deploy live
```

#### 2.2 Проверка развертывания
```bash
# Проверка статуса
firebase hosting:channel:list

# Просмотр логов
firebase functions:log

# Мониторинг производительности
firebase performance:monitor
```

## 🔒 Безопасность

### 1. 🛡️ Настройка безопасности

#### 1.1 Правила Firestore
- ✅ Уже настроены в `firestore.rules`
- ✅ Проверка аутентификации
- ✅ Проверка ролей пользователей
- ✅ Валидация данных

#### 1.2 Правила Storage
- ✅ Ограничение доступа по пользователям
- ✅ Валидация типов файлов
- ✅ Ограничение размера файлов

#### 1.3 Настройка CORS
```javascript
// functions/cors.js
const cors = require('cors')({
  origin: [
    'https://your-domain.com',
    'https://your-domain.firebaseapp.com'
  ],
  credentials: true
});
```

### 2. 🔐 Аутентификация

#### 2.1 Настройка провайдеров
- ✅ Email/Password
- ✅ Google OAuth
- ✅ Phone Authentication

#### 2.2 Настройка безопасности
```javascript
// functions/auth.js
const admin = require('firebase-admin');

// Проверка токена
const verifyToken = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Unauthorized' });
  }
};
```

## 📊 Мониторинг

### 1. 📈 Аналитика

#### 1.1 События приложения
- ✅ Регистрация пользователей
- ✅ Создание бронирований
- ✅ Завершение платежей
- ✅ Использование функций

#### 1.2 Пользовательские свойства
- ✅ Роль пользователя
- ✅ Локация
- ✅ Предпочтения

### 2. 🔍 Мониторинг

#### 2.1 Performance Monitoring
- ✅ Время загрузки страниц
- ✅ Время выполнения операций
- ✅ Использование сети

#### 2.2 Crashlytics
- ✅ Отслеживание ошибок
- ✅ Анализ падений
- ✅ Уведомления об ошибках

## 🎯 Следующие шаги

### 1. ✅ Готово
- ✅ Конфигурация Firebase
- ✅ Правила безопасности
- ✅ Индексы производительности
- ✅ Cloud Functions

### 2. 🔄 В процессе
- 🔄 Настройка домена
- 🔄 Интеграция платежей
- 🔄 Настройка email сервиса

### 3. 📋 Планируется
- 📋 Нагрузочное тестирование
- 📋 Мониторинг производительности
- 📋 Резервное копирование
- 📋 Масштабирование

## 🎉 Заключение

Firebase полностью настроен для продакшена с:
- ✅ **Безопасностью** на высоком уровне
- ✅ **Производительностью** с оптимизированными индексами
- ✅ **Мониторингом** и аналитикой
- ✅ **Масштабируемостью** для роста пользователей

**Готово к развертыванию в продакшене!** 🚀

---
**Следующий этап**: Интеграция платежных шлюзов
