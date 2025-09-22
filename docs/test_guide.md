# Руководство по тестированию Event Marketplace App

## 📋 Обзор

Это руководство описывает все аспекты тестирования приложения Event Marketplace App, включая unit-тесты, widget-тесты, интеграционные тесты и тестирование производительности.

## 🎯 Стратегия тестирования

### Пирамида тестирования

```
        /\
       /  \
      / E2E \     <- Интеграционные тесты (10%)
     /______\
    /        \
   / Widget   \   <- Widget тесты (20%)
  /____________\
 /              \
/   Unit Tests   \ <- Unit тесты (70%)
/________________\
```

### Принципы тестирования

1. **AAA Pattern** — Arrange, Act, Assert
2. **Изоляция тестов** — каждый тест независим
3. **Детерминированность** — тесты дают одинаковый результат
4. **Быстрота выполнения** — unit-тесты выполняются быстро
5. **Читаемость** — тесты легко понимать и поддерживать

## 🧪 Типы тестов

### 1. Unit Tests (70%)

Тестирование отдельных функций, классов и методов.

#### Структура unit-тестов

```
test/
├── unit/
│   ├── services/
│   │   ├── auth_service_test.dart
│   │   ├── booking_service_test.dart
│   │   ├── chat_service_test.dart
│   │   └── payment_service_test.dart
│   ├── models/
│   │   ├── user_test.dart
│   │   ├── specialist_test.dart
│   │   ├── booking_test.dart
│   │   └── chat_message_test.dart
│   ├── utils/
│   │   ├── validators_test.dart
│   │   ├── formatters_test.dart
│   │   └── extensions_test.dart
│   └── providers/
│       ├── auth_provider_test.dart
│       ├── specialist_provider_test.dart
│       └── booking_provider_test.dart
```

#### Пример unit-теста сервиса

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:event_marketplace_app/services/auth_service.dart';
import 'package:event_marketplace_app/models/user.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([FirebaseAuth, FirebaseFirestore])
void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      authService = AuthService();
    });

    group('signInWithEmailAndPassword', () {
      test('should return user when credentials are valid', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const expectedUser = AppUser(
          id: 'user123',
          email: email,
          displayName: 'Test User',
          role: UserRole.customer,
          createdAt: DateTime.now(),
        );

        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => UserCredential());

        // Act
        final result = await authService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.email, equals(email));
        verify(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).called(1);
      });

      test('should throw exception when credentials are invalid', () async {
        // Arrange
        const email = 'invalid@example.com';
        const password = 'wrongpassword';

        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(code: 'user-not-found'));

        // Act & Assert
        expect(
          () => authService.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('signOut', () {
      test('should sign out user successfully', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await authService.signOut();

        // Assert
        verify(mockAuth.signOut()).called(1);
      });
    });
  });
}
```

#### Пример unit-теста модели

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:event_marketplace_app/models/specialist.dart';

void main() {
  group('Specialist', () {
    test('should create specialist from map', () {
      // Arrange
      final map = {
        'id': 'specialist123',
        'userId': 'user123',
        'name': 'John Doe',
        'category': 'photographer',
        'hourlyRate': 5000.0,
        'rating': 4.5,
        'reviewCount': 10,
        'isAvailable': true,
        'isVerified': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // Act
      final specialist = Specialist.fromMap(map);

      // Assert
      expect(specialist.id, equals('specialist123'));
      expect(specialist.name, equals('John Doe'));
      expect(specialist.category, equals(SpecialistCategory.photographer));
      expect(specialist.hourlyRate, equals(5000.0));
      expect(specialist.rating, equals(4.5));
      expect(specialist.isAvailable, isTrue);
      expect(specialist.isVerified, isTrue);
    });

    test('should convert specialist to map', () {
      // Arrange
      final specialist = Specialist(
        id: 'specialist123',
        userId: 'user123',
        name: 'John Doe',
        category: SpecialistCategory.photographer,
        hourlyRate: 5000.0,
        rating: 4.5,
        reviewCount: 10,
        isAvailable: true,
        isVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final map = specialist.toMap();

      // Assert
      expect(map['id'], equals('specialist123'));
      expect(map['name'], equals('John Doe'));
      expect(map['category'], equals('photographer'));
      expect(map['hourlyRate'], equals(5000.0));
      expect(map['rating'], equals(4.5));
      expect(map['isAvailable'], isTrue);
      expect(map['isVerified'], isTrue);
    });

    test('should calculate price range correctly', () {
      // Arrange
      final specialist = Specialist(
        id: 'specialist123',
        userId: 'user123',
        name: 'John Doe',
        category: SpecialistCategory.photographer,
        hourlyRate: 5000.0,
        minBookingHours: 2.0,
        maxBookingHours: 8.0,
        rating: 4.5,
        reviewCount: 10,
        isAvailable: true,
        isVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final priceRange = specialist.priceRange;

      // Assert
      expect(priceRange, equals('10000 - 40000 ₽'));
    });
  });
}
```

