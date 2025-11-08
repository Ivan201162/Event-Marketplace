# v5.18.1-auth-splash-hotfix — Итоговый отчёт

## Версия и маркеры
- **Версия**: 5.18.1+29
- **Build Tag**: v5.18.1-auth-splash-hotfix
- **APK размер**: 80.0MB
- **APK путь**: `build/app/outputs/flutter-apk/app-release.apk`

## Выполненные исправления

### ✅ 1. Исправлен AuthGate с корректной логикой StreamBuilder
- **Файл**: `lib/core/auth_gate.dart`
- **Изменения**:
  - Заменён `listen()` на `StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges())`
  - Добавлена проверка `_wipeChecked` для fresh-install wipe
  - Разделена логика на `_AuthGateState` и `_ProfileCheckWidget`
  - Добавлены логи: `AUTH_GATE: user=null → show login`, `AUTH_GATE: user exists → checking profile`, `AUTH_GATE: profile incomplete → onboarding`, `AUTH_GATE: profile OK → main`

### ✅ 2. Исправлен Splash-экран
- **Файл**: `lib/screens/splash/splash_event_screen.dart`
- **Изменения**:
  - Убрана фиксированная задержка `Duration(milliseconds: 500)`
  - Добавлено ожидание инициализации Firebase (`_firebaseReady`)
  - Добавлено ожидание разрешения auth state (`_authStateReady`)
  - Добавлены логи: `SPLASH: Firebase init start`, `SPLASH: Firebase init complete`, `SPLASH: Auth state resolved`, `SPLASH_COMPLETE`
  - Splash остаётся на экране до завершения Firebase init + auth state

### ✅ 3. Обеспечен переход на онбординг после входа
- **Файл**: `lib/core/auth_gate.dart`
- **Логика**: После входа через Google/Email проверяется профиль:
  - Если документ не существует → `/onboarding/role-name-city`
  - Если отсутствуют обязательные поля (roles, firstName, lastName, city) → `/onboarding/role-name-city`
  - Только после заполнения профиля → `/main`

### ✅ 4. Главный экран защищён от неавторизованных пользователей
- **Файл**: `lib/screens/main_navigation_screen.dart`
- **Изменения**:
  - Добавлена проверка `FirebaseAuth.instance.currentUser == null`
  - При отсутствии пользователя → перенаправление на `/auth-gate`
  - Главный экран не отображается без авторизации

### ✅ 5. Удалено сообщение "Пользователь не авторизован"
- **Файл**: `lib/screens/home/home_screen_simple.dart`
- **Изменение**: Заменено `Text('Пользователь не авторизован')` на `CircularProgressIndicator()`
- **Примечание**: Остальные вхождения в сервисах оставлены (это исключения для бизнес-логики)

### ✅ 6. Исправлен WipeService для принудительного logout
- **Файл**: `lib/services/wipe_service.dart`
- **Изменения**:
  - После успешного wipe добавлен `FirebaseAuth.instance.signOut()`
  - Добавлен лог: `WIPE_LOGOUT_COMPLETE` / `WIPE_LOGOUT_ERR`
  - После wipe пользователь принудительно выходит из аккаунта

### ✅ 7. Fresh-install wipe оставлен включённым
- **Файл**: `lib/core/auth_gate.dart`
- **Логика**: В release режиме при первой установке:
  1. Обнаруживается пользователь
  2. Вызывается `WipeService.wipeTestUser(uid, hard: true)`
  3. Выполняется `FirebaseAuth.instance.signOut()`
  4. Отмечается первая установка как выполненная
  5. Показывается экран входа

## Изменённые файлы

1. `pubspec.yaml` - версия 5.18.1+29
2. `lib/core/build_version.dart` - BUILD_VERSION = 'v5.18.1-auth-splash-hotfix'
3. `lib/main.dart` - маркер сборки
4. `lib/core/auth_gate.dart` - полная переработка с StreamBuilder
5. `lib/screens/splash/splash_event_screen.dart` - ожидание Firebase init
6. `lib/screens/main_navigation_screen.dart` - проверка авторизации
7. `lib/services/wipe_service.dart` - принудительный logout после wipe
8. `lib/screens/home/home_screen_simple.dart` - удалено сообщение "Пользователь не авторизован"

## Ожидаемый flow

1. **Launch app** → Splash остаётся на экране
2. **Firebase init** → `SPLASH: Firebase init start` → `SPLASH: Firebase init complete`
3. **Auth state check** → `SPLASH: Auth state resolved` → `SPLASH_COMPLETE`
4. **IF first install** → `FRESH_INSTALL_DETECTED` → `WIPE_CALL` → `WIPE_DONE` → `WIPE_LOGOUT_COMPLETE` → `AUTH_GATE: user=null → show login`
5. **User logs in** → `AUTH_GATE: user exists → checking profile`
6. **If profile incomplete** → `AUTH_GATE: profile incomplete → onboarding` → `ONBOARDING_OPENED`
7. **After onboarding** → `AUTH_GATE: profile OK → main` → `HOME_LOADED`

## Логирование

Все требуемые логи добавлены:
- ✅ `AUTH_GATE: user=null → show login`
- ✅ `AUTH_GATE: user exists → checking profile`
- ✅ `AUTH_GATE: profile incomplete → onboarding`
- ✅ `AUTH_GATE: profile OK → main`
- ✅ `SPLASH: Firebase init start`
- ✅ `SPLASH: Firebase init complete`
- ✅ `SPLASH: Auth state resolved`
- ✅ `SPLASH_COMPLETE`
- ✅ `FRESH_INSTALL_DETECTED`
- ✅ `WIPE_LOGOUT_COMPLETE`

## Что НЕ тронуто

- ✅ UI styles (тема, шрифты, цвета)
- ✅ Bottom navigation
- ✅ Content system (posts, reels, stories)
- ✅ Stories, posts, reels logic
- ✅ Все остальные экраны и функциональность

## Итоговые артефакты

- `build/app/outputs/flutter-apk/app-release.apk` (80.0MB)
- `logs/v5_18_1_auth_splash_hotfix_logcat.txt` (логи запуска)
- `V5_18_1_AUTH_SPLASH_HOTFIX_REPORT.md` (этот отчёт)

## Статус

✅ **BUILD DONE**  
✅ **INSTALL DONE**  
✅ **ALL FIXES COMPLETED**

Авторизация и сплэш-экран исправлены. Приложение корректно обрабатывает авторизацию, онбординг и fresh-install wipe.

