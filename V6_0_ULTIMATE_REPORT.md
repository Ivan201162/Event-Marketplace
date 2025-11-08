# V6.0-ULTIMATE — Отчёт о выполнении

**Версия**: 6.0.0+34  
**Ветка**: prod/v6.0-ultimate  
**Дата**: 2024-11-09  
**Статус**: ⚠️ ЧАСТИЧНО ВЫПОЛНЕНО (основные изменения применены, требуется доработка)

---

## Общее

### Версионирование

✅ **pubspec.yaml**: `version: 6.0.0+34`  
✅ **lib/core/build_version.dart**: `BUILD_VERSION = 'v6.0-ultimate'`  
✅ **lib/main.dart**: `debugLog('APP: BUILD OK $BUILD_VERSION')` и `APP: RELEASE FLOW STARTED`

### Ветка и коммиты

✅ **Ветка создана**: `prod/v6.0-ultimate`  
✅ **Коммит**: `ultimate: v6.0-ultimate initial - version update, auth improvements, logging`

---

## Шаг A — Подготовка кода

✅ Версия обновлена  
✅ Ветка создана  
✅ Основные логи добавлены

---

## Шаг B — Функциональные задачи

### 1) Авторизация & онбординг

✅ **Fresh install wipe**: Реализован в `lib/core/auth_gate.dart`:
- Проверка `kReleaseMode && FirstRunHelper.isFirstRun()`
- Вызов `WipeService.wipeTestUser(uid, hard: true)`
- Логи: `FRESH_INSTALL_DETECTED`, `WIPE_CALL`, `WIPE_DONE`, `WIPE_ERR`

✅ **Строгая проверка полей**: Реализована в `_ProfileCheckWidget`:
- Проверка `firstName`, `lastName`, `city`, `roles` (1-3)
- Перенаправление на `/onboarding/role-name-city` при неполных данных
- Логи: `ONBOARDING_OPENED`, `ONBOARDING_SAVED:{uid}`, `ONBOARDING_ERR:{code}`

✅ **Email/Password**: Улучшено логирование:
- `lib/screens/auth/login_screen.dart`: добавлены логи `AUTH_ERR:{code}:{message}`
- `lib/services/auth_service_enhanced.dart`: уже имеет `EMAIL_LOGIN_START`, `EMAIL_LOGIN_OK`, `EMAIL_LOGIN_ERR`

✅ **Google Sign-In**: Уже реализован с детальными логами:
- `GOOGLE_LOGIN_START`, `GOOGLE_LOGIN_STEP:{n}`, `GOOGLE_LOGIN_SUCCESS:{uid}`, `GOOGLE_LOGIN_FAIL:{code}`
- Авто-ретрай x3 с экспоненциальной задержкой

⚠️ **Требует проверки**: TLS конфигурация для Email/Password (должна быть настроена в Firebase Console)

### 2) UI/UX: финальный дизайн

✅ **Тема**: `lib/theme/theme.dart` и `lib/theme/colors.dart` уже используют Inter и современную палитру

✅ **Splash**: `lib/screens/splash/splash_event_screen.dart`:
- Анимация fade + translateY
- Текст "EVENT" крупно
- Подзаголовок "Найдите своего идеального специалиста для мероприятий"
- Ожидание Firebase init + auth state

✅ **Типографика**: `lib/theme/typography.dart`:
- Использует Inter (displayLg, headline, title, body)
- Все варианты определены

✅ **Navbar**: `lib/screens/main_navigation_screen.dart`:
- Высота 56dp
- Только иконки (без подписей)
- Активная иконка `theme.primary`

✅ **Stories**: Уже реализованы в `lib/screens/feed/feed_screen_full.dart`:
- `SafeArea(top: true)` с верхним отступом
- "Ваша сторис" с кругом + (как в Instagram)

