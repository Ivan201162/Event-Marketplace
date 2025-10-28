import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/core/safe_log.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Типы событий аналитики
enum AnalyticsEventType {
  // Аутентификация
  userSignUp,
  userSignIn,
  userSignOut,
  passwordReset,

  // События
  eventCreated,
  eventViewed,
  eventEdited,
  eventDeleted,
  eventBooked,
  eventCancelled,

  // Поиск и фильтрация
  searchPerformed,
  filterApplied,
  categorySelected,

  // Профиль
  profileViewed,
  profileEdited,
  photoUploaded,

  // Чат
  messageSent,
  attachmentUploaded,
  chatOpened,

  // Платежи
  paymentInitiated,
  paymentCompleted,
  paymentFailed,

  // Навигация
  screenViewed,
  buttonClicked,
  menuOpened,

  // Ошибки
  errorOccurred,
  crashReported,

  // Производительность
  apiCallMade,
  apiCallFailed,
  slowOperation,

  // Пользовательские события
  customEvent,
}

/// Параметры события аналитики
class AnalyticsEvent {
  const AnalyticsEvent({
    required this.type,
    required this.timestamp, this.parameters = const {},
    this.userId,
    this.sessionId,
  });
  final AnalyticsEventType type;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;

  /// Преобразовать в параметры Firebase Analytics
  Map<String, dynamic> toFirebaseParameters() {
    final firebaseParams = <String, dynamic>{
      'event_type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      ...parameters,
    };

    if (userId != null) {
      firebaseParams['user_id'] = userId;
    }

    if (sessionId != null) {
      firebaseParams['session_id'] = sessionId;
    }

    return firebaseParams;
  }

  @override
  String toString() =>
      'AnalyticsEvent(type: ${type.name}, parameters: $parameters, timestamp: $timestamp)';
}

/// Сервис аналитики
class AnalyticsService {
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();
  static final AnalyticsService _instance = AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;
  String? _currentUserId;
  String? _currentSessionId;

  /// Инициализация сервиса аналитики
  Future<void> initialize() async {
    if (!FeatureFlags.analyticsEnabled) {
      SafeLog.info('AnalyticsService: Analytics disabled via feature flag');
      return;
    }

    try {
      _analytics = FirebaseAnalytics.instance;
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _isInitialized = true;

      SafeLog.info('AnalyticsService: Initialized successfully');
    } catch (e, stackTrace) {
      SafeLog.error('AnalyticsService: Error initializing', e, stackTrace);
      _isInitialized = false;
    }
  }

  /// Проверить, доступна ли аналитика
  bool get isAvailable =>
      FeatureFlags.analyticsEnabled && _isInitialized && _analytics != null;

  /// Установить пользователя
  Future<void> setUserId(String userId) async {
    if (!isAvailable) {
      SafeLog.info('AnalyticsService: setUserId called but analytics disabled');
      return;
    }

    try {
      _currentUserId = userId;
      await _analytics!.setUserId(id: userId);
      SafeLog.info('AnalyticsService: User ID set to $userId');
    } catch (e, stackTrace) {
      SafeLog.error('AnalyticsService: Error setting user ID', e, stackTrace);
    }
  }

  /// Очистить пользователя
  Future<void> clearUserId() async {
    if (!isAvailable) {
      SafeLog.info(
          'AnalyticsService: clearUserId called but analytics disabled',);
      return;
    }

    try {
      _currentUserId = null;
      await _analytics!.setUserId();
      SafeLog.info('AnalyticsService: User ID cleared');
    } catch (e, stackTrace) {
      SafeLog.error('AnalyticsService: Error clearing user ID', e, stackTrace);
    }
  }

  /// Установить свойства пользователя
  Future<void> setUserProperties(Map<String, String> properties) async {
    if (!isAvailable) {
      SafeLog.info(
          'AnalyticsService: setUserProperties called but analytics disabled',);
      return;
    }

    try {
      for (final entry in properties.entries) {
        await _analytics!.setUserProperty(name: entry.key, value: entry.value);
      }
      SafeLog.info('AnalyticsService: User properties set: $properties');
    } catch (e, stackTrace) {
      SafeLog.error(
          'AnalyticsService: Error setting user properties', e, stackTrace,);
    }
  }

  /// Отправить событие
  Future<void> logEvent(AnalyticsEvent event) async {
    if (!isAvailable) {
      SafeLog.info(
          'AnalyticsService: logEvent called but analytics disabled: ${event.type.name}',);
      return;
    }

    try {
      // Преобразуем параметры для Firebase Analytics
      final firebaseParams = _convertToFirebaseParams(event.parameters);

      await _analytics!.logEvent(
        name: event.type.name,
        parameters: firebaseParams.cast<String, Object>(),
      );

      SafeLog.info('AnalyticsService: Event logged: ${event.type.name}');
    } catch (e, stackTrace) {
      SafeLog.error('AnalyticsService: Error logging event', e, stackTrace);
    }
  }

  /// Отправить событие с параметрами
  Future<void> logEventWithParams(
      AnalyticsEventType type, Map<String, dynamic> parameters,) async {
    final event = AnalyticsEvent(
      type: type,
      parameters: parameters,
      timestamp: DateTime.now(),
      userId: _currentUserId,
      sessionId: _currentSessionId,
    );

    await logEvent(event);
  }

  /// Отправить простое событие
  Future<void> logSimpleEvent(AnalyticsEventType type) async {
    await logEventWithParams(type, {});
  }

  /// Отправить событие просмотра экрана
  Future<void> logScreenView(String screenName,
      {Map<String, dynamic>? parameters,}) async {
    if (!isAvailable) {
      SafeLog.info(
          'AnalyticsService: logScreenView called but analytics disabled: $screenName',);
      return;
    }

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenName,
        parameters: parameters?.cast<String, Object>(),
      );

