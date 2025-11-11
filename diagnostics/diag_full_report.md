# Полный диагностический отчёт — V6.DIAG-AUTO-REPORT

**Дата:** 2025-11-11  
**Версия приложения:** 6.3.0+45  
**Последний рабочий релиз:** v6.0-ultimate (коммит fdc839ae)  
**Текущий HEAD:** 2463a8e6 (prod/v6.1-next)

---

## Executive Summary

**Критическая проблема:** Дубликат зависимости `google_sign_in` в `pubspec.yaml` (строки 25 и 53) блокирует выполнение `flutter pub get` и сборку проекта.

**Симптомы:**
- Белый/чёрный экран при запуске
- Невозможность входа через Google (firebase_auth/unknown)
- Ошибка YAML парсинга: "Duplicate mapping key" при попытке `flutter pub get`

**Основная причина (гипотеза #1):**
Дубликат `google_sign_in` в `pubspec.yaml` приводит к ошибке парсинга YAML, что делает невозможной установку зависимостей и сборку проекта. Это блокирует все последующие операции.

**Вторичные проблемы:**
- Устройство 34HDU20228002261 находится в состоянии "offline" (недоступно для сбора логов)
- Множественные реализации AuthGate (lib/core/auth_gate.dart и lib/widgets/auth_gate.dart)
- Изменения в main.dart по сравнению с v6.0-ultimate (упрощение инициализации, таймауты)

---

## Symptoms

### Что видим:
1. **Белый/чёрный экран:** Приложение не запускается или зависает на экране загрузки
2. **Ошибка сборки:** `flutter pub get` падает с ошибкой "Duplicate mapping key" для `google_sign_in`
3. **Google Sign-In не работает:** Ошибки `firebase_auth/unknown` или `network-request-failed`
4. **Устройство офлайн:** ADB показывает устройство как "offline", логи недоступны

### Ожидаемое поведение (v6.0-ultimate):
- Приложение запускается, показывает SplashScreen
- Firebase инициализируется успешно
- AuthGate проверяет состояние авторизации
- Google Sign-In работает корректно

---

## Environment

### Версии SDK/Flutter/Gradle

**Flutter:** >=3.22.0  
**Dart SDK:** >=3.3.0 <4.0.0  
**Версия приложения:** 6.3.0+45 (текущая) vs 6.0.0+34 (v6.0-ultimate)

**Gradle:**
- Google Services: 4.4.2
- Firebase BOM: 33.3.0
- Play Services Auth: 21.2.0 (было 21.1.1 в v6.0-ultimate)
- MultiDex: 2.0.1

**Android:**
- applicationId: `com.eventmarketplace.app`
- package_name: `com.eventmarketplace.app` (совпадает ✅)
- minSdk: flutter.minSdkVersion
- targetSdk: flutter.targetSdkVersion
- multiDexEnabled: true

**Firebase:**
- project_id: `event-marketplace-mvp`
- mobilesdk_app_id: `1:272201705683:android:0196de78aaeb970ef80c26`
- apiKey: `AIzaSyCdDRPCyCHEJy7WBr5eQrcyuRhh_hSfih4`

**SHA-1 Certificate:**
- Hash: `a2179ae3c52226d72edbf194e5f9e280b8e3b9fd`
- ⚠️ Требуется валидация на Firebase Console

---

## Project Diff vs Last Working (v6.0-ultimate)

### Ключевые изменения с коммита fdc839ae (v6.0-ultimate):

#### 1. `pubspec.yaml`
**Статус:** ❌ **FAIL** — дубликат `google_sign_in`
- Строка 25: `google_sign_in: ^6.2.1`
- Строка 53: `google_sign_in: ^6.2.1` (дубликат!)

#### 2. `lib/main.dart`
**Изменения:**
- Удалена инициализация Bootstrap
- Добавлен таймаут 8 сек для Firebase.initializeApp
- Упрощена структура (удалены логи FCM, Firestore persistence)
- Изменён AppRoot (теперь принимает `firebaseReady: bool`)
- Добавлен WipeService.maybeWipeOnFirstRun()

**Код v6.0-ultimate:**
```dart
await Bootstrap.initialize().timeout(Duration(seconds: 10));
// FCM инициализация
// Firestore persistence
runApp(const ProviderScope(child: EventMarketplaceApp()));
```

**Код текущий:**
```dart
await Future.any([
  Firebase.initializeApp(...),
  Future.delayed(const Duration(seconds: 8)),
]);
runApp(AppRoot(firebaseReady: firebaseReady));
```

#### 3. `lib/core/auth_gate.dart`
**Изменения:**
- Преобразован из `StatefulWidget` в `StatelessWidget`
- Удалена логика `_checkFreshInstall()` и `FirstRunHelper`
- Упрощена проверка профиля (теперь только `_ensureProfileAndRoute()`)
- Изменена навигация (теперь через GoRouter вместо прямого context.go)

#### 4. `android/app/build.gradle.kts`
**Изменения:**
- Добавлен `multiDexEnabled = true`
- Добавлен `manifestPlaceholders["appAuthRedirectScheme"]`
- Обновлена версия Play Services Auth: 21.1.1 → 21.2.0
- Улучшена проверка google-services.json (проверка package_name и client_info)

#### 5. `android/app/src/main/AndroidManifest.xml`
**Статус:** ✅ Без изменений (INTERNET permission присутствует)

---

## Firebase/Google Config Checks

### ✅ OK — Конфигурация корректна

1. **google-services.json:**
   - ✅ Файл существует: `android/app/google-services.json`
   - ✅ package_name совпадает: `com.eventmarketplace.app`
   - ✅ mobilesdk_app_id присутствует: `1:272201705683:android:0196de78aaeb970ef80c26`
   - ✅ oauth_client блоки присутствуют (client_type 1 и 3)
   - ✅ certificate_hash: `a2179ae3c52226d72edbf194e5f9e280b8e3b9fd`

2. **applicationId vs package_name:**
   - ✅ Совпадают: `com.eventmarketplace.app`

3. **Internet Permission:**
   - ✅ Присутствует в AndroidManifest.xml

4. **Gradle плагины:**
   - ✅ `com.google.gms.google-services` подключен
   - ✅ Версии: firebase_core ^3.6.0, firebase_auth ^5.3.1, google_sign_in ^6.2.1

5. **Proguard Rules:**
   - ✅ Google Sign-In классы защищены
   - ✅ Firebase классы защищены

### ⚠️ WARNING — Требует проверки

1. **SHA-1 Certificate:**
   - ⚠️ Невозможно проверить онлайн — требуется валидация на Firebase Console
   - Если SHA-1 не совпадает → DEVELOPER_ERROR при Google Sign-In

2. **Google Play Services:**
   - ⚠️ Недоступно проверить без устройства (устройство offline)

### ❌ FAIL — Критические проблемы

1. **pubspec.yaml:**
   - ❌ Дубликат `google_sign_in` (строки 25 и 53)
   - ❌ Блокирует `flutter pub get` и сборку

---

## Runtime Logs Analysis

### Ограничения:
- ⚠️ Устройство 34HDU20228002261 находится в состоянии "offline"
- ⚠️ Логи с устройства недоступны
- ⚠️ Анализ выполнен на основе кода и конфигурации

### Ожидаемые логи (на основе кода):

**При успешном запуске (v6.0-ultimate):**
```
APP: BUILD OK v6.0-ultimate
APP: RELEASE FLOW STARTED
APP_VERSION:6.0.0+34
SESSION_START
GOOGLE_INIT:[DEFAULT]
GOOGLE_JSON_CHECK:found
```

**При текущем запуске (ожидаемые):**
```
APP: BUILD OK v6.3-ultimate-restore
APP_VERSION:6.3.0+45
SPLASH:init-start
SPLASH:init-done (или SPLASH_INIT_ERR при таймауте)
GOOGLE_JSON_CHECK:found
```

**При ошибке Google Sign-In:**
```
GOOGLE_SIGNIN_START
GOOGLE_SIGNIN_ERROR:unknown:...
GOOGLE_FIREBASE_AUTH_ERROR:...
```

### Потенциальные ошибки в логах:

1. **YAML Parse Error:**
   ```
   Error on line 53, column 3: Duplicate mapping key.
   ```

2. **Firebase Init Timeout:**
   ```
   SPLASH_INIT_ERR:Firebase not initialized after timeout
   ```

3. **Google Sign-In Errors:**
   - `DEVELOPER_ERROR` → SHA-1 mismatch
   - `network-request-failed` → Проблемы с сетью или конфигурацией
   - `unknown` → Общая ошибка, требует детального лога

---

## Root Cause Analysis

### Гипотеза #1: Дубликат google_sign_in (ВЫСОКАЯ ВЕРОЯТНОСТЬ) ⭐

**Проблема:** Дубликат `google_sign_in: ^6.2.1` в `pubspec.yaml` (строки 25 и 53)

**Последствия:**
1. `flutter pub get` падает с ошибкой "Duplicate mapping key"
2. Зависимости не устанавливаются
3. Проект не собирается
4. Приложение не может запуститься

**Доказательства:**
- Ошибка при выполнении `flutter doctor` и `flutter pub deps`
- YAML парсер не может обработать дубликат ключа

**Вероятность:** 95%

---

### Гипотеза #2: Изменения в инициализации Firebase (СРЕДНЯЯ ВЕРОЯТНОСТЬ)

**Проблема:** Упрощение инициализации Firebase в `main.dart` с таймаутом 8 сек

**Последствия:**
1. Firebase может не успеть инициализироваться за 8 секунд
2. `firebaseReady = false` → AppRoot показывает SplashScreen с retry
3. AuthGate не может проверить состояние авторизации

**Доказательства:**
- В v6.0-ultimate использовался `Bootstrap.initialize()` с таймаутом 10 сек
- В текущей версии используется `Future.any` с таймаутом 8 сек
- Удалена проверка `Firebase.app()` перед инициализацией

**Вероятность:** 60%

---

### Гипотеза #3: SHA-1 Certificate Mismatch (НИЗКАЯ ВЕРОЯТНОСТЬ)

**Проблема:** SHA-1 сертификат в google-services.json не совпадает с подписью APK

**Последствия:**
1. Google Sign-In возвращает `DEVELOPER_ERROR`
2. Firebase Auth не может аутентифицировать пользователя

**Доказательства:**
- SHA-1 в google-services.json: `a2179ae3c52226d72edbf194e5f9e280b8e3b9fd`
- Невозможно проверить без доступа к устройству и keystore

**Вероятность:** 30%

---

## Minimal Fix Plan (MFP)

### Шаг 1: Исправить дубликат google_sign_in (КРИТИЧНО)

**Файл:** `pubspec.yaml`

**Действие:**
1. Удалить дубликат `google_sign_in: ^6.2.1` со строки 53
2. Оставить только одно вхождение на строке 25

**Код до:**
```yaml
  firebase_auth: ^5.3.1
  google_sign_in: ^6.2.1  # строка 25
  cloud_firestore: ^5.4.4
  ...
  google_fonts: ^6.1.0
  google_sign_in: ^6.2.1  # строка 53 - УДАЛИТЬ
  hive_flutter: ^1.1.0
```

**Код после:**
```yaml
  firebase_auth: ^5.3.1
  google_sign_in: ^6.2.1  # строка 25 - ОСТАВИТЬ
  cloud_firestore: ^5.4.4
  ...
  google_fonts: ^6.1.0
  # google_sign_in удалён (дубликат)
  hive_flutter: ^1.1.0
```

**Проверка:**
```bash
flutter pub get  # должен выполниться без ошибок
```

---

### Шаг 2: Восстановить проверку Firebase инициализации

**Файл:** `lib/main.dart`

**Действие:**
Добавить проверку `Firebase.app()` перед инициализацией (как в v6.0-ultimate)

**Код до:**
```dart
bool firebaseReady = false;
try {
  await Future.any([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    Future.delayed(const Duration(seconds: 8)),
  ]);
  try {
    Firebase.app();
    firebaseReady = true;
  } catch (_) {
    debugPrint('SPLASH_INIT_ERR:Firebase not initialized after timeout');
  }
} catch (e, st) {
  debugPrint('SPLASH_INIT_ERR:$e\n$st');
}
```

**Код после:**
```dart
bool firebaseReady = false;
try {
  // Проверка, не инициализирован ли уже Firebase
  try {
    Firebase.app();
    firebaseReady = true;
    debugPrint('SPLASH:init-already-done');
  } catch (_) {
    // Инициализация Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Firebase.app(); // Проверка успешности
    firebaseReady = true;
    debugPrint('SPLASH:init-done');
  }
} catch (e, st) {
  debugPrint('🔥 Firebase init failed: $e\n$st');
  firebaseReady = false;
}
```

**Проверка:**
- Логи должны содержать `SPLASH:init-done` или `SPLASH:init-already-done`
- `firebaseReady` должен быть `true` при успешной инициализации

---

### Шаг 3: Увеличить таймаут Firebase инициализации (опционально)

**Файл:** `lib/main.dart`

**Действие:**
Если шаг 2 не помогает, добавить таймаут 10 секунд (как в v6.0-ultimate)

**Код:**
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
).timeout(
  const Duration(seconds: 10),
  onTimeout: () {
    debugPrint('SPLASH_INIT_TIMEOUT:Firebase init exceeded 10 seconds');
    throw TimeoutException('Firebase initialization timeout');
  },
);
```

---

### Шаг 4: Проверить SHA-1 сертификат (если Google Sign-In не работает)

**Действие:**
1. Получить SHA-1 из keystore:
   ```bash
   keytool -list -v -keystore android/app/key.properties -alias <keyAlias>
   ```
2. Сравнить с SHA-1 в `google-services.json`: `a2179ae3c52226d72edbf194e5f9e280b8e3b9fd`
3. Если не совпадает:
   - Добавить правильный SHA-1 в Firebase Console → Project Settings → Your apps → Android app
   - Скачать обновлённый `google-services.json`

---

## Safety Rollback Plan

### Откат к v6.0-ultimate (1 команда)

```bash
git checkout fdc839ae
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