### 2. Widget Tests (20%)

Тестирование UI компонентов и их взаимодействия.

#### Структура widget-тестов

```
test/
├── widget/
│   ├── screens/
│   │   ├── home_screen_test.dart
│   │   ├── search_screen_test.dart
│   │   ├── specialist_profile_test.dart
│   │   └── booking_form_test.dart
│   ├── widgets/
│   │   ├── specialist_card_test.dart
│   │   ├── booking_requests_test.dart
│   │   ├── my_bookings_test.dart
│   │   └── chat_bubble_test.dart
│   └── providers/
│       ├── auth_provider_test.dart
│       └── specialist_provider_test.dart
```

#### Пример widget-теста

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/widgets/specialist_card.dart';
import 'package:event_marketplace_app/models/specialist.dart';

void main() {
  group('SpecialistCard', () {
    late Specialist testSpecialist;

    setUp(() {
      testSpecialist = Specialist(
        id: 'specialist123',
        userId: 'user123',
        name: 'John Doe',
        description: 'Professional photographer with 5 years experience',
        category: SpecialistCategory.photographer,
        hourlyRate: 5000.0,
        rating: 4.5,
        reviewCount: 10,
        isAvailable: true,
        isVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('should display specialist information correctly', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpecialistCard(specialist: testSpecialist),
          ),
        ),
      );

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Professional photographer with 5 years experience'), findsOneWidget);
      expect(find.text('Фотограф'), findsOneWidget);
      expect(find.text('5000 ₽/час'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('(10 отзывов)'), findsOneWidget);
    });

    testWidgets('should show verified badge for verified specialist', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpecialistCard(specialist: testSpecialist),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('should not show verified badge for unverified specialist', (tester) async {
      // Arrange
      final unverifiedSpecialist = testSpecialist.copyWith(isVerified: false);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpecialistCard(specialist: unverifiedSpecialist),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.verified), findsNothing);
    });

    testWidgets('should navigate to specialist profile when tapped', (tester) async {
      // Arrange
      bool navigated = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => navigated = true,
              child: SpecialistCard(specialist: testSpecialist),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(SpecialistCard));
      await tester.pumpAndSettle();

      // Assert
      expect(navigated, isTrue);
    });

    testWidgets('should show unavailable indicator for unavailable specialist', (tester) async {
      // Arrange
      final unavailableSpecialist = testSpecialist.copyWith(isAvailable: false);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpecialistCard(specialist: unavailableSpecialist),
          ),
        ),
      );

      // Assert
      expect(find.text('Недоступен'), findsOneWidget);
    });
  });
}
```

#### Пример теста экрана

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/screens/home_screen.dart';
import 'package:event_marketplace_app/models/specialist.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('should display loading indicator initially', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display specialists when loaded', (tester) async {
      // Arrange
      final specialists = [
        Specialist(
          id: '1',
          userId: 'user1',
          name: 'John Doe',
          category: SpecialistCategory.photographer,
          hourlyRate: 5000.0,
          rating: 4.5,
          reviewCount: 10,
          isAvailable: true,
          isVerified: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Specialist(
          id: '2',
          userId: 'user2',
          name: 'Jane Smith',
          category: SpecialistCategory.videographer,
          hourlyRate: 6000.0,
          rating: 4.8,
          reviewCount: 15,
          isAvailable: true,
          isVerified: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            specialistsProvider.overrideWith((ref) => AsyncValue.data(specialists)),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.byType(SpecialistCard), findsNWidgets(2));
    });

    testWidgets('should display error message when loading fails', (tester) async {
      // Arrange
      const errorMessage = 'Failed to load specialists';

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            specialistsProvider.overrideWith(
              (ref) => AsyncValue.error(errorMessage, StackTrace.current),
            ),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ошибка загрузки'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
    });
  });
}
```

### 3. Integration Tests (10%)

Тестирование полных пользовательских сценариев.

#### Структура интеграционных тестов

```
test/
├── integration/
│   ├── booking_flow_test.dart
│   ├── calendar_flow_test.dart
│   ├── payment_flow_test.dart
│   ├── chat_flow_test.dart
│   └── auth_flow_test.dart
```

