import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';
import '../models/analytics.dart';

/// Провайдер сервиса аналитики
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Провайдер аналитики специалиста
final specialistAnalyticsProvider = FutureProvider.family<SpecialistAnalytics?, String>((ref, specialistId) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.getSpecialistAnalytics(specialistId);
});

/// Провайдер месячной статистики
final monthlyStatsProvider = FutureProvider.family<List<MonthlyStat>, String>((ref, specialistId) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.getMonthlyStats(specialistId);
});

/// Провайдер топ услуг
final topServicesProvider = FutureProvider.family<List<ServiceStat>, String>((ref, specialistId) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.getTopServices(specialistId);
});

/// Провайдер сравнения с предыдущим периодом
final comparisonProvider = FutureProvider.family<Map<String, double>, String>((ref, specialistId) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.getComparisonWithPreviousPeriod(specialistId);
});