**Проверка:**
- Приложение должно запуститься
- Google Sign-In должен работать
- Логи должны содержать `APP: BUILD OK v6.0-ultimate`

---

## Post-Fix Validation

### Чек-лист проверки после исправления:

1. **Сборка проекта:**
   - [ ] `flutter pub get` выполняется без ошибок
   - [ ] `flutter build apk --release` успешно собирает APK
   - [ ] APK устанавливается на устройство 34HDU20228002261

2. **Запуск приложения:**
   - [ ] Приложение запускается без белого/чёрного экрана
   - [ ] SplashScreen отображается
   - [ ] Логи содержат `SPLASH:init-done` или `SPLASH:init-already-done`
   - [ ] `firebaseReady = true` в логах

3. **Авторизация:**
   - [ ] AuthGate корректно проверяет состояние авторизации
   - [ ] При отсутствии пользователя → переход на `/login`
   - [ ] При наличии пользователя → проверка профиля

4. **Google Sign-In:**
   - [ ] Кнопка "Войти через Google" работает
   - [ ] Логи содержат `GOOGLE_SIGNIN_START`
   - [ ] Логи содержат `GOOGLE_SIGNIN_SUCCESS` или `GOOGLE_FIREBASE_AUTH_SUCCESS`
   - [ ] Нет ошибок `DEVELOPER_ERROR` или `unknown`