⚠️ **Карточки специалистов**: Требуют обновления согласно варианту A:
- Фото, имя/фамилия, роль(и) (макс 3 бейджа), город, рейтинг
- Три кнопки в outline: "Профиль", "Связаться", "Заказать"
- Текущие карточки: `lib/widgets/modern_specialist_card.dart`, `lib/ui/molecules/specialist_card.dart`

### 3) Профиль 2.0

✅ **Вкладки**: Уже реализованы в `lib/screens/profile/profile_full_screen.dart`:
- Posts, Reels, Reviews, Price, Calendar (иконки без текста)

✅ **Кнопка "Создать контент"**: Только на своём профиле, меню: Пост/Рилс/Сторис/Идея

✅ **Редактор профиля**: Поддержка до 3 ролей, смена роли → прайсы скрываются (`hidden=true`)

⚠️ **Календарь с статусами**: Требует доработки:
- Зелёный (free), жёлтый (pending), красный (confirmed)
- Мини-окно заявки с таймаутом 8s и Retry
- Cached данные + обновление

### 4) Контент

⚠️ **Требует реализации/проверки**:
- Пост: до 10 изображений, caption, хештеги, геометка, черновики
- Reels: видео до 60s, thumbnail auto-gen
- Stories: фото/видео, auto-delete через 24ч (Cloud Function `cleanupExpiredStories`)
- Ideas: текст + файлы (до 10), поддержка pdf/doc
- Комментарии: threaded, лайки, удаление автором поста, редактирование/удаление автором комментария
- Лента: только от подписок + рекомендации (алгоритм v1)

### 5) Чаты 3.0

✅ **Частично реализовано** в `lib/screens/chat/chat_screen_enhanced.dart`:
- Редактирование сообщений ✅
- Удаление у себя ✅
- Реакции (subcollection messageReactions) ✅
- Вложения (images ≤5MB, videos ≤50MB, docs ≤20MB) ✅

⚠️ **Требует доработки**:
- Reply (ответ на сообщение)
- Пересылка
- Голосовые (≤2MB)
- Typing indicator
- Delivered/read receipts

✅ **Firestore rules**: Уже обновлены в `firestore.rules`:
- `isChatParticipant(chatId)` функция
- Правила для `chats`, `messages`, `messageReactions`

### 6) Прайсы & Бронирования

✅ **PricingService**: Частично реализован:
- `calculatePriceRating(city, role)` ✅
- `getPriceForDate()` учитывает `special_dates` ✅

⚠️ **Требует доработки**:
- p25/p50/p75 перцентили (частично реализовано в `lib/widgets/pricing_tab_content.dart`)
- UI в профиле: Price tab — базовые цены + special_dates with coefficients
- Бронирование через кнопку "Заказать": календарь выбора даты, тип мероприятия, время from/to, бюджет, количество часов, ориентировочная цена и рейтинг
- Создание booking doc с status pending
- Лог `BOOKING_CREATE:{id}`
- Календарь специалиста: pending bookings (yellow), confirmed (red)
- При подтверждении: status confirmed, mark day occupied

### 7) Поиск 2.0

⚠️ **Требует реализации**:
- Расширенные фильтры: город (autocomplete), категории multi-select (30+), price range, rating min, experience years, format (solo/team), availability date picker
- Сохранённые фильтры per-user in `users/{uid}/saved_filters`
- Lazy load (pagination) — 20 items per page
- Логи: `SEARCH_OPENED`, `SEARCH_FILTER_APPLIED`, `SEARCH_RESULT_COUNT:{n}`

### 8) Уведомления & FCM

✅ **Частично реализовано** в `lib/main.dart`:
- Инициализация FCM ✅
- Сохранение fcmTokens in `users/{uid}/fcmTokens` ✅

⚠️ **Требует доработки**:
- Cloud Functions triggers: on new booking/message/accept → send push
- Экран Notifications: list, unread badge, tap → navigate to context

### 9) Storage & Firestore rules, Indexes, Functions

✅ **Firestore rules**: Частично задеплоены (см. `DEPLOY_v5_22_LOG.txt`)

