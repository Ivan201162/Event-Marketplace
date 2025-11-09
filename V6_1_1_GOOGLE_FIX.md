# V6.1.1-Google-Fix: Отчёт о выполнении

## Версия
- **pubspec.yaml**: 6.1.1+36
- **BUILD_VERSION**: v6.1.1-google-fix
- **APK**: `build/app/outputs/flutter-apk/app-release.apk` (80.3 MB)

## Выполненные задачи

### 1. ✅ Детальное логирование Google Sign-In

Добавлены все требуемые логи на всех этапах авторизации:

- `GOOGLE_BTN_TAP` - при нажатии на кнопку входа через Google
- `GOOGLE_SIGNIN_START` - начало процесса входа
- `GOOGLE_SIGNIN_SUCCESS` - успешный вход через Google
- `GOOGLE_SIGNIN_ERROR:{code}:{message}` - ошибки входа через Google
- `GOOGLE_FIREBASE_AUTH_START` - начало аутентификации в Firebase
- `GOOGLE_FIREBASE_AUTH_SUCCESS` - успешная аутентификация в Firebase
- `GOOGLE_FIREBASE_AUTH_ERROR:{code}:{message}` - ошибки аутентификации в Firebase

**Файлы:**
- `lib/services/auth_service_enhanced.dart` - обновлено логирование в `signInWithGoogleRelease()`
- `lib/screens/auth/login_screen_improved.dart` - добавлен `GOOGLE_BTN_TAP`

### 2. ✅ Проверка и исправление интеграции Google → Firebase

Проверена и подтверждена корректная интеграция:

```dart
final googleUser = await _googleSignIn.signIn();
if (googleUser == null) {
  // Пользователь отменил вход
  throw FirebaseAuthException(code: 'canceled', ...);
}

final googleAuth = await googleUser.authentication;
final credential = GoogleAuthProvider.credential(
  idToken: googleAuth.idToken,
  accessToken: googleAuth.accessToken,
);

await FirebaseAuth.instance.signInWithCredential(credential);
```

**Добавлена обработка ошибок:**
- `network_error`
- `sign_in_failed`
- `missing_client_id`
- `invalid_request`
- `account_exists_with_different_credential`
- `unknown`
- `internal-error`
- `network-request-failed`

### 3. ✅ Auto-retry

Реализован автоматический повтор попытки (1 раз) для:
- `network-request-failed`
- `unknown`
- `internal-error`
- `sign_in_failed` (PlatformException)
- `network_error` (PlatformException)

При второй неудачной попытке выводится SnackBar с кнопкой "Попробуйте снова".

**Файлы:**
- `lib/services/auth_service_enhanced.dart` - логика retry в `signInWithGoogleRelease()`
- `lib/screens/auth/login_screen_improved.dart` - SnackBar с кнопкой повтора

### 4. ✅ Исправлен редирект

Обновлён `AuthGate` для корректной проверки профиля и редиректа:

**Логика:**
1. После успешного входа через Google → `AuthGate` проверяет профиль
2. Если профиль неполный (нет `firstName`, `lastName`, `city`, `roles`) → редирект на `/onboarding/role-name-city`
3. Если профиль полный → редирект на `/main`

**Добавлены логи:**
- `AUTH_GATE:PROFILE_CHECK:uid={uid}`
- `AUTH_GATE:PROFILE_CHECK:incomplete:doc_not_exists`
- `AUTH_GATE:PROFILE_CHECK:incomplete:missing_fields`
- `AUTH_GATE:PROFILE_CHECK:complete`
- `ONBOARDING_OPENED`

**Файлы:**
- `lib/core/auth_gate.dart` - обновлена логика проверки профиля

### 5. ✅ Fresh-install wipe

Добавлены явные логи для fresh-install wipe:

- `FRESH_WIPE_DONE:{uid}` - успешное выполнение wipe
- `FRESH_WIPE_ERR:failed` - ошибка wipe
- `LOGOUT:OK` - успешный выход
- `LOGOUT:ERR:{error}` - ошибка выхода

**Файлы:**
- `lib/core/auth_gate.dart` - обновлены логи в `_checkFreshInstall()`