#### Пример интеграционного теста

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:event_marketplace_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Booking Flow Integration Test', () {
    testWidgets('should complete full booking flow', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act & Assert - Step 1: Login
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();

      // Verify login success
      expect(find.text('Главная'), findsOneWidget);

      // Step 2: Search for specialist
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextField), 'фотограф');
      await tester.tap(find.text('Поиск'));
      await tester.pumpAndSettle();

      // Verify search results
      expect(find.byType(SpecialistCard), findsWidgets);

      // Step 3: Select specialist
      await tester.tap(find.byType(SpecialistCard).first);
      await tester.pumpAndSettle();

      // Verify specialist profile
      expect(find.text('Забронировать'), findsOneWidget);

      // Step 4: Create booking
      await tester.tap(find.text('Забронировать'));
      await tester.pumpAndSettle();

      // Fill booking form
      await tester.enterText(find.byKey(Key('event_date')), '2024-12-25');
      await tester.enterText(find.byKey(Key('event_time')), '18:00');
      await tester.enterText(find.byKey(Key('duration')), '4');
      await tester.enterText(find.byKey(Key('location')), 'Москва, Красная площадь');
      await tester.enterText(find.byKey(Key('notes')), 'Свадебная фотосессия');
      
      await tester.tap(find.text('Отправить заявку'));
      await tester.pumpAndSettle();

      // Verify booking created
      expect(find.text('Заявка отправлена'), findsOneWidget);

      // Step 5: Check booking in list
      await tester.tap(find.text('Мои заказы'));
      await tester.pumpAndSettle();

      expect(find.text('Ожидает подтверждения'), findsOneWidget);
    });

    testWidgets('should handle booking cancellation', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Login and navigate to bookings
      await _loginUser(tester);
      await tester.tap(find.text('Мои заказы'));
      await tester.pumpAndSettle();

      // Act - Cancel booking
      await tester.tap(find.text('Отменить'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Подтвердить отмену'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Заказ отменен'), findsOneWidget);
    });
  });

  group('Chat Flow Integration Test', () {
    testWidgets('should send and receive messages', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      await _loginUser(tester);

      // Act - Open chat
      await tester.tap(find.text('Чат'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.byType(SpecialistCard).first);
      await tester.pumpAndSettle();

      // Send message
      await tester.enterText(find.byType(TextField), 'Здравствуйте! Интересует ваша услуга');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Здравствуйте! Интересует ваша услуга'), findsOneWidget);
    });
  });
}

// Helper function for login
Future<void> _loginUser(WidgetTester tester) async {
  await tester.tap(find.text('Войти'));
  await tester.pumpAndSettle();
  
  await tester.enterText(find.byType(TextField).first, 'test@example.com');
  await tester.enterText(find.byType(TextField).last, 'password123');
  await tester.tap(find.text('Войти'));
  await tester.pumpAndSettle();
}
```

## 🚀 Запуск тестов

### Команды для запуска тестов

```bash
# Все тесты
flutter test

# Конкретный тест
flutter test test/unit/services/auth_service_test.dart

# Тесты с покрытием
flutter test --coverage

# Интеграционные тесты
flutter test integration_test/

# Тесты на конкретной платформе
flutter test -d chrome
flutter test -d android
flutter test -d ios

# Тесты с детальным выводом
flutter test --verbose