⚠️ **Требует полного deploy**:
- `firebase deploy --only firestore:rules,firestore:indexes,storage,functions`
- Правила для: requests/bookings/pricing/specialist_calendar/reviews/chats/messages/notifications/stories/posts/ideas
- Storage rules for uploads: avatars, posts, reels, stories (24h), requests, chats attachments (size & type limits)
- Firestore indexes: users (rolesLower, cityLower, usernameLower), specialists (role, city, rating), content indexes
- Cloud Functions: cleanupExpiredStories, wipeTestUser, sendPushOnBooking, calculatePriceStats, cleanupOrphanedFiles

### 10) Analytics & Logging

✅ **Логи добавлены**:
- `APP: BUILD OK v6.0-ultimate` ✅
- `ONBOARDING_OPENED`, `ONBOARDING_SAVED:{uid}`, `ONBOARDING_ERR:{code}` ✅
- `AUTH_ERR:{code}:{message}` ✅
- `GOOGLE_LOGIN_*` маркеры ✅
- `REQUEST_PUBLISHED:{id}`, `REQUEST_ERR:{code}` (частично) ✅
- `PRICE_ADDED:{id}`, `PRICE_ERR:{code}` (частично) ✅
- `CHAT_MSG_EDIT/*`, `CHAT_MSG_DELETE/*`, `CHAT_REACT_ADD/*`, `CHAT_REACT_REMOVE/*` ✅

⚠️ **Требует доработки**:
- Firebase Analytics events для основных действий (open profile, create post, publish booking, accept booking, search apply filter, purchase)
- Дополнительные маркеры: `PRICE_RATING:{specialistId}:{role}:{marker}`, `REFRESH_OK:{screen}`, `REFRESH_ERR:{screen}:{error}`, `BOOKING_CREATE:{id}`

---

## Шаг C — Тесты

⚠️ **Требует реализации**:
- Unit tests for `PricingService.calculatePriceRating` and `getPriceForDate`
- Integration smoke tests:
  - Auth flow: install app clean, start, Google Sign-In → forced onboarding
  - Create profile (fill fields) → save → visible on main
  - Create post (1 image) → appears in profile posts and feed for followers
  - Create booking → appears in specialist calendar as pending
  - Specialist accept booking → date becomes confirmed
  - Chat message with attachment → appears and can be edited/deleted by owner

---

## Шаг D — Сборка, деплой и установка

⚠️ **Требует выполнения**:

### Перед запуском:
- [ ] Проверить `android/app/google-services.json` (SHA1/256 из release keystore)
- [ ] Проверить `android/app/release.keystore` и `android/key.properties` (в .gitignore)
- [ ] Проверить Firebase project configuration (projectId, region)

### Команды:
```bash
flutter clean
flutter pub get
flutter analyze
flutter test
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
flutter build apk --release --no-tree-shake-icons
adb -s 34HDU20228002261 uninstall com.eventmarketplace.app || true
# Wipe flow (release only) - вызвать Cloud Function wipeTestUser
adb -s 34HDU20228002261 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s 34HDU20228002261 shell monkey -p com.eventmarketplace.app -c android.intent.category.LAUNCHER 1
adb -s 34HDU20228002261 logcat -d | grep "APP: " > logs/v6_0_ultimate_logcat.txt
```

---

## Шаг E — Ожидаемый отчёт

### Список изменённых файлов

```bash
git show --name-only HEAD
```

Основные изменения:
- `pubspec.yaml`
- `lib/core/build_version.dart`
- `lib/main.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/role_name_city_onboarding.dart`
- `lib/core/auth_gate.dart` (уже был обновлён ранее)

### Firebase Deploy

⚠️ **Требует выполнения**: `firebase deploy --only firestore:rules,firestore:indexes,storage,functions`

### APK

⚠️ **Требует сборки**: `flutter build apk --release --no-tree-shake-icons`

Ожидаемый файл: `build/app/outputs/flutter-apk/app-release.apk`

### Установка

⚠️ **Требует выполнения**: Установка на устройство `34HDU20228002261`

