# Deployment Guide

## Обзор

Этот документ описывает процесс развертывания Event Marketplace App на различных платформах и окружениях.

## Предварительные требования

### Инструменты разработки

- Flutter SDK 3.35.x+
- Dart SDK 3.5.x+
- Firebase CLI
- Git
- Android Studio (для Android)
- Xcode (для iOS)
- Visual Studio (для Windows)

### Аккаунты и сервисы

- Firebase проект
- Google Play Console (для Android)
- Apple Developer Account (для iOS)
- GitHub Actions (для CI/CD)

## Настройка окружения

### 1. Клонирование репозитория

```bash
git clone https://github.com/your-username/event_marketplace_app.git
cd event_marketplace_app
```

### 2. Установка зависимостей

```bash
flutter pub get
```

### 3. Настройка Firebase

```bash
# Установка Firebase CLI
npm install -g firebase-tools

# Вход в Firebase
firebase login

# Инициализация проекта
firebase init

# Выберите следующие сервисы:
# - Firestore
# - Functions
# - Hosting
# - Storage
```

### 4. Конфигурация окружения

Создайте файл `.env` в корне проекта:

```env
# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
FIREBASE_STORAGE_BUCKET=your-project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_APP_ID=1:123456789:web:abcdef

# Google Services
GOOGLE_MAPS_API_KEY=your-maps-api-key
GOOGLE_SIGN_IN_CLIENT_ID=your-client-id

# Analytics
GOOGLE_ANALYTICS_ID=G-XXXXXXXXXX

# Feature Flags
ENABLE_CRASHLYTICS=true
ENABLE_ANALYTICS=true
ENABLE_PERFORMANCE_MONITORING=true
```

## Развертывание Firebase сервисов

### 1. Firestore Database

```bash
# Развертывание правил безопасности
firebase deploy --only firestore:rules

# Развертывание индексов
firebase deploy --only firestore:indexes
```

### 2. Firebase Functions

```bash
# Установка зависимостей
cd functions
npm install

# Развертывание функций
firebase deploy --only functions
```

### 3. Firebase Storage

```bash
# Развертывание правил безопасности
firebase deploy --only storage
```

### 4. Firebase Hosting (для Web)

```bash
# Сборка Web приложения
flutter build web --release

# Развертывание на Hosting
firebase deploy --only hosting
```

## Развертывание мобильных приложений

### Android

#### 1. Подготовка

```bash
# Генерация ключа подписи
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Создание файла key.properties
echo "storePassword=your-store-password
keyPassword=your-key-password
keyAlias=upload
storeFile=upload-keystore.jks" > android/key.properties
```

#### 2. Настройка build.gradle

```gradle
// android/app/build.gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### 3. Сборка APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (рекомендуется для Play Store)
flutter build appbundle --release
```

#### 4. Загрузка в Google Play Console

1. Войдите в [Google Play Console](https://play.google.com/console)
2. Создайте новое приложение
3. Загрузите App Bundle (.aab файл)
4. Заполните информацию о приложении
5. Настройте ценообразование и распространение
6. Отправьте на проверку

### iOS

#### 1. Настройка Xcode

```bash
# Открытие проекта в Xcode
open ios/Runner.xcworkspace
```

#### 2. Настройка подписи

1. В Xcode выберите Runner проект
2. Перейдите в Signing & Capabilities
3. Выберите Team (ваш Apple Developer Account)
4. Убедитесь, что Bundle Identifier уникален

#### 3. Сборка

```bash
# Debug сборка
flutter build ios --debug

# Release сборка
flutter build ios --release

# Archive для App Store
flutter build ipa --release
```

#### 4. Загрузка в App Store Connect

1. Войдите в [App Store Connect](https://appstoreconnect.apple.com)
2. Создайте новое приложение
3. Загрузите .ipa файл через Xcode или Application Loader
4. Заполните метаданные приложения
5. Отправьте на проверку

## Развертывание Desktop приложений

### Windows

#### 1. Сборка

```bash
# Debug сборка
flutter build windows --debug

# Release сборка
flutter build windows --release
```

#### 2. Создание установщика

```bash
# Установка MSIX tools
flutter install msix

# Создание MSIX пакета
flutter build windows --release
flutter pub run msix:create
```

### macOS

#### 1. Сборка

```bash
# Debug сборка
flutter build macos --debug

# Release сборка
flutter build macos --release
```

#### 2. Создание DMG

```bash
# Создание DMG файла
flutter build macos --release
cd build/macos/Build/Products/Release
hdiutil create -volname "Event Marketplace" -srcfolder "Event Marketplace.app" -ov -format UDZO "Event Marketplace.dmg"
```

### Linux

#### 1. Сборка

```bash
# Debug сборка
flutter build linux --debug

# Release сборка
flutter build linux --release
```

#### 2. Создание AppImage

```bash
# Установка linuxdeploy
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage

# Создание AppImage
./linuxdeploy-x86_64.AppImage --appdir AppDir --executable build/linux/x64/release/bundle/event_marketplace_app --desktop-file linux/event_marketplace_app.desktop --icon-file linux/event_marketplace_app.png --output appimage
```

## CI/CD с GitHub Actions

### 1. Настройка секретов

В GitHub репозитории добавьте следующие секреты:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_TOKEN`
- `GOOGLE_PLAY_SERVICE_ACCOUNT_KEY`
- `APPLE_CERTIFICATE`
- `APPLE_CERTIFICATE_PASSWORD`
- `APPLE_PROVISIONING_PROFILE`

### 2. Workflow для Android

```yaml
# .github/workflows/android.yml
name: Android Build and Deploy

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.x'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Run tests
      run: flutter test
      
    - name: Build APK
      run: flutter build apk --release
      
    - name: Build App Bundle
      run: flutter build appbundle --release
      
    - name: Deploy to Play Store
      if: startsWith(github.ref, 'refs/tags/')
      uses: r0adkll/upload-google-play@v1
      with:
        serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_KEY }}
        packageName: com.example.event_marketplace_app
        releaseFiles: build/app/outputs/bundle/release/app-release.aab
        track: production