# Тесты с фильтром
flutter test --name "AuthService"
```

### Настройка тестового окружения

#### 1. Создание тестовых данных

```dart
// test/test_data/test_specialists.dart
class TestData {
  static List<Specialist> get specialists => [
    Specialist(
      id: 'specialist1',
      userId: 'user1',
      name: 'John Doe',
      category: SpecialistCategory.photographer,
      hourlyRate: 5000.0,
      rating: 4.5,
      reviewCount: 10,
      isAvailable: true,
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Specialist(
      id: 'specialist2',
      userId: 'user2',
      name: 'Jane Smith',
      category: SpecialistCategory.videographer,
      hourlyRate: 6000.0,
      rating: 4.8,
      reviewCount: 15,
      isAvailable: true,
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  static List<Booking> get bookings => [
    Booking(
      id: 'booking1',
      userId: 'user1',
      specialistId: 'specialist1',
      eventDate: DateTime.now().add(Duration(days: 7)),
      status: BookingStatus.pending,
      totalPrice: 20000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
}
```

#### 2. Моки и заглушки

```dart
// test/mocks/mock_services.dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:event_marketplace_app/services/auth_service.dart';
import 'package:event_marketplace_app/services/booking_service.dart';

@GenerateMocks([
  AuthService,
  BookingService,
  ChatService,
  PaymentService,
])
void main() {}
```

#### 3. Тестовые утилиты

```dart
// test/utils/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestHelpers {
  static Widget createTestWidget({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pump();
    await tester.pumpAndSettle();
  }

  static Future<void> enterTextAndSubmit(
    WidgetTester tester,
    String text,
    String buttonText,
  ) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.text(buttonText));
    await tester.pumpAndSettle();
  }
}
```

## 📊 Покрытие кода

### Настройка покрытия

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  coverage: ^1.6.0
```

### Генерация отчета о покрытии

```bash
# Запуск тестов с покрытием
flutter test --coverage

# Генерация HTML отчета
genhtml coverage/lcov.info -o coverage/html

# Просмотр отчета
open coverage/html/index.html
```

### Анализ покрытия

```bash
# Установка lcov (Linux/macOS)
sudo apt-get install lcov  # Ubuntu/Debian
brew install lcov          # macOS

# Анализ покрытия
lcov --summary coverage/lcov.info
```

## 🔧 CI/CD интеграция

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.5.0'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Run tests
      run: flutter test --coverage
      
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info
```

### GitLab CI

```yaml
# .gitlab-ci.yml
test:
  stage: test
  image: cirrusci/flutter:3.5.0
  script:
    - flutter pub get
    - flutter test --coverage
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura.xml
```

## 🐛 Отладка тестов

### Полезные команды

```bash
# Запуск тестов с отладкой
flutter test --verbose

# Запуск конкретного теста с отладкой
flutter test test/unit/services/auth_service_test.dart --verbose

# Запуск тестов с сохранением скриншотов
flutter test integration_test/ --screenshot
```

### Отладка widget-тестов

```dart
testWidgets('debug widget test', (tester) async {
  await tester.pumpWidget(MyWidget());
  
  // Вывод дерева виджетов
  debugDumpApp();
  
  // Вывод рендера
  debugDumpRenderTree();
  
  // Пауза для инспекции
  await tester.pumpAndSettle();
});
```

## 📈 Метрики качества

### Целевые показатели

- **Покрытие кода**: > 80%
- **Unit тесты**: > 70% от общего количества тестов
- **Widget тесты**: > 20% от общего количества тестов
- **Интеграционные тесты**: > 10% от общего количества тестов
- **Время выполнения**: < 5 минут для всех тестов

### Мониторинг качества

```dart
// test/quality_metrics.dart
class QualityMetrics {
  static void checkTestCoverage() {
    // Проверка покрытия кода
    final coverage = _getCoveragePercentage();
    assert(coverage >= 80, 'Test coverage is below 80%: $coverage%');
  }
  
  static void checkTestPerformance() {
    // Проверка времени выполнения тестов
    final duration = _getTestDuration();
    assert(duration.inMinutes < 5, 'Tests take too long: ${duration.inMinutes} minutes');
  }
}
```

## 🎯 Лучшие практики

### 1. Написание тестов

- **Один тест = одна проверка**
- **Используйте описательные имена тестов**
- **Группируйте связанные тесты**
- **Используйте setUp и tearDown для подготовки**

### 2. Моки и заглушки

- **Мокайте внешние зависимости**
- **Используйте реальные данные в интеграционных тестах**
- **Избегайте моков в unit-тестах моделей**

### 3. Асинхронные тесты

```dart
test('async test example', () async {
  // Правильно
  final result = await someAsyncFunction();
  expect(result, isNotNull);
  
  // Неправильно
  someAsyncFunction().then((result) {
    expect(result, isNotNull);
  });
});
```

### 4. Тестирование состояний

```dart
testWidgets('state management test', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MyWidget(),
    ),
  );
  
  // Проверка начального состояния
  expect(find.text('Initial State'), findsOneWidget);
  
  // Изменение состояния
  await tester.tap(find.byIcon(Icons.refresh));
  await tester.pump();
  
  // Проверка нового состояния
  expect(find.text('Loading...'), findsOneWidget);
  
  await tester.pumpAndSettle();
  expect(find.text('Updated State'), findsOneWidget);
});
```

## 🔍 Troubleshooting

### Частые проблемы

#### 1. Тесты не находят виджеты

```dart
// Проблема: find.text('Button') не находит кнопку
// Решение: используйте ключи
await tester.tap(find.byKey(Key('submit_button')));
```

#### 2. Асинхронные операции

```dart
// Проблема: тест завершается до завершения асинхронной операции
// Решение: используйте pumpAndSettle
await tester.pumpAndSettle();
```

#### 3. Моки не работают

```dart
// Проблема: мок не возвращает ожидаемое значение
// Решение: проверьте настройку мока
when(mockService.getData()).thenAnswer((_) async => testData);
```

### Отладка интеграционных тестов

```dart
testWidgets('integration test with debugging', (tester) async {
  // Включение отладки
  await tester.binding.setSurfaceSize(Size(800, 600));
  
  // Запуск приложения
  app.main();
  await tester.pumpAndSettle();
  
  // Пауза для инспекции
  await tester.pump(Duration(seconds: 2));
  
  // Продолжение теста
  // ...
});
```

---

Это руководство обеспечивает комплексное тестирование Event Marketplace App, гарантируя высокое качество и надежность приложения для пользователей по всей России.



