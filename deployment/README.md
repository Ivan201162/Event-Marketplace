# Развертывание Event Marketplace App

## Обзор

Это руководство по развертыванию Flutter приложения Event Marketplace на различных платформах.

## Предварительные требования

- Flutter SDK 3.35.3 или выше
- Dart SDK 3.5.0 или выше
- Firebase CLI
- Android Studio (для Android)
- Xcode (для iOS)
- Node.js (для веб-развертывания)

## Настройка Firebase

### 1. Создание проекта Firebase

```bash
# Установка Firebase CLI
npm install -g firebase-tools

# Вход в Firebase
firebase login

# Создание проекта
firebase projects:create event-marketplace-app

# Инициализация Firebase в проекте
firebase init
```

### 2. Настройка Firestore

```bash
# Создание базы данных Firestore
firebase firestore:databases:create --region=us-central1

# Применение правил безопасности
firebase deploy --only firestore:rules
```

### 3. Настройка Authentication

```bash
# Включение Authentication в консоли Firebase
# Добавление провайдеров: Email/Password, Google, Apple
```

### 4. Настройка Cloud Messaging

```bash
# Настройка FCM в консоли Firebase
# Загрузка конфигурационных файлов
```

## Развертывание на Android

### 1. Подготовка

```bash
# Генерация ключа подписи
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Создание key.properties
echo "storePassword=your_store_password" > android/key.properties
echo "keyPassword=your_key_password" >> android/key.properties
echo "keyAlias=upload" >> android/key.properties
echo "storeFile=../upload-keystore.jks" >> android/key.properties
```

### 2. Сборка

```bash
# Debug сборка
flutter build apk --debug

# Release сборка
flutter build apk --release

# App Bundle для Google Play
flutter build appbundle --release
```

### 3. Развертывание

```bash
# Установка на устройство
flutter install

# Загрузка в Google Play Console
# Используйте app-release.aab файл
```

## Развертывание на iOS

### 1. Подготовка

```bash
# Установка CocoaPods
sudo gem install cocoapods

# Установка зависимостей
cd ios && pod install && cd ..
```

### 2. Сборка

```bash
# Debug сборка
flutter build ios --debug

# Release сборка
flutter build ios --release

# Archive для App Store
flutter build ipa --release
```

### 3. Развертывание

```bash
# Установка на симулятор
flutter run

# Загрузка в App Store Connect
# Используйте Runner.ipa файл
```

## Развертывание на Web

### 1. Сборка

```bash
# Debug сборка
flutter build web --debug

# Release сборка
flutter build web --release
```

### 2. Развертывание на Firebase Hosting

```bash
# Настройка Firebase Hosting
firebase init hosting

# Развертывание
firebase deploy --only hosting
```

### 3. Развертывание на других платформах

```bash
# Netlify
netlify deploy --prod --dir=build/web

# Vercel
vercel --prod build/web

# GitHub Pages
# Настройте GitHub Actions для автоматического развертывания
```

## Настройка CI/CD

### GitHub Actions

Создайте `.github/workflows/deploy.yml`:

```yaml
name: Deploy Event Marketplace

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.3'
    - run: flutter pub get
    - run: flutter test
    - run: flutter build apk --debug

  deploy-android:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.3'
    - run: flutter pub get
    - run: flutter build appbundle --release
    - uses: r0adkll/upload-google-play@v1
      with:
        serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
        packageName: com.example.event_marketplace
        releaseFiles: build/app/outputs/bundle/release/app-release.aab

  deploy-web:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.3'
    - run: flutter pub get
    - run: flutter build web --release
    - uses: FirebaseExtended/action-hosting-deploy@v0
      with:
        repoToken: '${{ secrets.GITHUB_TOKEN }}'
        firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
        channelId: live
        projectId: event-marketplace-app
```

## Мониторинг и аналитика

### 1. Firebase Analytics

```dart
// В main.dart
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Инициализация Analytics
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  
  runApp(const ProviderScope(child: MyApp()));
}
```

### 2. Crashlytics

```dart
// В main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Инициализация Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  runApp(const ProviderScope(child: MyApp()));
}
```

### 3. Performance Monitoring

```dart
// В main.dart
import 'package:firebase_performance/firebase_performance.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Инициализация Performance Monitoring
  FirebasePerformance performance = FirebasePerformance.instance;
  
  runApp(const ProviderScope(child: MyApp()));
}
```

## Переменные окружения

Создайте файл `.env`:

```env
# Firebase
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id

# API Keys
GOOGLE_MAPS_API_KEY=your_google_maps_key
PAYMENT_API_KEY=your_payment_api_key

# Environment
ENVIRONMENT=production
DEBUG_MODE=false
```

## Безопасность

### 1. Правила Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Пользователи могут читать и писать только свои данные
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Специалисты
    match /specialists/{specialistId} {
      allow read: if true; // Публичное чтение
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Бронирования
    match /bookings/{bookingId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.customerId || 
         request.auth.uid == resource.data.specialistId);
    }
    
    // Платежи
    match /payments/{paymentId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.customerId || 
         request.auth.uid == resource.data.specialistId);
    }
  }
}
```

### 2. Правила Storage

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /specialists/{specialistId}/{allPaths=**} {
      allow read: if true; // Публичное чтение
      allow write: if request.auth != null && 
        request.auth.uid == resource.metadata.userId;
    }
  }
}
```

## Резервное копирование

### 1. Автоматическое резервное копирование

```bash
# Создание скрипта резервного копирования
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
gcloud firestore export gs://your-backup-bucket/firestore-backup-$DATE
```

### 2. Восстановление

```bash
# Восстановление из резервной копии
gcloud firestore import gs://your-backup-bucket/firestore-backup-20231201_120000
```

## Масштабирование

### 1. Firestore

- Используйте индексы для оптимизации запросов
- Реализуйте пагинацию для больших коллекций
- Используйте кэширование для часто запрашиваемых данных

### 2. Cloud Functions

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendNotification = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    // Логика отправки уведомлений
  });
```

### 3. Load Balancing

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

## Мониторинг производительности

### 1. Метрики

- Время отклика API
- Использование памяти
- Количество активных пользователей
- Частота ошибок

### 2. Алерты

```yaml
# monitoring/alerts.yml
alerts:
  - name: High Error Rate
    condition: error_rate > 5%
    duration: 5m
    notification: email,slack
    
  - name: High Memory Usage
    condition: memory_usage > 80%
    duration: 2m
    notification: email
```

## Обновления

### 1. Hot Fixes

```bash
# Быстрое исправление критических ошибок
git checkout main
git pull origin main
flutter build apk --release
# Развертывание через CI/CD
```

### 2. Регулярные обновления

```bash
# Еженедельные обновления
git checkout main
git pull origin main
flutter pub upgrade
flutter test
flutter build appbundle --release
# Развертывание через CI/CD
```

## Troubleshooting

### Частые проблемы

1. **Ошибки сборки**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

2. **Проблемы с Firebase**
   ```bash
   firebase logout
   firebase login
   firebase use your-project-id
   ```

3. **Проблемы с зависимостями**
   ```bash
   flutter pub deps
   flutter pub upgrade
   ```

### Логи

```bash
# Android
adb logcat | grep flutter

# iOS
xcrun simctl spawn booted log stream --predicate 'process == "Runner"'

# Web
# Используйте DevTools в браузере
```

## Контакты

Для вопросов по развертыванию обращайтесь к команде разработки.

---

**Примечание**: Этот документ обновляется по мере развития проекта. Всегда проверяйте актуальную версию перед развертыванием.


