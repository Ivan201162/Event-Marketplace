import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/services/performance_service.dart';
import 'package:event_marketplace_app/services/logger_service.dart';
import 'package:event_marketplace_app/services/monitoring_service.dart';

/// Провайдер для PerformanceService
final performanceServiceProvider = Provider<PerformanceService>((ref) {
  return PerformanceService();
});

/// Провайдер для LoggerService
final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});

/// Провайдер для MonitoringService
final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  return MonitoringService();
});

/// Провайдер для статистики производительности
final performanceStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final performanceService = ref.watch(performanceServiceProvider);
  return performanceService.getPerformanceStats();
});

/// Провайдер для статистики кэша
final cacheStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final performanceService = ref.watch(performanceServiceProvider);
  return performanceService.getCacheStats();
});

/// Провайдер для статистики мониторинга
final monitoringStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final monitoringService = ref.watch(monitoringServiceProvider);
  return monitoringService.getOverallStats();
});


