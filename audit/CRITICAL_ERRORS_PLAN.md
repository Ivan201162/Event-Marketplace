# CRITICAL_ERRORS_PLAN.md
## План исправления критических ошибок по категориям

**Дата создания:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Статус:** 📋 ПЛАН ГОТОВ К ВЫПОЛНЕНИЮ

---

## 🎯 КАТЕГОРИИ ОШИБОК ДЛЯ ПОСЛЕДОВАТЕЛЬНОГО ИСПРАВЛЕНИЯ

### КАТЕГОРИЯ 1: 🔧 Дублирование объявлений и синтаксические ошибки
**Приоритет:** 🔴 КРИТИЧЕСКИЙ  
**Файлы:** 
- `lib/services/monitoring_service.dart`
- `lib/models/user_management.dart`

**Ошибки:**
- `_isMonitoring` уже объявлен в области видимости
- Expected identifier, but got 'this' (строки 572, 591, 610, 629)
- Can't assign to this (строки 964, 969)

**Действия:**
1. Удалить дублирующее объявление `_isMonitoring`
2. Исправить синтаксис switch statements в user_management.dart
3. Исправить присваивания в monitoring_service.dart

---

### КАТЕГОРИЯ 2: 🔄 Конфликты типов (UserRole, MaritalStatus, NotificationType)
**Приоритет:** 🔴 КРИТИЧЕСКИЙ  
**Файлы:**
- `lib/models/security.dart` vs `lib/models/user.dart`
- `lib/models/customer_profile.dart` vs `lib/models/user.dart`
- `lib/models/notification.dart` vs `lib/models/notification_type.dart`

**Ошибки:**
- UserRole/*1*/ vs UserRole/*2*/ конфликты
- MaritalStatus/*1*/ vs MaritalStatus/*2*/ конфликты
- NotificationType/*1*/ vs NotificationType/*2*/ конфликты

**Действия:**
1. Унифицировать определения UserRole в одном файле
2. Унифицировать определения MaritalStatus в одном файле
3. Унифицировать определения NotificationType в одном файле
4. Обновить все импорты для использования единого источника

---

### КАТЕГОРИЯ 3: 📝 Отсутствующие обязательные параметры
**Приоритет:** 🔴 КРИТИЧЕСКИЙ  
**Файлы:**
- `lib/models/badge.dart`
- `lib/models/review.dart`
- `lib/services/booking_service.dart`
- `lib/providers/notification_providers.dart`
- `test/integration/` (все файлы)

**Ошибки:**
- `earnedBadges` - обязательный параметр в BadgeStats
- `targetId` - обязательный параметр в Review.fromMap
- `channel` - обязательный параметр в sendNotification
- `customerId` - обязательный параметр в sendReviewNotification
- `prefs` - обязательный параметр в тестах

**Действия:**
1. Добавить отсутствующие параметры в конструкторы
2. Обновить вызовы методов с обязательными параметрами
3. Исправить тесты интеграции

---

### КАТЕГОРИЯ 4: 🔍 Неопределенные методы и геттеры
**Приоритет:** 🔴 КРИТИЧЕСКИЙ  
**Файлы:**
- `lib/models/user_management.dart`
- `lib/screens/settings_page.dart`
- `lib/screens/specialist_profile_screen.dart`
- `lib/services/notification_service.dart`

**Ошибки:**
- `hasPermission` - метод не определен для UserRole
- `displayName` - геттер не определен для UserRole
- `notificationId` - геттер не определен для NotificationService
- `posts` - геттер не определен в _SpecialistProfileScreenState
- `albums` - геттер не определен в _SpecialistProfileScreenState
- `l10n` - геттер не определен в SettingsPage
- `ref` - геттер не определен в SettingsPage

**Действия:**
1. Добавить отсутствующие методы в UserRole
2. Добавить отсутствующие геттеры в классы
3. Исправить наследование в экранах

---

### КАТЕГОРИЯ 5: 🔗 Несовместимость типов данных
**Приоритет:** 🔴 КРИТИЧЕСКИЙ  
**Файлы:**
- `lib/providers/event_providers.dart`
- `lib/screens/chat_screen.dart`
- `lib/screens/notifications_screen.dart`
- `lib/services/` (множественные файлы)

**Ошибки:**
- Stream vs Future несовместимость
- String vs NotificationType несовместимость
- String vs ChatMessage несовместимость
- String? vs String несовместимость
- double vs int несовместимость

**Действия:**
1. Исправить возвращаемые типы в провайдерах
2. Добавить приведение типов где необходимо
3. Исправить null-safety проблемы

