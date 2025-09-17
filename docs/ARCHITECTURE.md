# Архитектура Event Marketplace App

## Обзор

Event Marketplace App построен с использованием принципов Clean Architecture и следует паттернам Flutter/Dart для создания масштабируемого и поддерживаемого приложения.

## Архитектурные принципы

### 1. Clean Architecture

Приложение разделено на слои:

```
┌─────────────────────────────────────┐
│           Presentation Layer        │ ← UI, Widgets, Screens
├─────────────────────────────────────┤
│           Domain Layer              │ ← Business Logic, Models
├─────────────────────────────────────┤
│           Data Layer                │ ← Services, Repositories
└─────────────────────────────────────┘
```

### 2. SOLID принципы

- **S** - Single Responsibility: Каждый класс имеет одну ответственность
- **O** - Open/Closed: Открыт для расширения, закрыт для модификации
- **L** - Liskov Substitution: Подклассы должны заменять базовые классы
- **I** - Interface Segregation: Много специфичных интерфейсов лучше одного общего
- **D** - Dependency Inversion: Зависимость от абстракций, а не от конкретных реализаций

### 3. Dependency Injection

Используется Riverpod для управления зависимостями:

```dart
// Провайдер сервиса
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Использование в виджете
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    // ...
  }
}
```

## Структура проекта

### Core Layer

```
lib/core/
├── app_constants.dart      # Константы приложения
├── app_router.dart         # Конфигурация навигации
├── app_styles.dart         # Стили и темы
├── error_handler.dart      # Глобальная обработка ошибок
├── feature_flags.dart      # Управление функциями
├── performance_optimizations.dart # Оптимизации производительности
├── utils.dart              # Утилиты
└── validators.dart         # Валидаторы
```

### Models Layer

```
lib/models/
├── user.dart               # Модель пользователя
├── event.dart              # Модель события
├── booking.dart            # Модель бронирования
├── specialist.dart         # Модель специалиста
├── review.dart             # Модель отзыва
├── payment.dart            # Модель платежа
└── ...
```

### Providers Layer

```
lib/providers/
├── auth_providers.dart     # Провайдеры аутентификации
├── event_providers.dart    # Провайдеры событий
├── booking_providers.dart  # Провайдеры бронирований
├── theme_provider.dart     # Провайдер темы
├── locale_provider.dart    # Провайдер локализации
└── ...
```

### Services Layer

```
lib/services/
├── auth_service.dart       # Сервис аутентификации
├── event_service.dart      # Сервис событий
├── booking_service.dart    # Сервис бронирований
├── firestore_service.dart  # Сервис Firestore
├── storage_service.dart    # Сервис хранения файлов
└── ...
```

### Presentation Layer

```
lib/screens/                # Экраны приложения
lib/widgets/                # Переиспользуемые виджеты
```

## Паттерны проектирования

### 1. Repository Pattern

```dart
abstract class EventRepository {
  Future<List<Event>> getEvents();
  Future<Event> getEventById(String id);
  Future<void> createEvent(Event event);
  Future<void> updateEvent(Event event);
  Future<void> deleteEvent(String id);
}

class FirestoreEventRepository implements EventRepository {
  final FirebaseFirestore _firestore;
  
  FirestoreEventRepository(this._firestore);
  
  @override
  Future<List<Event>> getEvents() async {
    // Реализация
  }
}
```

### 2. State Management с Riverpod

```dart
// Состояние
class EventState {
  final List<Event> events;
  final bool isLoading;
  final String? error;
  
  const EventState({
    this.events = const [],
    this.isLoading = false,
    this.error,
  });
}

// Notifier
class EventNotifier extends StateNotifier<EventState> {
  final EventRepository _repository;
  
  EventNotifier(this._repository) : super(const EventState());
  
  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true);
    try {
      final events = await _repository.getEvents();
      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

// Провайдер
final eventProvider = StateNotifierProvider<EventNotifier, EventState>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return EventNotifier(repository);
});
```

### 3. Factory Pattern

```dart
class ServiceFactory {
  static AuthService createAuthService() {
    return AuthService(
      firebaseAuth: FirebaseAuth.instance,
      googleSignIn: GoogleSignIn(),
    );
  }
  
  static EventService createEventService() {
    return EventService(
      firestore: FirebaseFirestore.instance,
      storage: FirebaseStorage.instance,
    );
  }
}
```

### 4. Observer Pattern

