# Архитектура Event Marketplace App

## 📋 Обзор

Event Marketplace App построен на основе современной архитектуры с использованием Flutter и Firebase. Приложение следует принципам Clean Architecture и использует паттерн MVVM с Riverpod для управления состоянием.

## 🏗️ Общая архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                    Event Marketplace App                    │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (UI)                                   │
│  ├── Screens (126 files)                                   │
│  ├── Widgets (91 files)                                    │
│  └── Providers (52 files)                                  │
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer (Services)                           │
│  ├── Auth Service                                          │
│  ├── Booking Service                                       │
│  ├── Chat Service                                          │
│  ├── Payment Service                                       │
│  ├── Analytics Service                                     │
│  └── 100+ других сервисов                                  │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (Models & Firebase)                            │
│  ├── Models (94 files)                                     │
│  ├── Firestore                                             │
│  ├── Firebase Auth                                         │
│  ├── Firebase Storage                                      │
│  └── Firebase Functions                                    │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 Архитектурные принципы

### 1. Clean Architecture
- **Разделение ответственности** — каждый слой имеет четко определенную роль
- **Независимость от фреймворков** — бизнес-логика не зависит от UI
- **Тестируемость** — каждый компонент может быть протестирован изолированно
- **Гибкость** — легко добавлять новые функции и изменять существующие

### 2. MVVM Pattern
- **Model** — данные и бизнес-логика
- **View** — UI компоненты (Screens, Widgets)
- **ViewModel** — связующее звено между Model и View (Providers)

### 3. SOLID Principles
- **Single Responsibility** — каждый класс имеет одну ответственность
- **Open/Closed** — открыт для расширения, закрыт для модификации
- **Liskov Substitution** — подклассы могут заменять базовые классы
- **Interface Segregation** — интерфейсы разделены по функциональности
- **Dependency Inversion** — зависимости инвертированы

## 📁 Структура проекта

```
lib/
├── analytics/           # Аналитика и метрики
├── calendar/           # Календарные функции
├── core/               # Основные компоненты
│   ├── constants/      # Константы приложения
│   ├── extensions/     # Расширения Dart
│   ├── i18n/          # Интернационализация
│   ├── platform/      # Платформо-специфичный код
│   ├── riverpod/      # Конфигурация Riverpod
│   ├── utils/         # Утилиты
│   └── validators/    # Валидаторы
├── generated/          # Сгенерированный код
├── l10n/              # Файлы локализации
├── maps/              # Интеграция с картами
├── models/            # Модели данных (94 файла)
├── payments/          # Платежные системы
├── providers/         # Riverpod провайдеры (52 файла)
├── screens/           # Экраны приложения (126 файлов)
├── services/          # Бизнес-логика (105 файлов)
├── ui/                # UI компоненты
└── widgets/           # Переиспользуемые виджеты (91 файл)
```

## 🔧 Слои архитектуры

### 1. Presentation Layer (UI)

#### Screens (126 файлов)
Основные экраны приложения, организованные по функциональности:

```dart
// Пример структуры экрана
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialists = ref.watch(specialistsProvider);
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      body: specialists.when(
        data: (data) => SpecialistGrid(specialists: data),
        loading: () => LoadingWidget(),
        error: (error, stack) => ErrorWidget(error),
      ),
    );
  }
}
```

#### Widgets (91 файл)
Переиспользуемые UI компоненты:

- **SpecialistCard** — карточка специалиста
- **BookingForm** — форма бронирования
- **ChatBubble** — сообщение в чате
- **RatingWidget** — компонент рейтинга
- **SearchFilters** — фильтры поиска

#### Providers (52 файла)
Riverpod провайдеры для управления состоянием:

```dart
// Пример провайдера
final specialistsProvider = StreamProvider<List<Specialist>>((ref) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getSpecialists();
});

final currentUserProvider = StateProvider<AppUser?>((ref) => null);
```

### 2. Business Logic Layer (Services)

#### AuthService
Управление аутентификацией пользователей:

```dart
class AuthService {
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  
  Future<AppUser?> signInWithGoogle();
  Future<void> signOut();
  Stream<AppUser?> get currentUserStream;
}
```

#### BookingService
Управление бронированиями:

```dart
class BookingService {
  Future<Booking> createBooking(BookingRequest request);
  Future<List<Booking>> getUserBookings(String userId);
  Future<void> updateBookingStatus(String bookingId, BookingStatus status);
  Stream<List<Booking>> watchUserBookings(String userId);
}
```

#### ChatService
Система обмена сообщениями:

```dart
class ChatService {
  Future<Chat> createChat(String userId, String specialistId);
  Future<void> sendMessage(String chatId, ChatMessage message);
  Stream<List<ChatMessage>> watchChatMessages(String chatId);
  Future<void> markAsRead(String chatId, String messageId);
}
```

#### PaymentService
Обработка платежей:

```dart
class PaymentService {
  Future<Payment> createPayment(PaymentRequest request);
  Future<Payment> processPayment(String paymentId);
  Future<List<Payment>> getUserPayments(String userId);
  Future<void> refundPayment(String paymentId);
}
```

#### AnalyticsService
Сбор и анализ данных:

```dart
class AnalyticsService {
  Future<void> logEvent(String eventName, Map<String, dynamic> parameters);
  Future<void> setUserProperties(Map<String, dynamic> properties);
  Future<AnalyticsData> getAnalyticsData(DateTimeRange range);
}
```

### 3. Data Layer (Models & Firebase)

#### Models (94 файла)
Модели данных с валидацией и сериализацией:

```dart
class Specialist {
  final String id;
  final String userId;
  final String name;
  final SpecialistCategory category;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Методы сериализации
  Map<String, dynamic> toMap();
  factory Specialist.fromMap(Map<String, dynamic> map);
  factory Specialist.fromDocument(DocumentSnapshot doc);
}
```

#### Firebase Integration

**Firestore Collections:**
- `users` — пользователи системы
- `specialists` — профили специалистов
- `bookings` — бронирования
- `chats` — чаты между пользователями
- `messages` — сообщения в чатах
- `reviews` — отзывы о специалистах
- `payments` — платежи
- `notifications` — уведомления
- `analytics` — аналитические данные

**Firebase Storage:**
- `profile_images/` — аватары пользователей
- `portfolio/` — портфолио специалистов
- `documents/` — документы и контракты

**Firebase Functions:**
- `processPayment` — обработка платежей
- `sendNotification` — отправка уведомлений
- `generateReport` — генерация отчетов
- `moderateContent` — модерация контента

## 🔄 Потоки данных

### 1. Поток аутентификации

```
User Input → AuthService → Firebase Auth → Firestore → AppUser Model → UI Update
```

### 2. Поток бронирования

```
User Input → BookingForm → BookingService → Firestore → NotificationService → UI Update
```

### 3. Поток чата

```
User Input → ChatService → Firestore → Real-time Updates → UI Update
```

### 4. Поток платежей

```
User Input → PaymentService → Firebase Functions → External Payment Gateway → Firestore → UI Update
```

## 🎨 UI/UX Архитектура

### Design System

#### Цветовая схема
```dart
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFB00020);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F5F5);
}
```

#### Типографика
```dart
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.onBackground,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.onBackground,
  );
}
```

#### Компоненты
- **Material Design 3** — современный дизайн
- **Responsive Design** — адаптация под разные экраны
- **Dark Mode** — поддержка темной темы
- **Accessibility** — доступность для всех пользователей

### Навигация

Используется GoRouter для декларативной навигации:

```dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => HomeScreen(),
    ),
    GoRoute(
      path: '/specialist/:id',
      builder: (context, state) {
        final specialistId = state.pathParameters['id'];
        return SpecialistProfileScreen(specialistId: specialistId);
      },
    ),
  ],
);
```

