# v6.2.1-splash-init-fix — Отчёт о выполнении

## Версионирование

✅ **pubspec.yaml**: `version: 6.2.1+39`
✅ **lib/core/build_version.dart**: `BUILD_VERSION = 'v6.2.1-splash-init-fix'`
✅ **lib/main.dart**: `debugLog('APP: BUILD OK v6.2.1-splash-init-fix')`

## 1. Починить зависание на Splash

✅ **Реализовано**:
- Заменена цепочка инициализации в `main.dart` и `auth_gate.dart` на безопасную:
  - `await Firebase.initializeApp().timeout(Duration(seconds: 6))`
  - `await FirebaseAuth.instance.authStateChanges().timeout(Duration(seconds: 6)).first`
- Добавлен `Future.any` между `Firebase.initializeApp()` и `Future.delayed(Duration(seconds: 6))` через `.timeout()`
- Splash никогда не висит дольше 6 секунд

**Логи**:
- `SPLASH_INIT_START`
- `SPLASH_FIREBASE_INIT_OK`
- `SPLASH_FIREBASE_ALREADY_INIT`
- `SPLASH_TIMEOUT_RETRY`
- `SPLASH_AUTH_STATE_OK`
- `SPLASH_READY`

## 2. Добавить фолбэк при сбое Firebase init

✅ **Реализовано**:
- Если Firebase init кидает ошибку:
  - Логируется `SPLASH_INIT_FAILED:{error}`
  - Показывается экран ошибки с кнопкой "Повторить запуск"
- Создан `InitErrorScreen` для отображения ошибок инициализации

**Логи**:
- `SPLASH_INIT_FAILED:{error}`
- `INIT_ERROR:RETRY`

## 3. Исправить "висит до бесконечности"

✅ **Реализовано**:
- `StreamBuilder<User?>` в AuthGate использует таймаут:
  ```dart
  stream: FirebaseAuth.instance.authStateChanges().timeout(
    Duration(seconds: 6),
    onTimeout: (sink) {
      sink.add(null);
    },
  )
  ```
- Гарантированно получаем состояние даже при таймауте

**Логи**:
- `AUTH_GATE:STREAM_TIMEOUT`
- `AUTH_GATE:AUTH_STATE_TIMEOUT`

## 4. Добавить fallback в main.dart

✅ **Реализовано**:
- В блоке `runApp()`:
  - Если `Firebase.initializeApp()` падает, показывается оффлайн режим
  - Лог: `SPLASH_OFFLINE_MODE_ENABLED`
  - Приложение продолжает работу даже при ошибке инициализации

**Логи**:
- `SPLASH_OFFLINE_MODE_ENABLED`

## 5. Добавить логирование на каждом этапе Splash

✅ **Реализовано**:
- Все этапы логируются:
  - `SPLASH_INIT_START`
  - `SPLASH_FIREBASE_INIT_OK`
  - `SPLASH_AUTH_STATE_OK`
  - `SPLASH_READY` → goTo(AuthGate)
  - `SPLASH_INIT_FAILED:{error}`
  - `SPLASH_TIMEOUT_RETRY`

**Логи**:
- `SPLASH_INIT_START`
- `SPLASH_FIREBASE_INIT_OK`
- `SPLASH_FIREBASE_ALREADY_INIT`
- `SPLASH_AUTH_STATE_OK`
- `SPLASH_AUTH_STATE_TIMEOUT`
- `SPLASH_READY`
- `SPLASH_INIT_FAILED:{error}`
- `SPLASH_TIMEOUT_RETRY`

## 6. Убрать "вечный progress indicator"

✅ **Реализовано**:
- Splash имеет чёткий state machine:
  - `INIT` → `LOADING` → `READY` → `ERROR`
- Заменён безусловный `CircularProgressIndicator()` на анимированный логотип с плавным fade
- Индикатор показывается только в состоянии `LOADING`

**Состояния**:
- `SplashState.init` - начальное состояние
- `SplashState.loading` - загрузка (показывается индикатор)
- `SplashState.ready` - готово (переход в AuthGate)
- `SplashState.error` - ошибка (показывается InitErrorScreen)