---

### КАТЕГОРИЯ 6: 🏗️ Отсутствующие классы и типы
**Приоритет:** 🔴 КРИТИЧЕСКИЙ  
**Файлы:**
- `lib/services/user_management_service.dart`
- `lib/services/chat_service.dart`
- `lib/services/booking_service.dart`
- `lib/models/specialist_schedule.dart`

**Ошибки:**
- UserRole - тип не найден
- Chat - тип не найден
- NotificationChannel - геттер не определен
- ScheduleEventType.available - член не найден

**Действия:**
1. Создать отсутствующие классы
2. Добавить отсутствующие enum значения
3. Определить отсутствующие геттеры

---

### КАТЕГОРИЯ 7: 🔥 Firebase и Flutter API ошибки
**Приоритет:** 🟠 ВЫСОКИЙ  
**Файлы:**
- `lib/services/notification_service.dart`
- `lib/services/analytics_service.dart`
- `lib/services/backup_service.dart`

**Ошибки:**
- FirebaseMessaging.getInitialMessage - метод не найден
- NotificationType.cancellation - член не найден
- TargetPlatform.web - член не найден
- BadgeStats.empty() - метод не найден

**Действия:**
1. Обновить Firebase API вызовы
2. Исправить устаревшие методы Flutter
3. Добавить отсутствующие методы

---

### КАТЕГОРИЯ 8: 🧪 Ошибки тестов
**Приоритет:** 🟠 ВЫСОКИЙ  
**Файлы:**
- `test/widgets_test.dart`
- `test/integration/` (все файлы)

**Ошибки:**
- ResponsiveWidget - функция не определена
- ResponsiveList - функция не определена
- Invalid constant value - множественные ошибки

**Действия:**
1. Создать отсутствующие тестовые функции
2. Исправить константы в тестах
3. Обновить интеграционные тесты

---

### КАТЕГОРИЯ 9: 🏗️ Ошибки сборки платформ
**Приоритет:** 🟠 ВЫСОКИЙ  
**Платформы:**
- Android (NDK проблемы)
- Web (Flex Color Scheme конфликты)
- Windows (CMake ошибки)

**Ошибки:**
- Android NDK поврежден
- Flex Color Scheme несовместимость
- CMake конфигурация

**Действия:**
1. Переустановить Android NDK
2. Обновить Flex Color Scheme
3. Исправить CMake конфигурацию

---

### КАТЕГОРИЯ 10: 🔄 Riverpod Provider конфликты
**Приоритет:** 🟠 ВЫСОКИЙ  
**Файлы:**
- `lib/screens/favorites_page.dart`
- `lib/widgets/recommendations_section.dart`

**Ошибки:**
- StreamProvider vs ProviderListenable несовместимость
- FutureProviderFamily несовместимость

**Действия:**
1. Обновить Riverpod до совместимой версии
2. Исправить типы провайдеров
3. Обновить вызовы ref.watch

---

## 📋 ПОРЯДОК ВЫПОЛНЕНИЯ

1. **КАТЕГОРИЯ 1** - Дублирование и синтаксис (блокирует компиляцию)
2. **КАТЕГОРИЯ 2** - Конфликты типов (блокирует компиляцию)
3. **КАТЕГОРИЯ 3** - Обязательные параметры (блокирует компиляцию)
4. **КАТЕГОРИЯ 4** - Неопределенные методы (блокирует компиляцию)
5. **КАТЕГОРИЯ 5** - Несовместимость типов (блокирует компиляцию)
6. **КАТЕГОРИЯ 6** - Отсутствующие классы (блокирует компиляцию)
7. **КАТЕГОРИЯ 7** - Firebase/Flutter API (ломает функциональность)
8. **КАТЕГОРИЯ 8** - Тесты (ломает CI/CD)
9. **КАТЕГОРИЯ 9** - Сборка платформ (ломает деплой)
10. **КАТЕГОРИЯ 10** - Riverpod (ломает состояние)

---

## ✅ КРИТЕРИИ УСПЕХА

- [ ] `flutter analyze` возвращает 0 ошибок
- [ ] `flutter test` проходит все тесты
- [ ] `flutter build apk --debug` успешно собирается
- [ ] `flutter build web --release` успешно собирается
- [ ] `flutter build windows --release` успешно собирается
- [ ] `flutter run -d chrome` запускается без ошибок
- [ ] `flutter run -d windows` запускается без ошибок

---

**ГОТОВ К НАЧАЛУ ИСПРАВЛЕНИЙ** 🚀