## 🔒 Безопасность

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Пользователи могут читать/писать только свои данные
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Специалисты видят только свои профили
    match /specialists/{specialistId} {
      allow read, write: if request.auth != null && request.auth.uid == specialistId;
      allow read: if request.auth != null; // Все могут читать профили
    }
  }
}
```

### Аутентификация

- **Firebase Auth** — надежная система аутентификации
- **JWT токены** — безопасная передача данных
- **Role-based access** — контроль доступа по ролям
- **Session management** — управление сессиями

## 📊 Производительность

### Оптимизации

#### Кэширование
```dart
class CacheService {
  static const Duration defaultExpiration = Duration(minutes: 5);
  
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value, {Duration? expiration});
  Future<void> clear();
}
```

#### Ленивая загрузка
```dart
class LazyListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        // Загружаем элементы по мере прокрутки
        return FutureBuilder<Specialist>(
          future: loadSpecialist(index),
          builder: (context, snapshot) {
            return snapshot.hasData 
              ? SpecialistCard(specialist: snapshot.data!)
              : LoadingCard();
          },
        );
      },
    );
  }
}
```

#### Оптимизация изображений
```dart
class ImageOptimizationService {
  Future<String> optimizeImage(File imageFile) async {
    // Сжатие изображения
    final compressedImage = await compressImage(imageFile);
    
    // Загрузка в Firebase Storage
    final downloadUrl = await uploadToStorage(compressedImage);
    
    return downloadUrl;
  }
}
```

## 🧪 Тестирование

### Архитектура тестов

```
test/
├── unit/              # Unit тесты
│   ├── services/      # Тесты сервисов
│   ├── models/        # Тесты моделей
│   └── utils/         # Тесты утилит
├── widget/            # Widget тесты
│   ├── screens/       # Тесты экранов
│   └── widgets/       # Тесты виджетов
└── integration/       # Интеграционные тесты
    ├── auth_flow/     # Тесты аутентификации
    ├── booking_flow/  # Тесты бронирования
    └── payment_flow/  # Тесты платежей
```

### Примеры тестов

#### Unit тест сервиса
```dart
void main() {
  group('AuthService', () {
    late AuthService authService;
    
    setUp(() {
      authService = AuthService();
    });
    
    test('should sign in with valid credentials', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      
      // Act
      final result = await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Assert
      expect(result, isNotNull);
      expect(result!.email, equals(email));
    });
  });
}
```

#### Widget тест
```dart
void main() {
  group('SpecialistCard', () {
    testWidgets('should display specialist information', (tester) async {
      // Arrange
      final specialist = Specialist(
        id: '1',
        name: 'John Doe',
        category: SpecialistCategory.photographer,
        hourlyRate: 5000,
        rating: 4.5,
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SpecialistCard(specialist: specialist),
        ),
      );
      
      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Фотограф'), findsOneWidget);
      expect(find.text('5000 ₽/час'), findsOneWidget);
    });
  });
}
```

## 🔄 State Management с Riverpod

### Провайдеры

#### StateProvider
Для простого состояния:
```dart
final currentUserProvider = StateProvider<AppUser?>((ref) => null);
```

#### StateNotifierProvider
Для сложного состояния:
```dart
class SpecialistNotifier extends StateNotifier<AsyncValue<List<Specialist>>> {
  SpecialistNotifier(this._service) : super(const AsyncValue.loading());
  
  final SpecialistService _service;
  
  Future<void> loadSpecialists() async {
    state = const AsyncValue.loading();
    try {
      final specialists = await _service.getSpecialists();
      state = AsyncValue.data(specialists);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final specialistProvider = StateNotifierProvider<SpecialistNotifier, AsyncValue<List<Specialist>>>(
  (ref) => SpecialistNotifier(ref.watch(specialistServiceProvider)),
);
```

#### StreamProvider
Для потоков данных:
```dart
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.watchChatMessages(chatId);
});
```

### Зависимости

```dart
// Сервисы
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final specialistServiceProvider = Provider<SpecialistService>((ref) => SpecialistService());

// Репозитории
final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

// Утилиты
final loggerProvider = Provider<Logger>((ref) => Logger());
```

## 🌐 Сетевая архитектура

### HTTP клиент
```dart
class ApiClient {
  final Dio _dio;
  