## 7. Исправить sequence в AuthGate

✅ **Реализовано**:
- Если пользователь = null → сразу LoginScreen (через `Future.microtask` для исключения двойного срабатывания)
- Если пользователь = есть, но профиль пустой → OnboardingScreen
- Если всё заполнено → MainScreen
- Исключено двойное срабатывание `build()` через `Future.microtask`

**Логи**:
- `AUTH_GATE:USER:null` → `/login`
- `AUTH_GATE:USER:uid={uid}` → проверка профиля
- `ONBOARDING_REQUIRED:uid={uid}` → `/onboarding/role-name-city`
- `AUTH_GATE:PROFILE_CHECK:ok` → `/main`

## 8. Добавить визуальный fallback

✅ **Реализовано**:
- При зависании > 8 секунд показывается:
  - "Приложение загружается дольше обычного... Проверьте интернет."
  - Кнопка "Перезапустить"
- Логируется состояние зависания

**Логи**:
- `SPLASH:RETRY` (при нажатии "Перезапустить")

## 9. Проверить wipe при первом запуске

✅ **Реализовано**:
- Fresh-install wipe выполняется после успешной авторизации (как и было)
- Добавлен лог: `WIPE_BEFORE_INIT_DONE:not_first_run` если wipe не требуется

**Логи**:
- `WIPE_BEFORE_INIT_DONE:not_first_run`
- `FRESH_INSTALL_DETECTED:uid={uid}`
- `FRESH_WIPE_START:uid={uid}`
- `FRESH_WIPE_DONE:{uid}`

## 10. Финальные логи для проверки

✅ **Все логи добавлены**:
- `APP: BUILD OK v6.2.1-splash-init-fix`
- `SPLASH_INIT_START`
- `SPLASH_FIREBASE_INIT_OK`
- `SPLASH_AUTH_STATE_OK`
- `SPLASH_READY`

## Сборка, установка, тест

✅ **Выполнено**:
- `flutter clean` ✅
- `flutter pub get` ✅
- `flutter build apk --release --no-tree-shake-icons` ✅
- APK установлен на устройство: `34HDU20228002261` ✅
- Логи собраны: `logs/v6_2_1_splash_init_fix_logcat.txt` ✅

**APK**:
- Путь: `build/app/outputs/flutter-apk/app-release.apk`
- Размер: 80.3MB
- Версия: 6.2.1+39

## Итоги

Все задачи из промпта выполнены:
1. ✅ Починить зависание на Splash (таймауты и безопасная инициализация)
2. ✅ Добавить фолбэк при сбое Firebase init (InitErrorScreen)
3. ✅ Исправить "висит до бесконечности" (таймаут для StreamBuilder)
4. ✅ Добавить fallback в main.dart (оффлайн режим)
5. ✅ Добавить логирование на каждом этапе Splash
6. ✅ Убрать "вечный progress indicator" (state machine)
7. ✅ Исправить sequence в AuthGate (Future.microtask)
8. ✅ Добавить визуальный fallback при зависании > 8 сек
9. ✅ Проверить wipe при первом запуске (логирование)
10. ✅ Финальные логи для проверки

## Файлы

- ✅ `app-release.apk` (80.3MB)
- ✅ `logs/v6_2_1_splash_init_fix_logcat.txt`
- ✅ `REPORT_v6_2_1_splash_init_fix.md`

## Изменённые файлы

1. `pubspec.yaml` - версия 6.2.1+39
2. `lib/core/build_version.dart` - BUILD_VERSION = 'v6.2.1-splash-init-fix'
3. `lib/main.dart` - безопасная инициализация Firebase с таймаутами
4. `lib/core/auth_gate.dart` - таймауты для authStateChanges, исправлен sequence
5. `lib/screens/splash/splash_event_screen.dart` - state machine, визуальный fallback
6. `lib/screens/splash/init_error_screen.dart` - новый экран ошибки инициализации
7. `lib/core/app_router_minimal_working.dart` - добавлен маршрут для InitErrorScreen

