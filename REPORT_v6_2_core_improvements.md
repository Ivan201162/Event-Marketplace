# v6.2-core-improvements — Отчёт о выполнении

## Версионирование

✅ **pubspec.yaml**: `version: 6.2.0+37`
✅ **lib/core/build_version.dart**: `BUILD_VERSION = 'v6.2-core-improvements'`
✅ **lib/main.dart**: `debugLog('APP: BUILD OK v6.2-core-improvements')`

## 1. Google Sign-In — Полный фикс

✅ **Реализовано**:
- Полный стек логов: `GOOGLE_BTN_TAP`, `GOOGLE_SIGNIN_START`, `GOOGLE_SIGNIN_SUCCESS`, `GOOGLE_SIGNIN_ERROR`, `GOOGLE_FIREBASE_AUTH_START`, `GOOGLE_FIREBASE_AUTH_SUCCESS`, `GOOGLE_FIREBASE_AUTH_ERROR`
- Авто-повтор (1 раз) при `network-request-failed`, `internal-error`, `unknown`
- При повторной неудаче выводится SnackBar: "Ошибка входа. Попробуйте снова."
- Убеждено, что Google аккаунт реально выбирается (не silentSignIn)
- После успешного Google входа — жёсткий переход в ONBOARDING, если профиль не заполнен

**Логи**:
- `GOOGLE_BTN_TAP`
- `GOOGLE_SIGNIN_START`
- `GOOGLE_SIGNIN_SUCCESS:email={email}`
- `GOOGLE_SIGNIN_ERROR:{code}`
- `GOOGLE_FIREBASE_AUTH_START`
- `GOOGLE_FIREBASE_AUTH_SUCCESS:uid={uid}`
- `GOOGLE_FIREBASE_AUTH_ERROR:{code}:{message}`
- `GOOGLE_AUTH_RETRY:code={code}`

## 2. Обязательный онбординг после Google

✅ **Реализовано**:
- После первой авторизации вход блокируется, пока не заполнены: `firstName`, `lastName`, `city`, `roles` (1–3)
- Если хотя бы одно поле отсутствует → редирект только на `/onboarding/role-name-city`
- Добавлен лог: `ONBOARDING_REQUIRED:{uid}`

**Логи**:
- `ONBOARDING_REQUIRED:uid={uid}`
- `ONBOARDING_OPENED`

## 3. Человеческие ошибки авторизации

✅ **Реализовано**:
- Firebase auth error codes → нормальные тексты:
  - `invalid-email` → "Неверный email"
  - `wrong-password` → "Неверный пароль"
  - `user-not-found` → "Пользователь не найден"
  - `network-request-failed` → "Нет соединения"
  - `too-many-requests` → "Слишком много попыток. Подождите"
- Добавлена обработка fallback ошибок: "Произошла ошибка. Попробуйте ещё раз"
- Логируются все ошибки: `AUTH_ERR:{code}`

**Логи**:
- `AUTH_ERR:{code}`
- `AUTH_EMAIL_LOGIN:{result}`

## 4. Полный fresh install wipe

✅ **Реализовано**:
- При новой установке автоматически:
  1) удалить пользователя из Firebase Auth (если есть)
  2) удалить user doc из Firestore
  3) удалить Storage uploads (если есть)
- Добавлены логи:
  - `FRESH_INSTALL_DETECTED`
  - `FRESH_WIPE_START`
  - `FRESH_WIPE_DONE`

**Логи**:
- `FRESH_INSTALL_DETECTED:uid={uid}`
- `FRESH_WIPE_START:uid={uid}`
- `FRESH_WIPE:AUTH_USER_DELETED`
- `FRESH_WIPE:FIRESTORE_USER_DELETED`
- `FRESH_WIPE:STORAGE_DELETED`
- `FRESH_WIPE_DONE:{uid}`

## 5. Auth Debug Overlay (секретное меню)

✅ **Реализовано**:
- 5 быстрых тапов по логотипу → включить debug overlay
- Показывается:
  - Firebase init: true/false
  - Auth state: signed in / signed out
  - User ID: uid / null
  - Fresh wipe flag: true/false
- Лог: `AUTH_DEBUG_OVERLAY_ENABLED`

**Логи**:
- `AUTH_DEBUG_OVERLAY_ENABLED`

## 6. Email/Password улучшение

✅ **Реализовано**:
- Валидация email & password в UI
- Кнопка "Показать пароль"
- Авто-фокус на input при экране входа
- Лог: `AUTH_EMAIL_LOGIN:{result}`

**Логи**:
- `AUTH_EMAIL_LOGIN:success`
- `AUTH_EMAIL_LOGIN:error:{code}`

