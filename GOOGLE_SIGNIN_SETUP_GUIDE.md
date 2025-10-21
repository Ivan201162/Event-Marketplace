# 🔧 Google Sign-In Setup Guide

## Проблема
Ошибка `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10, null, null)` возникает из-за неправильной конфигурации OAuth Client ID в Firebase Console.

## ✅ Исправления в коде

### 1. Обновлен `firebase_options.dart`
- Исправлены реальные значения Firebase из `google-services.json`
- Project ID: `event-marketplace-mvp`
- API Key: `AIzaSyBcNT54NuncA9Nck-5VQYdbnxwl5pdzsmA`

### 2. Улучшена обработка ошибок в `auth_service.dart`
- Добавлена детализированная обработка ошибок Google Sign-In
- Проверка токенов аутентификации
- Правильная конфигурация GoogleSignIn

### 3. Улучшена обработка ошибок в UI
- `auth_screen.dart` - детализированные сообщения об ошибках
- `login_screen.dart` - понятные сообщения для пользователя
- Специальная обработка ошибки `ApiException: 10`

### 4. Обновлен `AndroidManifest.xml`
- Добавлена конфигурация Google Play Services

## 🔑 Требуется настройка в Firebase Console

### SHA-1 и SHA-256 ключи для debug keystore:
```
SHA-1: 8A:04:3E:65:47:27:BB:E9:69:5A:E5:21:F2:67:68:BF:62:ED:C9:F8
SHA-256: 6D:9E:0A:CF:57:F0:06:D6:62:E3:00:7E:EB:C6:17:F5:E8:1E:65:10:7B:13:DC:DF:EC:C8:ED:78:FE:86:FC:98
```

### Шаги настройки:

1. **Зайти в Firebase Console**: https://console.firebase.google.com/
2. **Выбрать проект**: `event-marketplace-mvp`
3. **Перейти в Authentication > Sign-in method**
4. **Включить Google Sign-In**
5. **Добавить OAuth Client ID для Android**:
   - Package name: `com.eventmarketplace.app`
   - SHA-1: `8A:04:3E:65:47:27:BB:E9:69:5A:E5:21:F2:67:68:BF:62:ED:C9:F8`
6. **Скачать обновленный `google-services.json`**
7. **Заменить файл** `android/app/google-services.json`

### Для production:
1. **Создать release keystore**
2. **Получить SHA-1 и SHA-256 для release keystore**
3. **Добавить в Firebase Console**
4. **Обновить `google-services.json`**

## 🧪 Тестирование

После настройки в Firebase Console:

1. **Очистить кэш**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Пересобрать**:
   ```bash
   flutter build apk --debug --no-shrink
   ```

3. **Установить**:
   ```bash
   adb uninstall com.eventmarketplace.app
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

4. **Протестировать Google Sign-In**:
   - Открыть приложение
   - Нажать "Войти через Google"
   - Проверить, что нет ошибки `ApiException: 10`

## 📱 Ожидаемый результат

- ✅ Google Sign-In работает без ошибок
- ✅ Пользователь видит понятные сообщения об ошибках
- ✅ Успешная авторизация перенаправляет на главный экран
- ✅ Профиль пользователя создается в Firebase Auth и Firestore

## ⚠️ Важные моменты

1. **Не использовать тестовые client_id** - только реальные из Firebase Console
2. **SHA ключи должны точно совпадать** с теми, что в Firebase Console
3. **Package name должен совпадать** с `applicationId` в `build.gradle`
4. **После изменения `google-services.json`** обязательно пересобрать приложение

## 🔍 Диагностика

Если ошибка `ApiException: 10` все еще возникает:

1. Проверить, что OAuth Client ID создан в Firebase Console
2. Проверить, что SHA-1 ключ точно совпадает
3. Проверить, что package name совпадает
4. Убедиться, что Google Sign-In включен в Firebase Console
5. Проверить, что `google-services.json` обновлен и пересобран

## 📞 Поддержка

Если проблема не решается:
1. Проверить логи: `adb logcat -s flutter`
2. Проверить Firebase Console на наличие ошибок
3. Убедиться, что все SHA ключи добавлены правильно
