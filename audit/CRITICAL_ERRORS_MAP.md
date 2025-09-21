# CRITICAL_ERRORS_MAP.md
## Полная карта критических ошибок Event Marketplace App

**Дата анализа:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Статус:** 🔴 КРИТИЧЕСКИЕ ОШИБКИ БЛОКИРУЮТ ЗАПУСК ПРИЛОЖЕНИЯ

---

## 🔴 БЛОКИРУЮЩИЕ ОШИБКИ (Компиляция невозможна)

### 1. Отсутствующие типы и классы
- **UserRole** - тип не найден в `lib/services/user_management_service.dart`
- **Chat** - тип не найден в `lib/services/chat_service.dart`
- **NotificationChannel** - геттер не определен в `BookingService`
- **ScheduleEventType.available** - член не найден в `lib/models/specialist_schedule.dart`

### 2. Дублирование объявлений
- **`_isMonitoring`** - уже объявлен в области видимости в `lib/services/monitoring_service.dart:33`

### 3. Несовместимость типов (UserRole конфликты)
- **UserRole/*1*/ vs UserRole/*2*/** - конфликт между `models/security.dart` и `models/user.dart`
- **MaritalStatus/*1*/ vs MaritalStatus/*2*/** - конфликт между `models/user.dart` и `models/customer_profile.dart`
- **NotificationType/*1*/ vs NotificationType/*2*/** - конфликт между `models/notification.dart` и `models/notification_type.dart`

### 4. Отсутствующие обязательные параметры
- **`earnedBadges`** - обязательный параметр в `BadgeStats` конструкторе
- **`targetId`** - обязательный параметр в `Review.fromMap`
- **`channel`** - обязательный параметр в `sendNotification`
- **`customerId`** - обязательный параметр в `sendReviewNotification`
- **`prefs`** - обязательный параметр в тестах интеграции

### 5. Неопределенные методы и геттеры
- **`hasPermission`** - метод не определен для типа `UserRole`
- **`displayName`** - геттер не определен для типа `UserRole`
- **`notificationId`** - геттер не определен для типа `NotificationService`
- **`posts`** - геттер не определен в `_SpecialistProfileScreenState`
- **`albums`** - геттер не определен в `_SpecialistProfileScreenState`
- **`l10n`** - геттер не определен в `SettingsPage`
- **`ref`** - геттер не определен в `SettingsPage`

### 6. Несовместимость типов данных
- **Stream vs Future** - `Stream<List<Event>>` не может быть возвращен из async функции с типом `Future<List<Event>>`
- **String vs NotificationType** - `String` не может быть присвоен параметру типа `NotificationType`
- **String vs ChatMessage** - `String` не может быть присвоен параметру типа `ChatMessage`
- **String? vs String** - `String?` не может быть присвоен параметру типа `String`
- **double vs int** - множественные ошибки несовместимости типов в аналитических сервисах

### 7. Синтаксические ошибки
- **Expected identifier, but got 'this'** - в `lib/models/user_management.dart` (строки 572, 591, 610, 629)
- **Can't assign to this** - в `lib/services/monitoring_service.dart` (строки 964, 969)

### 8. Отсутствующие члены Firebase/Flutter
- **`FirebaseMessaging.getInitialMessage`** - метод не найден
- **`NotificationType.cancellation`** - член не найден
- **`TargetPlatform.web`** - член не найден
- **`BadgeStats.empty()`** - метод не найден

### 9. Ошибки в тестах
- **`ResponsiveWidget`** - функция не определена в `test/widgets_test.dart`
- **`ResponsiveList`** - функция не определена в `test/widgets_test.dart`
- **Invalid constant value** - множественные ошибки в тестах

### 10. Ошибки сборки платформ
- **Android NDK** - поврежденная загрузка NDK в `C:\Android\ndk\27.0.12077973`
- **Flex Color Scheme** - несовместимость версий с Flutter 3.35.3

---

## 🟠 ВЫСОКИЕ ПРИОРИТЕТЫ (Ломают ключевые функции)

### 1. Riverpod Provider конфликты
- **StreamProvider vs ProviderListenable** - несовместимость типов в `favorites_page.dart`
- **FutureProviderFamily** - несовместимость с `ProviderListenable` в `recommendations_section.dart`

### 2. Локализация
- **AppLocalizations** - отсутствующие геттеры `l10n` в экранах

### 3. Аналитика и мониторинг
- **Performance Service** - множественные ошибки типов и отсутствующие сеттеры
- **Analytics Service** - отсутствующие платформы

---

## 📊 СТАТИСТИКА ОШИБОК

- **Всего ошибок:** 7073 (из flutter analyze)
- **Критических ошибок:** ~150+
- **Блокирующих компиляцию:** ~80+
- **Ошибок сборки:** 3 платформы (Android, Web, Windows)

---

## 🎯 ПЛАН ИСПРАВЛЕНИЯ

1. **Этап 1:** Исправить дублирование объявлений и синтаксические ошибки
2. **Этап 2:** Устранить конфликты типов (UserRole, MaritalStatus, NotificationType)
3. **Этап 3:** Добавить отсутствующие обязательные параметры
4. **Этап 4:** Исправить неопределенные методы и геттеры
5. **Этап 5:** Устранить несовместимость типов данных
6. **Этап 6:** Исправить ошибки сборки платформ
7. **Этап 7:** Обновить тесты и интеграционные тесты

---

## ⚠️ КРИТИЧЕСКИЕ ЗАВИСИМОСТИ

- **Flutter SDK:** 3.35.3
- **Dart SDK:** 3.9.2
- **Flex Color Scheme:** 7.3.1 (требует обновления)
- **Riverpod:** 2.6.1 (требует обновления)
- **Firebase:** множественные пакеты требуют обновления

---

**ВЫВОД:** Приложение не может быть скомпилировано и запущено на любой платформе из-за множественных критических ошибок типов, отсутствующих классов и несовместимости зависимостей.