## 7. Смена пароля из настроек

✅ **Реализовано**:
- Экран "Сменить пароль"
- Требует текущий пароль + новый пароль
- Логи: `PASSWORD_CHANGE_OK` / `PASSWORD_CHANGE_ERR:{code}`

**Логи**:
- `PASSWORD_CHANGE_START`
- `PASSWORD_CHANGE_REAUTH_OK`
- `PASSWORD_CHANGE_OK`
- `PASSWORD_CHANGE_ERR:{code}`

## 8. Полное удаление аккаунта

✅ **Реализовано**:
- Новый пункт в Settings: "Удалить аккаунт"
- Подтверждение → удалить:
  1) Firebase Auth user
  2) Firestore user doc
  3) Storage uploads
  4) Все user subcollections (messages, prices, bookings, content)
- Лог: `ACCOUNT_DELETE_OK:{uid}`

**Логи**:
- `ACCOUNT_DELETE_START`
- `ACCOUNT_DELETE:AUTH_USER_DELETED`
- `ACCOUNT_DELETE:FIRESTORE_USER_DELETED`
- `ACCOUNT_DELETE:STORAGE_DELETED`
- `ACCOUNT_DELETE:SUBCOLLECTIONS_DELETED`
- `ACCOUNT_DELETE_OK:{uid}`

## 9. Fix: Race Condition (Firebase init vs UI)

✅ **Реализовано**:
- AuthGate ждёт:
  - `Firebase.initializeApp()`
  - `FirebaseAuth.instance.authStateChanges().first`
- Убраны любые `runApp()` до инициализации
- Лог: `AUTH_GATE_READY`

**Логи**:
- `AUTH_GATE:FIREBASE_INIT_OK`
- `AUTH_GATE:FIREBASE_ALREADY_INIT`
- `AUTH_GATE_READY`

## 10. Блокировка двойной регистрации (Google + Email)

✅ **Реализовано**:
- Если email уже существует → показывается сообщение: "Аккаунт с таким email уже существует. Войдите через Google или используйте пароль."
- Лог: `MERGE_ACCOUNT_DETECTED:{email}`

**Логи**:
- `MERGE_ACCOUNT_DETECTED:email={email}`

## 11. Fix чёрного экрана при запуске

✅ **Реализовано**:
- Splash отображается, пока:
  - ✅ Firebase init complete
  - ✅ Auth state received
- Добавлен таймер fallback 6 сек:
  - если init завис → повторить init + лог `SPLASH_INIT_TIMEOUT_RETRY`
- Если ошибка → показывается splash с индикатором загрузки вместо чёрного экрана
- Логи:
  - `SPLASH_START`
  - `SPLASH_READY`
  - `SPLASH_TIMEOUT:{firebaseInit}:{authResolved}`
  - `SPLASH_INIT_TIMEOUT_RETRY`

**Логи**:
- `SPLASH_START`
- `SPLASH: Firebase init ok`
- `SPLASH: Auth state resolved`
- `SPLASH_READY`
- `SPLASH_TIMEOUT:firebaseInit={bool}:authResolved={bool}`
- `SPLASH_INIT_TIMEOUT_RETRY`

## Сборка, установка, тест

✅ **Выполнено**:
- `flutter clean` ✅
- `flutter pub get` ✅
- `flutter build apk --release --no-tree-shake-icons` ✅
- APK установлен на устройство: `34HDU20228002261` ✅
- Логи собраны: `logs/LOG_v6_2_core_improvements.txt` ✅

**APK**:
- Путь: `build/app/outputs/flutter-apk/app-release.apk`
- Размер: 80.3MB
- Версия: 6.2.0+37

## Итоги

Все задачи из промпта выполнены:
1. ✅ Версионирование обновлено
2. ✅ Google Sign-In полный фикс с логами и авто-повтором
3. ✅ Обязательный онбординг после Google
4. ✅ Человеческие ошибки авторизации
5. ✅ Полный fresh install wipe
6. ✅ Auth debug overlay (секретное меню)
7. ✅ Email/password улучшения
8. ✅ Смена пароля из настроек
9. ✅ Полное удаление аккаунта
10. ✅ Fix race condition (Firebase init vs UI)
11. ✅ Блокировка двойной регистрации
12. ✅ Fix чёрного экрана при запуске
13. ✅ Сборка, установка и тест

## Файлы

- ✅ `app-release.apk` (80.3MB)
- ✅ `logs/LOG_v6_2_core_improvements.txt`
- ✅ `REPORT_v6_2_core_improvements.md`

