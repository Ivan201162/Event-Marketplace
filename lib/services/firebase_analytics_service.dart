import 'package:firebase_analytics/firebase_analytics.dart';

import '../core/logger.dart';

/// Сервис для работы с Firebase Analytics
class FirebaseAnalyticsService {
  factory FirebaseAnalyticsService() => _instance;
  FirebaseAnalyticsService._internal();
  static final FirebaseAnalyticsService _instance = FirebaseAnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Инициализация аналитики
  Future<void> initialize() async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      AppLogger.logI('Firebase Analytics инициализирован', 'firebase_analytics_service');
    } catch (e) {
      AppLogger.logE('Ошибка инициализации Firebase Analytics: $e', 'firebase_analytics_service');
    }
  }

  /// Установить пользовательские свойства
  Future<void> setUserProperties({
    required String userId,
    String? userType,
    String? userRole,
    String? location,
    String? language,
  }) async {
    try {
      await _analytics.setUserId(id: userId);
      
      if (userType != null) {
        await _analytics.setUserProperty(name: 'user_type', value: userType);
      }
      if (userRole != null) {
        await _analytics.setUserProperty(name: 'user_role', value: userRole);
      }
      if (location != null) {
        await _analytics.setUserProperty(name: 'location', value: location);
      }
      if (language != null) {
        await _analytics.setUserProperty(name: 'language', value: language);
      }

      AppLogger.logI('Пользовательские свойства установлены для $userId', 'firebase_analytics_service');
    } catch (e) {
      AppLogger.logE('Ошибка установки пользовательских свойств: $e', 'firebase_analytics_service');
    }
  }

  /// Отслеживание просмотра экрана
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
        parameters: parameters?.cast<String, Object>(),
      );
      AppLogger.logI('Просмотр экрана: $screenName', 'firebase_analytics_service');
    } catch (e) {
      AppLogger.logE('Ошибка логирования просмотра экрана: $e', 'firebase_analytics_service');
    }
  }

  /// Отслеживание события
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters?.cast<String, Object>());
      AppLogger.logI('Событие: $name', 'firebase_analytics_service');
    } catch (e) {
      AppLogger.logE('Ошибка логирования события: $e', 'firebase_analytics_service');
    }
  }

  // === СОБЫТИЯ ПОЛЬЗОВАТЕЛЕЙ ===

  /// Регистрация пользователя
  Future<void> logUserRegistration({
    required String method,
    String? userId,
  }) async {
    await logEvent(
      name: 'user_registration',
      parameters: {
        'method': method,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  /// Вход пользователя
  Future<void> logUserLogin({
    required String method,
    String? userId,
  }) async {
    await logEvent(
      name: 'user_login',
      parameters: {
        'method': method,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  /// Выход пользователя
  Future<void> logUserLogout() async {
    await logEvent(name: 'user_logout');
  }

  // === СОБЫТИЯ СПЕЦИАЛИСТОВ ===

  /// Просмотр профиля специалиста
  Future<void> logSpecialistProfileView({
    required String specialistId,
    required String specialistCategory,
    String? source,
  }) async {
    await logEvent(
      name: 'specialist_profile_view',
      parameters: {
        'specialist_id': specialistId,
        'specialist_category': specialistCategory,
        if (source != null) 'source': source,
      },
    );
  }

  /// Создание заявки
  Future<void> logBookingCreated({
    required String bookingId,
    required String specialistId,
    required String customerId,
    required String category,
    double? amount,
    DateTime? eventDate,
  }) async {
    await logEvent(
      name: 'booking_created',
      parameters: {
        'booking_id': bookingId,
        'specialist_id': specialistId,
        'customer_id': customerId,
        'category': category,
        if (amount != null) 'amount': amount,
        if (eventDate != null) 'event_date': eventDate.toIso8601String(),
      },
    );
  }

  /// Принятие заявки
  Future<void> logBookingAccepted({
    required String bookingId,
    required String specialistId,
  }) async {
    await logEvent(
      name: 'booking_accepted',
      parameters: {
        'booking_id': bookingId,
        'specialist_id': specialistId,
      },
    );
  }

  /// Отклонение заявки
  Future<void> logBookingRejected({
    required String bookingId,
    required String specialistId,
    String? reason,
  }) async {
    await logEvent(
      name: 'booking_rejected',
      parameters: {
        'booking_id': bookingId,
        'specialist_id': specialistId,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Завершение заявки
  Future<void> logBookingCompleted({
    required String bookingId,
    required String specialistId,
    required String customerId,
    double? amount,
  }) async {
    await logEvent(
      name: 'booking_completed',
      parameters: {
        'booking_id': bookingId,
        'specialist_id': specialistId,
        'customer_id': customerId,
        if (amount != null) 'amount': amount,
      },
    );
  }

  /// Отмена заявки
  Future<void> logBookingCancelled({
    required String bookingId,
    required String specialistId,
    required String customerId,
    String? reason,
  }) async {
    await logEvent(
      name: 'booking_cancelled',
      parameters: {
        'booking_id': bookingId,
        'specialist_id': specialistId,
        'customer_id': customerId,
        if (reason != null) 'reason': reason,
      },
    );
  }

  // === СОБЫТИЯ ПЛАТЕЖЕЙ ===

  /// Инициация платежа
  Future<void> logPaymentInitiated({
    required String paymentId,
    required String bookingId,
    required double amount,
    required String method,
    String? currency,
  }) async {
    await logEvent(
      name: 'payment_initiated',
      parameters: {
        'payment_id': paymentId,
        'booking_id': bookingId,
        'amount': amount,
        'method': method,
        if (currency != null) 'currency': currency,
      },
    );
  }

  /// Успешный платеж
  Future<void> logPaymentCompleted({
    required String paymentId,
    required String bookingId,
    required double amount,
    required String method,
    String? currency,
  }) async {
    await logEvent(
      name: 'payment_completed',
      parameters: {
        'payment_id': paymentId,
        'booking_id': bookingId,
        'amount': amount,
        'method': method,
        if (currency != null) 'currency': currency,
      },
    );
  }

  /// Неудачный платеж
  Future<void> logPaymentFailed({
    required String paymentId,
    required String bookingId,
    required double amount,
    required String method,
    String? error,
  }) async {
    await logEvent(
      name: 'payment_failed',
      parameters: {
        'payment_id': paymentId,
        'booking_id': bookingId,
        'amount': amount,
        'method': method,
        if (error != null) 'error': error,
      },
    );
  }

  // === СОБЫТИЯ РЕКОМЕНДАЦИЙ ===

  /// Просмотр рекомендаций
  Future<void> logRecommendationsViewed({
    required String userId,
    required String type,
    int? count,
  }) async {
    await logEvent(
      name: 'recommendations_viewed',
      parameters: {
        'user_id': userId,
        'type': type,
        if (count != null) 'count': count,
      },
    );
  }

  /// Клик по рекомендации
  Future<void> logRecommendationClicked({
    required String userId,
    required String recommendationId,
    required String type,
    String? specialistId,
  }) async {
    await logEvent(
      name: 'recommendation_clicked',
      parameters: {
        'user_id': userId,
        'recommendation_id': recommendationId,
        'type': type,
        if (specialistId != null) 'specialist_id': specialistId,
      },
    );
  }

  /// Принятие рекомендации
  Future<void> logRecommendationAccepted({
    required String userId,
    required String recommendationId,
    required String type,
    String? specialistId,
  }) async {
    await logEvent(
      name: 'recommendation_accepted',
      parameters: {
        'user_id': userId,
        'recommendation_id': recommendationId,
        'type': type,
        if (specialistId != null) 'specialist_id': specialistId,
      },
    );
  }

  // === СОБЫТИЯ КАЛЕНДАРЯ ===

  /// Создание события в календаре
  Future<void> logCalendarEventCreated({
    required String userId,
    required String eventType,
    bool isRecurring = false,
  }) async {
    await logEvent(
      name: 'calendar_event_created',
      parameters: {
        'user_id': userId,
        'event_type': eventType,
        'is_recurring': isRecurring,
      },
    );
  }

  /// Просмотр календаря
  Future<void> logCalendarViewed({
    required String userId,
    required String view,
  }) async {
    await logEvent(
      name: 'calendar_viewed',
      parameters: {
        'user_id': userId,
        'view': view,
      },
    );
  }

  // === СОБЫТИЯ ОТЗЫВОВ ===

  /// Создание отзыва
  Future<void> logReviewCreated({
    required String reviewId,
    required String specialistId,
    required String customerId,
    required double rating,
    bool hasComment = false,
  }) async {
    await logEvent(
      name: 'review_created',
      parameters: {
        'review_id': reviewId,
        'specialist_id': specialistId,
        'customer_id': customerId,
        'rating': rating,
        'has_comment': hasComment,
      },
    );
  }

  /// Просмотр отзывов
  Future<void> logReviewsViewed({
    required String specialistId,
    int? count,
  }) async {
    await logEvent(
      name: 'reviews_viewed',
      parameters: {
        'specialist_id': specialistId,
        if (count != null) 'count': count,
      },
    );
  }

  // === СОБЫТИЯ ПОИСКА ===

  /// Поиск специалистов
  Future<void> logSpecialistSearch({
    required String query,
    String? category,
    String? location,
    int? resultsCount,
  }) async {
    await logEvent(
      name: 'specialist_search',
      parameters: {
        'query': query,
        if (category != null) 'category': category,
        if (location != null) 'location': location,
        if (resultsCount != null) 'results_count': resultsCount,
      },
    );
  }

  /// Фильтрация специалистов
  Future<void> logSpecialistFilter({
    required Map<String, dynamic> filters,
    int? resultsCount,
  }) async {
    await logEvent(
      name: 'specialist_filter',
      parameters: {
        ...filters,
        if (resultsCount != null) 'results_count': resultsCount,
      },
    );
  }

  // === СОБЫТИЯ ОШИБОК ===

  /// Ошибка приложения
  Future<void> logAppError({
    required String error,
    String? screen,
    String? action,
  }) async {
    await logEvent(
      name: 'app_error',
      parameters: {
        'error': error,
        if (screen != null) 'screen': screen,
        if (action != null) 'action': action,
      },
    );
  }

  /// Ошибка API
  Future<void> logApiError({
    required String endpoint,
    required int statusCode,
    String? error,
  }) async {
    await logEvent(
      name: 'api_error',
      parameters: {
        'endpoint': endpoint,
        'status_code': statusCode,
        if (error != null) 'error': error,
      },
    );
  }

  // === СОБЫТИЯ ПРОИЗВОДИТЕЛЬНОСТИ ===

  /// Время загрузки экрана
  Future<void> logScreenLoadTime({
    required String screenName,
    required int loadTimeMs,
  }) async {
    await logEvent(
      name: 'screen_load_time',
      parameters: {
        'screen_name': screenName,
        'load_time_ms': loadTimeMs,
      },
    );
  }

  /// Время ответа API
  Future<void> logApiResponseTime({
    required String endpoint,
    required int responseTimeMs,
  }) async {
    await logEvent(
      name: 'api_response_time',
      parameters: {
        'endpoint': endpoint,
        'response_time_ms': responseTimeMs,
      },
    );
  }

  // === УТИЛИТЫ ===

  /// Получить экземпляр Firebase Analytics
  FirebaseAnalytics get analytics => _analytics;

  /// Включить/выключить сбор аналитики
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
      AppLogger.logI('Сбор аналитики ${enabled ? 'включен' : 'выключен'}', 'firebase_analytics_service');
    } catch (e) {
      AppLogger.logE('Ошибка изменения настроек аналитики: $e', 'firebase_analytics_service');
    }
  }

  /// Сбросить данные аналитики
  Future<void> resetAnalyticsData() async {
    try {
      await _analytics.resetAnalyticsData();
      AppLogger.logI('Данные аналитики сброшены', 'firebase_analytics_service');
    } catch (e) {
      AppLogger.logE('Ошибка сброса данных аналитики: $e', 'firebase_analytics_service');
    }
  }
}
