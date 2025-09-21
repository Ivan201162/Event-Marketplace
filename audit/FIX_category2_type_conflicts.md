# FIX_category2_type_conflicts.md
## Исправление КАТЕГОРИИ 2: Конфликты типов (UserRole, MaritalStatus, NotificationType)

**Дата исправления:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Статус:** ✅ ЗАВЕРШЕНО

---

## 🔄 ИСПРАВЛЕННЫЕ КОНФЛИКТЫ ТИПОВ

### 1. Конфликт UserRole
**Проблема:** Два разных определения UserRole
- `lib/models/security.dart` - `class UserRole` (модель назначения роли)
- `lib/models/user.dart` - `enum UserRole` (перечисление ролей)

**Решение:** Переименован класс в security.dart
- `class UserRole` → `class UserRoleAssignment`
- Обновлены все ссылки в security.dart

**Файлы изменены:**
- `lib/models/security.dart` - переименован класс

### 2. Конфликт MaritalStatus
**Проблема:** Дублирование enum MaritalStatus
- `lib/models/customer_profile.dart` - `enum MaritalStatus`
- `lib/models/user.dart` - `enum MaritalStatus`

**Решение:** Удален дублирующий enum из customer_profile.dart
- Удален enum MaritalStatus из customer_profile.dart
- Добавлен импорт `import 'user.dart';`
- Все использования MaritalStatus теперь ссылаются на user.dart

**Файлы изменены:**
- `lib/models/customer_profile.dart` - удален дублирующий enum, добавлен импорт

### 3. Конфликт NotificationType
**Проблема:** Два разных enum NotificationType с разными значениями
- `lib/models/notification.dart` - `enum NotificationType` (6 значений)
- `lib/models/notification_type.dart` - `enum NotificationType` (14 значений)

**Решение:** Унифицирован в notification_type.dart
- Удален enum из notification.dart
- Добавлен импорт `import 'notification_type.dart';`
- Добавлено недостающее значение `cancellation`
- Обновлены extension методы

**Файлы изменены:**
- `lib/models/notification.dart` - удален enum, добавлен импорт
- `lib/models/notification_type.dart` - добавлено значение `cancellation`

---

## ✅ РЕЗУЛЬТАТЫ

### Исправленные ошибки:
- ✅ UserRole/*1*/ vs UserRole/*2*/ конфликты
- ✅ MaritalStatus/*1*/ vs MaritalStatus/*2*/ конфликты  
- ✅ NotificationType/*1*/ vs NotificationType/*2*/ конфликты
- ✅ Member not found: 'cancellation'

### Унифицированные типы:
- ✅ UserRole - только enum в user.dart
- ✅ MaritalStatus - только enum в user.dart
- ✅ NotificationType - только enum в notification_type.dart

---

## 📋 ДЕТАЛИ ИЗМЕНЕНИЙ

### lib/models/security.dart
```dart
// ДО
class UserRole {
  const UserRole({
    required this.id,
    required this.userId,
    // ...
  });

// ПОСЛЕ  
class UserRoleAssignment {
  const UserRoleAssignment({
    required this.id,
    required this.userId,
    // ...
  });
```

### lib/models/customer_profile.dart
```dart
// ДО
import 'package:cloud_firestore/cloud_firestore.dart';

enum MaritalStatus {
  single,
  married,
  // ...
}

// ПОСЛЕ
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';
```

### lib/models/notification.dart
```dart
// ДО
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  booking,
  message,
  // ...
}

// ПОСЛЕ
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_type.dart';
```

### lib/models/notification_type.dart
```dart
// ДО
enum NotificationType {
  booking,
  payment,
  // ...
  announcement,
}

// ПОСЛЕ
enum NotificationType {
  booking,
  payment,
  // ...
  announcement,
  cancellation, // ДОБАВЛЕНО
}
```

---

## 🔍 ПРОВЕРКА ИСПРАВЛЕНИЙ

### Проверяем, что конфликты устранены:
```bash
# Проверяем, что нет дублирующих определений
findstr /s /n "enum UserRole" lib\models\*.dart
findstr /s /n "enum MaritalStatus" lib\models\*.dart  
findstr /s /n "enum NotificationType" lib\models\*.dart

# Проверяем компиляцию
flutter analyze lib/models/security.dart
flutter analyze lib/models/customer_profile.dart
flutter analyze lib/models/notification.dart
flutter analyze lib/models/notification_type.dart
```

---

## 📋 СЛЕДУЮЩИЕ ШАГИ

**КАТЕГОРИЯ 2 ЗАВЕРШЕНА** ✅  
**Переходим к КАТЕГОРИИ 3:** Отсутствующие обязательные параметры

---

## ⚠️ ВАЖНЫЕ ЗАМЕЧАНИЯ

1. **UserRoleAssignment** - новый класс для назначения ролей пользователям
2. **MaritalStatus** - теперь только в user.dart
3. **NotificationType** - теперь только в notification_type.dart с полным набором значений
4. **cancellation** - добавлено новое значение для уведомлений об отмене

---

**СТАТУС:** КАТЕГОРИЯ 2 УСПЕШНО ИСПРАВЛЕНА 🎉