```dart
class EventObserver {
  final List<Event> _events = [];
  final List<Function(Event)> _listeners = [];
  
  void addListener(Function(Event) listener) {
    _listeners.add(listener);
  }
  
  void removeListener(Function(Event) listener) {
    _listeners.remove(listener);
  }
  
  void notifyListeners(Event event) {
    for (final listener in _listeners) {
      listener(event);
    }
  }
}
```

## Управление состоянием

### Riverpod Providers

1. **Provider** - Простые значения
2. **StateProvider** - Изменяемое состояние
3. **StateNotifierProvider** - Сложная логика состояния
4. **FutureProvider** - Асинхронные операции
5. **StreamProvider** - Потоки данных

### Примеры использования

```dart
// Простой провайдер
final themeProvider = Provider<ThemeData>((ref) {
  return ThemeData.light();
});

// Провайдер с состоянием
final counterProvider = StateProvider<int>((ref) => 0);

// Провайдер с бизнес-логикой
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.watch(authServiceProvider));
});

// Асинхронный провайдер
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final service = ref.watch(eventServiceProvider);
  return await service.getEvents();
});
```

## Обработка ошибок

### Глобальная обработка

```dart
class GlobalErrorHandler {
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Логирование ошибки
      SafeLog.error('Flutter error: ${details.exception}', 
                   details.exception, details.stack);
      
      // Отправка в Crashlytics
      if (FeatureFlags.crashlyticsEnabled) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };
  }
}
```

### Локальная обработка

```dart
class EventService {
  Future<List<Event>> getEvents() async {
    try {
      // Бизнес-логика
      return await _repository.getEvents();
    } on FirebaseException catch (e) {
      throw EventServiceException('Ошибка загрузки событий: ${e.message}');
    } catch (e) {
      throw EventServiceException('Неизвестная ошибка: $e');
    }
  }
}
```

## Производительность

### Оптимизации

1. **Lazy Loading** - Загрузка данных по требованию
2. **Caching** - Кэширование часто используемых данных
3. **Pagination** - Постраничная загрузка
4. **Image Optimization** - Оптимизация изображений
5. **Memory Management** - Управление памятью

### Мониторинг

```dart
class PerformanceMonitor {
  static Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      return result;
    } finally {
      stopwatch.stop();
      SafeLog.info('Operation $operationName took ${stopwatch.elapsedMilliseconds}ms');
    }
  }
}
```

## Безопасность

### Аутентификация

- Firebase Authentication
- JWT токены
- Refresh токены
- Биометрическая аутентификация

### Авторизация

- Role-based access control
- Firestore Security Rules
- API ключи
- Валидация на клиенте и сервере

### Защита данных

- Шифрование чувствительных данных
- Secure Storage
- HTTPS только
- Валидация входных данных

## Тестирование

### Стратегия тестирования

1. **Unit Tests** (70%) - Тестирование отдельных функций
2. **Widget Tests** (20%) - Тестирование UI компонентов
3. **Integration Tests** (10%) - Тестирование пользовательских сценариев

### Примеры тестов

```dart
// Unit тест
test('should return events when getEvents is called', () async {
  // Arrange
  final mockRepository = MockEventRepository();
  when(mockRepository.getEvents()).thenAnswer((_) async => [testEvent]);
  final service = EventService(mockRepository);
  
  // Act
  final result = await service.getEvents();
  
  // Assert
  expect(result, [testEvent]);
});

// Widget тест
testWidgets('should display events list', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        eventProvider.overrideWith((ref) => MockEventNotifier()),
      ],
      child: MaterialApp(home: EventsScreen()),
    ),
  );
  
  expect(find.byType(EventCard), findsWidgets);
});
```

## Масштабируемость

### Горизонтальное масштабирование

- Микросервисная архитектура
- Load balancing
- CDN для статических ресурсов
- Кэширование на разных уровнях

### Вертикальное масштабирование

- Оптимизация алгоритмов
- Профилирование производительности
- Управление памятью
- Асинхронная обработка

## Заключение

Архитектура Event Marketplace App спроектирована для обеспечения:

- **Масштабируемости** - Легкое добавление новых функций
- **Поддерживаемости** - Четкое разделение ответственности
- **Тестируемости** - Изолированные компоненты
- **Производительности** - Оптимизированные решения
- **Безопасности** - Многоуровневая защита

Эта архитектура позволяет команде разработчиков эффективно работать над проектом и обеспечивает высокое качество кода.
