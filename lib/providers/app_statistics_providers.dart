import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_statistics_service.dart';

/// Провайдер для App Statistics Service
final appStatisticsServiceProvider = Provider<AppStatisticsService>((ref) {
  return AppStatisticsService();
});

/// Провайдер для статистики приложения
final appStatisticsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, DateTime?>>((ref, params) async {
  final service = ref.read(appStatisticsServiceProvider);
  return service.getAppStatistics(
    startDate: params['startDate'],
    endDate: params['endDate'],
  );
});

/// Провайдер для статистики дашборда
final dashboardStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(appStatisticsServiceProvider);
  return service.getDashboardStatistics();
});

/// Провайдер для сбора статистики в реальном времени
final realTimeStatisticsProvider = FutureProvider<void>((ref) async {
  final service = ref.read(appStatisticsServiceProvider);
  return service.collectRealTimeStatistics();
});