  ApiClient() : _dio = Dio() {
    _dio.options.baseUrl = 'https://api.eventmarketplace.app';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    _dio.interceptors.addAll([
      AuthInterceptor(),
      LogInterceptor(),
      ErrorInterceptor(),
    ]);
  }
}
```

### Обработка ошибок
```dart
class ErrorHandler {
  static String handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Время соединения истекло';
        case DioExceptionType.receiveTimeout:
          return 'Время получения данных истекло';
        case DioExceptionType.badResponse:
          return 'Ошибка сервера: ${error.response?.statusCode}';
        default:
          return 'Ошибка сети';
      }
    }
    return 'Неизвестная ошибка';
  }
}
```

## 📱 Платформо-специфичный код

### Android
```dart
// android/app/src/main/kotlin/MainActivity.kt
class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Android-специфичная инициализация
        FirebaseMessaging.getInstance().isAutoInitEnabled = true
    }
}
```

### iOS
```dart
// ios/Runner/AppDelegate.swift
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // iOS-специфичная инициализация
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

### Web
```dart
// web/index.html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Event Marketplace</title>
    <script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-app.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-firestore.js"></script>
</head>
<body>
    <div id="loading">Loading...</div>
    <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
```

## 🔧 Конфигурация и настройки

### Environment Configuration
```dart
class EnvironmentConfig {
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  static const String apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://api.eventmarketplace.app');
  static const bool enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: true);
  static const bool enableCrashlytics = bool.fromEnvironment('ENABLE_CRASHLYTICS', defaultValue: true);
}
```

### Feature Flags
```dart
class FeatureFlags {
  static const bool enableNewBookingFlow = true;
  static const bool enableVideoChat = false;
  static const bool enableARPreview = false;
  static const bool enableAdvancedAnalytics = true;
}
```

## 📈 Мониторинг и логирование

### Логирование
```dart
class AppLogger {
  static void logI(String message, String tag) {
    if (kDebugMode) {
      print('[$tag] INFO: $message');
    }
  }
  
  static void logE(String message, String tag, dynamic error) {
    if (kDebugMode) {
      print('[$tag] ERROR: $message - $error');
    }
    
    // Отправка в Crashlytics
    FirebaseCrashlytics.instance.recordError(error, null);
  }
}
```

### Метрики производительности
```dart
class PerformanceService {
  static Future<T> measureTime<T>(String operation, Future<T> Function() function) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await function();
      stopwatch.stop();
      
      // Отправка метрики
      FirebasePerformance.instance
          .newTrace(operation)
          .putMetric('duration_ms', stopwatch.elapsedMilliseconds)
          .start()
          .stop();
      
      return result;
    } catch (e) {
      stopwatch.stop();
      rethrow;
    }
  }
}
```

## 🚀 Масштабирование

### Горизонтальное масштабирование
- **Firebase Auto-scaling** — автоматическое масштабирование серверов
- **CDN** — распределение контента по регионам
- **Load Balancing** — балансировка нагрузки

### Вертикальное масштабирование
- **Database Sharding** — разделение данных по регионам России
- **Caching Strategy** — многоуровневое кэширование
- **Resource Optimization** — оптимизация использования ресурсов

## 🔮 Будущие улучшения

### Планируемые функции
- **AI-рекомендации** — умные рекомендации специалистов
- **AR-превью** — предварительный просмотр услуг в AR
- **Blockchain** — интеграция с блокчейн для контрактов
- **IoT Integration** — интеграция с IoT устройствами

### Архитектурные улучшения
- **Microservices** — переход на микросервисную архитектуру
- **GraphQL** — внедрение GraphQL API
- **Event Sourcing** — событийно-ориентированная архитектура
- **CQRS** — разделение команд и запросов

---

Эта архитектура обеспечивает высокую производительность, масштабируемость и поддерживаемость приложения Event Marketplace, покрывающего всю территорию России.