```

### 3. Workflow для iOS

```yaml
# .github/workflows/ios.yml
name: iOS Build and Deploy

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build-and-deploy:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.x'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Run tests
      run: flutter test
      
    - name: Build iOS
      run: flutter build ios --release --no-codesign
      
    - name: Deploy to App Store
      if: startsWith(github.ref, 'refs/tags/')
      uses: apple-actions/upload-app-store@v1
      with:
        app-path: build/ios/iphoneos/Runner.app
        issuer-id: ${{ secrets.APPLE_ISSUER_ID }}
        api-key-id: ${{ secrets.APPLE_API_KEY_ID }}
        api-private-key: ${{ secrets.APPLE_API_PRIVATE_KEY }}
```

### 4. Workflow для Web

```yaml
# .github/workflows/web.yml
name: Web Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.x'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Build Web
      run: flutter build web --release
      
    - name: Deploy to Firebase Hosting
      uses: FirebaseExtended/action-hosting-deploy@v0
      with:
        repoToken: '${{ secrets.GITHUB_TOKEN }}'
        firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
        channelId: live
        projectId: ${{ secrets.FIREBASE_PROJECT_ID }}
```

## Мониторинг развертывания

### 1. Firebase Console

- **Analytics**: Отслеживание пользователей и событий
- **Crashlytics**: Мониторинг ошибок и сбоев
- **Performance**: Анализ производительности
- **Remote Config**: Управление конфигурацией

### 2. Google Play Console

- **Статистика**: Количество установок, рейтинги
- **Отчеты о сбоях**: Анализ ошибок
- **Отзывы**: Обратная связь пользователей

### 3. App Store Connect

- **Аналитика**: Метрики использования
- **Отчеты о сбоях**: Диагностика проблем
- **Отзывы**: Пользовательские оценки

## Откат развертывания

### 1. Firebase

```bash
# Откат к предыдущей версии
firebase hosting:channel:deploy previous --only hosting

# Откат функций
firebase functions:log
firebase functions:rollback
```

### 2. Мобильные приложения

- **Android**: Создайте новый релиз с исправлениями
- **iOS**: Используйте App Store Connect для отката

### 3. Web

```bash
# Откат к предыдущей версии
firebase hosting:channel:deploy previous --only hosting
```

## Безопасность развертывания

### 1. Секреты и ключи

- Никогда не коммитьте секреты в репозиторий
- Используйте переменные окружения
- Регулярно ротируйте ключи

### 2. Подписи приложений

- Храните ключи подписи в безопасном месте
- Используйте разные ключи для разных окружений
- Создайте резервные копии ключей

### 3. Права доступа

- Ограничьте доступ к production окружению
- Используйте принцип минимальных привилегий
- Регулярно проверяйте права доступа

## Troubleshooting

### Частые проблемы

#### 1. Ошибки сборки

```bash
# Очистка кэша
flutter clean
flutter pub get

# Обновление зависимостей
flutter pub upgrade
```

#### 2. Проблемы с Firebase

```bash
# Переустановка Firebase CLI
npm uninstall -g firebase-tools
npm install -g firebase-tools

# Повторная инициализация
firebase init
```

#### 3. Ошибки подписи

- Проверьте правильность ключей
- Убедитесь в корректности Bundle ID
- Проверьте срок действия сертификатов

### Логи и диагностика

```bash
# Логи Flutter
flutter logs

# Логи Firebase
firebase functions:log

# Логи Android
adb logcat

# Логи iOS
xcrun simctl spawn booted log stream --predicate 'process == "Runner"'
```

## Заключение

Этот гайд покрывает основные аспекты развертывания Event Marketplace App. Для успешного развертывания:

1. **Подготовьте окружение** - Установите все необходимые инструменты
2. **Настройте сервисы** - Конфигурируйте Firebase и другие сервисы
3. **Автоматизируйте процесс** - Используйте CI/CD для автоматического развертывания
4. **Мониторьте развертывание** - Отслеживайте метрики и ошибки
5. **Планируйте откаты** - Будьте готовы к быстрому откату при проблемах

Следуя этому гайду, вы сможете успешно развернуть приложение на всех поддерживаемых платформах.
