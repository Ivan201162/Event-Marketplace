# Отчёт: v6.1.2-google-auth-ABSOLUTE

## Версионирование
- **pubspec.yaml**: `6.1.2+37`
- **build_version.dart**: `v6.1.2-google-auth-ABSOLUTE`
- **main.dart**: Лог `APP: BUILD OK v6.1.2-google-auth-ABSOLUTE`

## Выполненные задачи

### 1. Версионирование и маркер ✅
- Обновлён `pubspec.yaml` → `version: 6.1.2+37`
- Обновлён `lib/core/build_version.dart` → `BUILD_VERSION = 'v6.1.2-google-auth-ABSOLUTE'`
- Добавлен лог в `main.dart`: `debugLog('APP: BUILD OK v6.1.2-google-auth-ABSOLUTE');`

### 2. Gradle / signing / google-services.json — предзащитные проверки ✅
- Обновлена таска `verifyGoogleServicesJson` в `android/app/build.gradle.kts`:
  - Проверка существования файла
  - Проверка наличия `package_name`
  - Проверка наличия `client_info`
- Подключён `com.google.gms.google-services` плагин
- Проверка `applicationId = "com.eventmarketplace.app"`

### 3. Firebase init + строгие логи ✅
- В `main.dart` добавлены логи:
  - `APP: RELEASE FLOW START`
  - `GOOGLE_JSON_CHECK:found` или `missing`
  - `GOOGLE_INIT:[DEFAULT]`

### 4. AuthGate — строгая маршрутизация ✅
- Обновлён `lib/core/auth_gate.dart`:
  - Используется `StreamBuilder<User?>` на `FirebaseAuth.instance.authStateChanges()`
  - Логи: `AUTH_GATE:USER:null` или `AUTH_GATE:USER:uid=...`
  - Жёсткая проверка профиля с логированием:
    - `AUTH_GATE:PROFILE_CHECK:missing_fields=[...]` или `ok`
    - `ONBOARDING_OPENED` при необходимости онбординга
    - `HOME_LOADED` при успешном переходе на главный экран

### 5. Fresh-install wipe — сохранён ✅
- Механизм wipe оставлен включённым для release
- Добавлены логи:
  - `FRESH_INSTALL_DETECTED:uid=...`
  - `WIPE_CALL:uid=...`
  - `WIPE_DONE:uid=...`
  - `LOGOUT:OK`
  - `FRESH_INSTALL_WIPE_COMPLETE:logged_out`

### 6. Роутер обновлён ✅
- `initialLocation` изменён на `/auth-gate`
- Используется `LoginScreenImproved` для экрана входа
- Google Sign-In обрабатывается через `auth_service_enhanced.dart`

### 7. Логирование Google Sign-In ✅
- В `lib/screens/auth/login_screen_improved.dart`:
  - `GOOGLE_BTN_TAP` при нажатии кнопки
- В `lib/services/auth_service_enhanced.dart`:
  - `GOOGLE_SIGNIN_START`
  - `GOOGLE_SIGNIN_SUCCESS`
  - `GOOGLE_SIGNIN_ERROR:{code}:{message}`
  - `GOOGLE_FIREBASE_AUTH_START`
  - `GOOGLE_FIREBASE_AUTH_SUCCESS`
  - `GOOGLE_FIREBASE_AUTH_ERROR:{code}:{message}`

## Сборка и установка

### APK
- **Размер**: 80.2 MB
- **Путь**: `build/app/outputs/flutter-apk/app-release.apk`
- **Версия**: 6.1.2+37 (v6.1.2-google-auth-ABSOLUTE)

### Установка
- Устройство: `34HDU20228002261`
- Команда установки: `adb -s 34HDU20228002261 install -r build/app/outputs/flutter-apk/app-release.apk`
- Команда запуска: `adb -s 34HDU20228002261 shell monkey -p com.eventmarketplace.app -c android.intent.category.LAUNCHER 1`

### Logcat
- Файл: `logs/v6_1_2_google_auth_absolute_logcat.txt`
- Маркеры для проверки:
  - `APP: BUILD OK v6.1.2-google-auth-ABSOLUTE`
  - `GOOGLE_JSON_CHECK:found`
  - `GOOGLE_BTN_TAP`
  - `GOOGLE_SIGNIN_START`
  - `GOOGLE_SIGNIN_SUCCESS`
  - `GOOGLE_FIREBASE_AUTH_SUCCESS: uid=...`
  - `AUTH_GATE:USER:...`
  - `AUTH_GATE:PROFILE_CHECK:...`
  - `ONBOARDING_OPENED` (если профиль неполный)
  - `HOME_LOADED` (если профиль полный)

## Изменённые файлы

1. `pubspec.yaml` - версия 6.1.2+37
2. `lib/core/build_version.dart` - BUILD_VERSION = 'v6.1.2-google-auth-ABSOLUTE'
3. `lib/main.dart` - логи Firebase init и BUILD OK
4. `lib/core/auth_gate.dart` - строгая маршрутизация с детальным логированием
5. `android/app/build.gradle.kts` - улучшенная проверка google-services.json
6. `lib/core/app_router_minimal_working.dart` - initialLocation = '/auth-gate'

## Примечания

- Используется существующий `LoginScreenImproved` с логированием `GOOGLE_BTN_TAP`
- Google Sign-In обрабатывается через `auth_service_enhanced.dart` с полным логированием
- Fresh-install wipe сохранён и работает только в release режиме
- AuthGate теперь строго проверяет профиль и перенаправляет на онбординг при необходимости

## Статус

✅ **Готово к тестированию**

APK собран и установлен на устройство. Необходимо протестировать Google Sign-In и проверить логи на наличие всех маркеров.

