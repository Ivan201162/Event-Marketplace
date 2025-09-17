import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Сервис аналитики
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Инициализация аналитики
  Future<void> initialize() async {
    if (kDebugMode) {
      await _analytics.setAnalyticsCollectionEnabled(false);
    } else {
      await _analytics.setAnalyticsCollectionEnabled(true);
    }
  }

  /// Отслеживание события
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Отслеживание экрана
  Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', parameters: {'screen_name': screenName});
  }

  /// Отслеживание пользователя
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Отслеживание свойств пользователя
  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}