### 6. ✅ Проверка google-services.json

Добавлена проверка наличия `google-services.json`:

- `GOOGLE_JSON_CHECK:found` - файл найден
- `GOOGLE_JSON_CHECK:missing` - файл отсутствует

**Файлы:**
- `lib/main.dart` - проверка в `main()`

## Изменённые файлы

1. `pubspec.yaml` - версия обновлена до 6.1.1+36
2. `lib/core/build_version.dart` - BUILD_VERSION = 'v6.1.1-google-fix'
3. `lib/main.dart` - добавлена проверка google-services.json, обновлена версия
4. `lib/services/auth_service_enhanced.dart` - улучшено логирование, добавлен auto-retry
5. `lib/screens/auth/login_screen_improved.dart` - добавлен GOOGLE_BTN_TAP, SnackBar с повтором
6. `lib/core/auth_gate.dart` - улучшена проверка профиля, добавлены логи
7. `lib/providers/theme_provider.dart` - исправлены импорты для сборки

## Сборка APK

**Команда:**
```bash
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

**Результат:**
- ✅ APK успешно собран
- 📦 Размер: 80.3 MB
- 📍 Путь: `build/app/outputs/flutter-apk/app-release.apk`

## Ожидаемые логи при тестировании

При успешном входе через Google должны появиться следующие логи:

```
GOOGLE_JSON_CHECK:found
APP: BUILD OK v6.1.1-google-fix
APP_VERSION:6.1.1+36
GOOGLE_BTN_TAP
GOOGLE_SIGNIN_START:attempt=1
GOOGLE_SIGNIN_STEP:signIn
GOOGLE_SIGNIN_STEP:getTokens
GOOGLE_FIREBASE_AUTH_START
GOOGLE_FIREBASE_AUTH_STEP:signInWithCredential
GOOGLE_SIGNIN_SUCCESS:{uid}
GOOGLE_FIREBASE_AUTH_SUCCESS:{uid}
AUTH_GATE:PROFILE_CHECK:uid={uid}
AUTH_GATE:PROFILE_CHECK:incomplete:missing_fields
ONBOARDING_OPENED
```

## Установка и тестирование

### Установка APK

**Команды:**
```bash
adb -s 34HDU20228002261 uninstall com.eventmarketplace.app
adb -s 34HDU20228002261 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s 34HDU20228002261 shell monkey -p com.eventmarketplace.app -c android.intent.category.LAUNCHER 1
```

**Результат установки:**
- APK успешно установлен на устройство 34HDU20228002261
- Приложение запущено автоматически

### Logcat маркеры

Собран logcat с ключевыми маркерами в файле `logs/v6_1_1_google_fix_logcat.txt`.

**Ожидаемые маркеры при тестировании:**
- `GOOGLE_JSON_CHECK:found`
- `APP: BUILD OK v6.1.1-google-fix`
- `APP_VERSION:6.1.1+36`
- `GOOGLE_BTN_TAP`
- `GOOGLE_SIGNIN_START:attempt=1`
- `GOOGLE_SIGNIN_SUCCESS:{uid}`
- `GOOGLE_FIREBASE_AUTH_SUCCESS:{uid}`
- `AUTH_GATE:PROFILE_CHECK:uid={uid}`
- `ONBOARDING_OPENED` (если профиль неполный)

## Чек-лист для ручной проверки

- [x] Установить APK на устройство 34HDU20228002261
- [ ] Выполнить fresh-install wipe (должен сработать автоматически)
- [ ] Нажать кнопку "Войти через Google"
- [ ] Проверить, что нет ошибок `firebase_auth/unknown`
- [ ] Убедиться, что после входа открывается онбординг (если профиль неполный)
- [ ] Проверить, что не появляется "Пользователь не авторизован"
- [ ] Заполнить онбординг (firstName, lastName, city, roles)
- [ ] Проверить, что после онбординга открывается главный экран

## Примечания

- Auto-retry выполняется только 1 раз (не 2, как было ранее)
- Все ошибки логируются с кодами и сообщениями
- SnackBar с кнопкой "Попробуйте снова" появляется при неудачной второй попытке
- Fresh-install wipe работает только в release режиме