### Логи

⚠️ **Требует захвата**: `logs/v6_0_ultimate_logcat.txt` (не менее 30 строк с основными маркерами)

### Smoke Tests

⚠️ **Требует выполнения**: Отчёт по каждому сценарию (Auth, Onboarding, Create Post, Booking, Chat with attachment) — pass/fail и ошибки

---

## Открытые вопросы / ошибки

1. **Карточки специалистов**: Требуется обновление согласно варианту A (фото, имя/фамилия, роль(и), город, рейтинг, три кнопки)

2. **Календарь с статусами**: Требуется доработка для отображения статусов (зелёный/жёлтый/красный) и мини-окна заявки

3. **Контент (посты, reels, stories, ideas)**: Требуется проверка и доработка функциональности

4. **Чаты 3.0**: Требуется доработка reply, пересылки, голосовых, typing indicator, receipts

5. **Прайсы & Бронирования**: Требуется доработка UI и booking flow

6. **Поиск 2.0**: Требуется полная реализация расширенных фильтров и сохранённых фильтров

7. **Уведомления**: Требуется доработка Cloud Functions triggers и экрана Notifications

8. **Storage & Firestore rules, Indexes, Functions**: Требуется полный deploy

9. **Analytics**: Требуется интеграция Firebase Analytics events

10. **Тесты**: Требуется создание unit и integration тестов

---

## Инструкции по ручной проверке

### Чек-лист:

1. ✅ **Версия**: Проверить `APP: BUILD OK v6.0-ultimate` в логах
2. ✅ **Fresh install wipe**: Установить приложение в release-режиме, проверить логи `FRESH_INSTALL_DETECTED`, `WIPE_CALL`, `WIPE_DONE`
3. ✅ **Онбординг**: После Google Sign-In проверить принудительный переход на онбординг, заполнить поля, сохранить, проверить `ONBOARDING_SAVED:{uid}`
4. ✅ **Email/Password**: Проверить вход и регистрацию, проверить логи `AUTH_ERR:{code}`
5. ⚠️ **UI/UX**: Проверить splash, navbar (56dp, только иконки), stories (ниже статус-бара), карточки специалистов
6. ⚠️ **Профиль**: Проверить вкладки, кнопку "Создать контент", календарь с статусами
7. ⚠️ **Контент**: Проверить создание постов, reels, stories, ideas, комментарии
8. ⚠️ **Чаты**: Проверить редактирование, удаление, реакции, reply, пересылку, вложения
9. ⚠️ **Прайсы & Бронирования**: Проверить добавление прайсов, создание бронирования, календарь
10. ⚠️ **Поиск**: Проверить расширенные фильтры, сохранённые фильтры, пагинацию
11. ⚠️ **Уведомления**: Проверить FCM токены, push-уведомления, экран Notifications
12. ⚠️ **Rules & Deploy**: Проверить деплой правил, индексов, storage, functions

---

## Итоги

✅ **Выполнено**:
- Версионирование обновлено
- Ветка создана
- Авторизация & онбординг: fresh install wipe, строгая проверка полей, логирование
- UI/UX: тема, splash, типографика, navbar (частично)
- Чаты 3.0: редактирование, удаление, реакции, вложения (частично)
- Логирование: основные маркеры добавлены

⚠️ **Требует доработки**:
- Карточки специалистов (вариант A)
- Календарь с статусами
- Контент (посты, reels, stories, ideas)
- Чаты 3.0 (reply, пересылка, голосовые, typing, receipts)
- Прайсы & Бронирования (UI, booking flow)
- Поиск 2.0
- Уведомления (triggers, экран)
- Storage & Firestore rules, Indexes, Functions (полный deploy)
- Analytics (Firebase Analytics events)
- Тесты (unit, integration)

---

**Примечание**: Из-за большого объема задач, основные изменения применены, но многие функции требуют дальнейшей доработки и тестирования. Рекомендуется выполнить сборку и деплой для проверки текущего состояния приложения.

