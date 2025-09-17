# Contributing Guide

## Добро пожаловать!

Спасибо за интерес к Event Marketplace App! Мы приветствуем вклад от сообщества и ценим ваше участие в развитии проекта.

## Как внести вклад

### 1. Сообщения об ошибках

Если вы нашли ошибку, пожалуйста:

1. Проверьте, не была ли уже зарегистрирована эта ошибка в [Issues](https://github.com/your-username/event_marketplace_app/issues)
2. Создайте новый issue с подробным описанием:
   - Шаги для воспроизведения
   - Ожидаемое поведение
   - Фактическое поведение
   - Скриншоты (если применимо)
   - Информация об окружении (версия Flutter, платформа, устройство)

### 2. Предложения функций

Для предложения новых функций:

1. Проверьте, не было ли уже предложено что-то подобное
2. Создайте issue с тегом `enhancement`
3. Опишите:
   - Проблему, которую решает функция
   - Предлагаемое решение
   - Альтернативные варианты
   - Дополнительную информацию

### 3. Pull Requests

Для внесения изменений в код:

1. Создайте форк репозитория
2. Создайте ветку для вашей функции/исправления
3. Внесите изменения
4. Добавьте тесты
5. Создайте Pull Request

## Процесс разработки

### Настройка окружения

1. **Клонирование форка**
```bash
git clone https://github.com/your-username/event_marketplace_app.git
cd event_marketplace_app
```

2. **Установка зависимостей**
```bash
flutter pub get
```

3. **Настройка IDE**
- Установите Flutter и Dart плагины
- Настройте форматирование кода
- Включите линтеры

### Создание ветки

```bash
# Создание новой ветки
git checkout -b feature/your-feature-name

# Или для исправления ошибки
git checkout -b fix/issue-number-description
```

### Соглашения о коммитах

Используйте [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: добавить новую функцию
fix: исправить баг
docs: обновить документацию
style: форматирование кода
refactor: рефакторинг
test: добавить тесты
chore: обновить зависимости
```

Примеры:
```bash
git commit -m "feat: добавить поддержку темной темы"
git commit -m "fix: исправить ошибку загрузки изображений"
git commit -m "docs: обновить README с инструкциями по установке"
```

## Стандарты кода

### Dart Style Guide

Следуйте [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style):

```dart
// ✅ Хорошо
class UserService {
  final FirebaseFirestore _firestore;
  
  UserService(this._firestore);
  
  Future<User?> getUserById(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      return doc.exists ? User.fromDocument(doc) : null;
    } catch (e) {
      throw UserServiceException('Ошибка получения пользователя: $e');
    }
  }
}

// ❌ Плохо
class userService {
  final FirebaseFirestore firestore;
  userService(this.firestore);
  Future<User?> getuserbyid(String id) async {
    var doc = await firestore.collection('users').doc(id).get();
    if (doc.exists) {
      return User.fromDocument(doc);
    } else {
      return null;
    }
  }
}
```

### Форматирование

```bash
# Автоматическое форматирование
dart format .

# Проверка стиля
dart analyze
```

### Именование

- **Классы**: PascalCase (`UserService`, `EventCard`)
- **Функции и переменные**: camelCase (`getUserById`, `isLoading`)
- **Константы**: camelCase (`defaultTimeout`, `maxRetries`)
- **Файлы**: snake_case (`user_service.dart`, `event_card.dart`)

### Документация

```dart
/// Сервис для работы с пользователями
/// 
/// Предоставляет методы для создания, обновления и получения
/// информации о пользователях из Firestore.
class UserService {
  final FirebaseFirestore _firestore;
  
  /// Создает экземпляр [UserService]
  /// 
  /// [firestore] - экземпляр Firestore для работы с базой данных
  UserService(this._firestore);
  
  /// Получает пользователя по ID
  /// 
  /// Возвращает [User] если пользователь найден, иначе null.
  /// 
  /// Throws [UserServiceException] если произошла ошибка.
  Future<User?> getUserById(String id) async {
    // Реализация
  }
}
```

## Тестирование

### Типы тестов

1. **Unit тесты** - Тестирование отдельных функций и классов
2. **Widget тесты** - Тестирование UI компонентов
3. **Integration тесты** - Тестирование пользовательских сценариев

### Структура тестов

```
test/
├── unit/                 # Unit тесты
│   ├── services/
│   ├── models/
│   └── utils/
├── widget/               # Widget тесты
│   ├── screens/
│   └── widgets/
├── integration/          # Integration тесты
└── mocks/               # Mock объекты
```

### Примеры тестов

#### Unit тест

```dart
// test/unit/services/user_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:event_marketplace_app/services/user_service.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  group('UserService', () {
    late UserService userService;
    late MockFirebaseFirestore mockFirestore;
    
    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      userService = UserService(mockFirestore);
    });
    
    test('should return user when getUserById is called with valid id', () async {
      // Arrange
      const userId = 'user123';
      final mockDoc = MockDocumentSnapshot();
      when(mockDoc.exists).thenReturn(true);
      when(mockDoc.data()).thenReturn({'id': userId, 'name': 'Test User'});
      
      when(mockFirestore.collection('users').doc(userId).get())
          .thenAnswer((_) async => mockDoc);
      
      // Act
      final result = await userService.getUserById(userId);
      
      // Assert
      expect(result, isNotNull);
      expect(result!.id, equals(userId));
      expect(result.name, equals('Test User'));
    });
  });
}
```

#### Widget тест

```dart
// test/widget/screens/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen should display events list', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventsProvider.overrideWith((ref) => MockEventsNotifier()),
        ],
        child: MaterialApp(home: HomeScreen()),
      ),
    );
    
    // Act
    await tester.pumpAndSettle();
    
    // Assert
    expect(find.byType(EventCard), findsWidgets);
    expect(find.text('События'), findsOneWidget);
  });
}
```

### Запуск тестов

```bash
# Все тесты
flutter test