      SafeLog.info('AnalyticsService: Screen view logged: $screenName');
    } catch (e, stackTrace) {
      SafeLog.error(
          'AnalyticsService: Error logging screen view', e, stackTrace,);
    }
  }

  /// Отправить событие покупки
  Future<void> logPurchase({
    required String transactionId,
    required String currency,
    required double value,
    Map<String, dynamic>? parameters,
  }) async {
    if (!isAvailable) {
      SafeLog.info(
          'AnalyticsService: logPurchase called but analytics disabled',);
      return;
    }

    try {
      await _analytics!.logPurchase(
        transactionId: transactionId,
        currency: currency,
        value: value,
        parameters: parameters?.cast<String, Object>(),
      );

      SafeLog.info('AnalyticsService: Purchase logged: $transactionId');
    } catch (e, stackTrace) {
      SafeLog.error('AnalyticsService: Error logging purchase', e, stackTrace);
    }
  }

  /// Отправить событие поиска
  Future<void> logSearch(
      {required String searchTerm, Map<String, dynamic>? parameters,}) async {
    if (!isAvailable) {
      SafeLog.info(
          'AnalyticsService: logSearch called but analytics disabled: $searchTerm',);
      return;
    }

    try {
      await _analytics!.logSearch(
        searchTerm: searchTerm,
        parameters: parameters?.cast<String, Object>(),
      );

      SafeLog.info('AnalyticsService: Search logged: $searchTerm');
    } catch (e, stackTrace) {
      SafeLog.error('AnalyticsService: Error logging search', e, stackTrace);
    }
  }

  /// Отправить событие ошибки
  Future<void> logError({
    required String error,
    required String description,
    Map<String, dynamic>? parameters,
  }) async {
    await logEventWithParams(AnalyticsEventType.errorOccurred, {
      'error': error,
      'description': description,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?parameters,
    });
  }

  /// Отправить событие производительности
  Future<void> logPerformance({
    required String operation,
    required int durationMs,
    Map<String, dynamic>? parameters,
  }) async {
    await logEventWithParams(AnalyticsEventType.slowOperation, {
      'operation': operation,
      'duration_ms': durationMs,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?parameters,
    });
  }

  /// Отправить событие API вызова
  Future<void> logApiCall({
    required String endpoint,
    required String method,
    required int statusCode,
    required int durationMs,
    Map<String, dynamic>? parameters,
  }) async {
    final eventType = statusCode >= 200 && statusCode < 300
        ? AnalyticsEventType.apiCallMade
        : AnalyticsEventType.apiCallFailed;

    await logEventWithParams(eventType, {
      'endpoint': endpoint,
      'method': method,
      'status_code': statusCode,
      'duration_ms': durationMs,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?parameters,
    });
  }

  /// Отправить событие аутентификации
  Future<void> logAuthEvent(AnalyticsEventType type,
      {Map<String, dynamic>? parameters,}) async {
    await logEventWithParams(type, parameters ?? {});
  }

  /// Отправить событие события (мероприятия)
  Future<void> logEventEvent(
    AnalyticsEventType type, {
    required String eventId,
    String? eventTitle,
    Map<String, dynamic>? parameters,
  }) async {
    await logEventWithParams(type, {
      'event_id': eventId,
      'event_title': eventTitle,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?parameters,
    });
  }

  /// Отправить событие чата
  Future<void> logChatEvent(
    AnalyticsEventType type, {
    required String chatId,
    String? messageType,
    Map<String, dynamic>? parameters,
  }) async {
    await logEventWithParams(type, {
      'chat_id': chatId,
      'message_type': messageType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?parameters,
    });
  }

  /// Отправить событие платежа
  Future<void> logPaymentEvent(
    AnalyticsEventType type, {
    required String paymentId,
    required double amount,
    required String currency,
    String? paymentMethod,
    Map<String, dynamic>? parameters,
  }) async {
    await logEventWithParams(type, {
      'payment_id': paymentId,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?parameters,
    });
  }

  /// Отправить событие навигации
  Future<void> logNavigationEvent({
    required String fromScreen,
    required String toScreen,
    String? action,
    Map<String, dynamic>? parameters,
  }) async {
    await logEventWithParams(AnalyticsEventType.screenViewed, {
      'from_screen': fromScreen,
      'to_screen': toScreen,
      'action': action,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?parameters,
    });
  }

  /// Отправить пользовательское событие
  Future<void> logCustomEvent(
      {required String eventName, Map<String, dynamic>? parameters,}) async {
    await logEventWithParams(AnalyticsEventType.customEvent, {
      'custom_event_name': eventName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?parameters,
    });
  }

  /// Получить текущий ID сессии
  String? get currentSessionId => _currentSessionId;

  /// Получить текущий ID пользователя
  String? get currentUserId => _currentUserId;

  /// Преобразовать параметры для Firebase Analytics
  Map<String, dynamic> _convertToFirebaseParams(
      Map<String, dynamic> parameters,) {
    final converted = <String, dynamic>{};

    for (final entry in parameters.entries) {
      final key = entry.key;
      final value = entry.value;

      // Firebase Analytics имеет ограничения на типы параметров
      if (value is String || value is int || value is double || value is bool) {
        converted[key] = value;
      } else if (value is List) {
        // Преобразуем списки в строки
        converted[key] = value.join(',');
      } else {
        // Преобразуем все остальное в строки
        converted[key] = value.toString();
      }
    }

    return converted;
  }

  /// Очистить ресурсы
  void dispose() {
    _analytics = null;
    _isInitialized = false;
    _currentUserId = null;
    _currentSessionId = null;
    SafeLog.info('AnalyticsService: Disposed');
  }
}