5. **Email/Password:**
   - [ ] Вход по email/password работает
   - [ ] Регистрация работает

6. **Навигация:**
   - [ ] После успешного входа → переход на `/main` или `/onboarding`
   - [ ] Нет зависаний на SplashScreen

---

## Appendix

### Ссылки на артефакты:

1. **Логи:**
   - `diagnostics/logcat_launch.txt` — лог запуска (недоступен, устройство offline)
   - `diagnostics/logcat_auth_flow.txt` — лог авторизации (недоступен, устройство offline)
   - `diagnostics/build_release_log.txt` — лог сборки (недоступен, сборка не выполнена)

2. **Git:**
   - `diagnostics/git_history.txt` — история коммитов (200 последних)
   - `diagnostics/git_diff_working_vs_current.patch` — дифф v6.0-ultimate → текущий HEAD

3. **Метаданные:**
   - `diagnostics/files_snapshot.txt` — список ключевых файлов и их статусы
   - `diagnostics/env_summary.txt` — сводка окружения
   - `diagnostics/flutter_doctor.txt` — вывод flutter doctor (недоступен из-за ошибки YAML)
   - `diagnostics/flutter_pub_deps.txt` — зависимости (недоступен из-за ошибки YAML)
   - `diagnostics/flutter_analyze.txt` — анализ кода (недоступен из-за ошибки YAML)

4. **Конфигурация:**
   - `pubspec.yaml` — зависимости (с дубликатом google_sign_in)
   - `android/app/build.gradle.kts` — конфигурация сборки Android
   - `android/app/google-services.json` — конфигурация Firebase
   - `android/app/src/main/AndroidManifest.xml` — манифест Android

### Ограничения диагностики:

1. ⚠️ Устройство 34HDU20228002261 находится в состоянии "offline"
2. ⚠️ Логи с устройства недоступны
3. ⚠️ Сборка проекта невозможна из-за ошибки YAML
4. ⚠️ `flutter doctor` и `flutter pub deps` не могут выполниться из-за ошибки YAML

### Рекомендации:

1. **Немедленно:** Исправить дубликат `google_sign_in` в `pubspec.yaml`
2. **После исправления:** Выполнить `flutter pub get` и проверить сборку
3. **При проблемах с Google Sign-In:** Проверить SHA-1 сертификат на Firebase Console
4. **При проблемах с запуском:** Восстановить проверку Firebase инициализации (шаг 2 MFP)

---

**Конец отчёта**