# Конкретный тест
flutter test test/unit/services/user_service_test.dart

# С покрытием
flutter test --coverage
```

## Pull Request процесс

### 1. Подготовка

- Убедитесь, что ваша ветка актуальна
- Запустите тесты и убедитесь, что они проходят
- Проверьте форматирование кода

```bash
# Обновление ветки
git checkout main
git pull origin main
git checkout your-branch
git rebase main

# Запуск тестов
flutter test

# Форматирование
dart format .
dart analyze
```

### 2. Создание PR

1. Перейдите на GitHub и создайте Pull Request
2. Заполните шаблон PR:
   - Описание изменений
   - Связанные issues
   - Чек-лист
   - Скриншоты (если применимо)

### 3. Шаблон PR

```markdown
## Описание
Краткое описание изменений

## Тип изменений
- [ ] Исправление ошибки
- [ ] Новая функция
- [ ] Рефакторинг
- [ ] Обновление документации
- [ ] Другое

## Связанные Issues
Closes #123

## Чек-лист
- [ ] Код соответствует стандартам проекта
- [ ] Добавлены тесты для новых функций
- [ ] Все тесты проходят
- [ ] Документация обновлена
- [ ] Изменения не ломают существующий функционал

## Скриншоты
(Если применимо)

## Дополнительная информация
Любая дополнительная информация для ревьюеров
```

### 4. Ревью процесса

- Код будет проверен командой разработчиков
- Могут быть запрошены изменения
- После одобрения PR будет объединен

## Feature Flags

Для новых функций используйте feature flags:

```dart
// lib/core/feature_flags.dart
class FeatureFlags {
  static const bool newFeatureEnabled = false; // Начните с false
}

// В коде
if (FeatureFlags.newFeatureEnabled) {
  // Новая функциональность
}
```

## Локализация

При добавлении новых строк:

1. Добавьте в `lib/l10n/app_ru.arb`:
```json
{
  "newFeature": "Новая функция",
  "@newFeature": {
    "description": "Описание новой функции"
  }
}
```

2. Добавьте в `lib/l10n/app_en.arb`:
```json
{
  "newFeature": "New Feature",
  "@newFeature": {
    "description": "Description of new feature"
  }
}
```

3. Используйте в коде:
```dart
Text(AppLocalizations.of(context)!.newFeature)
```

## Производительность

### Рекомендации

1. **Избегайте rebuilds** - Используйте `const` конструкторы
2. **Lazy loading** - Загружайте данные по требованию
3. **Кэширование** - Кэшируйте часто используемые данные
4. **Оптимизация изображений** - Используйте подходящие форматы

### Профилирование

```bash
# Профилирование производительности
flutter run --profile

# Анализ размера приложения
flutter build apk --analyze-size
```

## Безопасность

### Рекомендации

1. **Не коммитьте секреты** - Используйте переменные окружения
2. **Валидация данных** - Проверяйте все входные данные
3. **Безопасные API вызовы** - Используйте HTTPS
4. **Управление зависимостями** - Регулярно обновляйте пакеты

### Проверка безопасности

```bash
# Анализ зависимостей
flutter pub deps

# Проверка уязвимостей
flutter pub audit
```

## Коммуникация

### Каналы связи

- **GitHub Issues** - Для багов и предложений
- **GitHub Discussions** - Для общих вопросов
- **Discord** - Для неформального общения (если есть)

### Этикет

- Будьте вежливы и уважительны
- Используйте понятный язык
- Предоставляйте подробную информацию
- Будьте терпеливы с ответами

## Признание вклада

Все участники будут упомянуты в:

- **CONTRIBUTORS.md** - Список всех участников
- **Release Notes** - Упоминание в релизах
- **About Screen** - В приложении (опционально)

## Лицензия

Внося вклад в проект, вы соглашаетесь с тем, что ваш код будет лицензирован под MIT License.

## Вопросы?

Если у вас есть вопросы, не стесняйтесь:

1. Создать issue с тегом `question`
2. Написать в Discussions
3. Связаться с командой разработчиков

---

**Спасибо за ваш вклад в Event Marketplace App!** 🎉
