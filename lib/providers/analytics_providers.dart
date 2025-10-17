import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../analytics/analytics_service.dart';
import '../core/feature_flags.dart';

/// Провайдер сервиса аналитики
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService());

/// Провайдер для проверки доступности аналитики
final analyticsAvailableProvider = Provider<bool>((ref) => FeatureFlags.analyticsEnabled);

/// Провайдер для инициализации аналитики
final analyticsInitializationProvider = FutureProvider<void>((ref) async {
  final analyticsService = ref.read(analyticsServiceProvider);
  await analyticsService.initialize();
});

/// Провайдер текущего ID пользователя в аналитике
final analyticsUserIdProvider = Provider<String?>((ref) {
  final analyticsService = ref.read(analyticsServiceProvider);
  return analyticsService.currentUserId;
});

/// Провайдер текущего ID сессии в аналитике
final analyticsSessionIdProvider = Provider<String?>((ref) {
  final analyticsService = ref.read(analyticsServiceProvider);
  return analyticsService.currentSessionId;
});
