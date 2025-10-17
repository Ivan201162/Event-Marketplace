import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/specialist_report_service.dart';

/// Провайдер сервиса отчетов
final specialistReportServiceProvider = Provider((ref) => SpecialistReportService());

/// Провайдер для получения общего отчета по специалистам
final specialistReportProvider = FutureProvider((ref) async {
  final reportService = ref.read(specialistReportServiceProvider);
  return reportService.generateSpecialistReport();
});

/// Провайдер для получения отчета по категориям
final categoryReportProvider = FutureProvider((ref) async {
  final reportService = ref.read(specialistReportServiceProvider);
  return reportService.generateCategoryReport();
});

/// Провайдер для получения отчета по рейтингам
final ratingReportProvider = FutureProvider((ref) async {
  final reportService = ref.read(specialistReportServiceProvider);
  return reportService.generateRatingReport();
});

/// Провайдер для получения отчета по доходам
final earningsReportProvider = FutureProvider((ref) async {
  final reportService = ref.read(specialistReportServiceProvider);
  return reportService.generateEarningsReport();
});

/// Провайдер для получения отчета по активности
final activityReportProvider = FutureProvider((ref) async {
  final reportService = ref.read(specialistReportServiceProvider);
  return reportService.generateActivityReport();
});

/// Провайдер для получения детального отчета по специалисту
final specialistDetailReportProvider =
    FutureProvider.family<SpecialistDetailReport, String>((ref, specialistId) async {
  final reportService = ref.read(specialistReportServiceProvider);
  return reportService.generateSpecialistDetailReport(specialistId);
});
