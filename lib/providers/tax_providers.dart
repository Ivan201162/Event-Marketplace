import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tax_info.dart';
import '../services/tax_service.dart';

/// Провайдер для TaxService
final taxServiceProvider = Provider<TaxService>((ref) => TaxService());

/// Провайдер для получения налоговой информации специалиста
final taxInfoProvider =
    FutureProvider.family<List<TaxInfo>, String>((ref, specialistId) async {
  final taxService = ref.read(taxServiceProvider);
  return taxService.getTaxInfoForSpecialist(specialistId);
});

/// Провайдер для получения налоговой статистики специалиста
final taxStatisticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  specialistId,
) async {
  final taxService = ref.read(taxServiceProvider);
  return taxService.getTaxStatistics(specialistId);
});

/// Провайдер для получения налоговой сводки за период
final taxSummaryProvider =
    FutureProvider.family<TaxSummary, ({String specialistId, String period})>(
        (ref, params) async {
  final taxService = ref.read(taxServiceProvider);
  return taxService.getTaxSummary(
      specialistId: params.specialistId, period: params.period);
});

/// Провайдер для получения напоминаний о налогах
final taxRemindersProvider = FutureProvider<List<TaxInfo>>((ref) async {
  final taxService = ref.read(taxServiceProvider);
  return taxService.getTaxReminders();
});

/// Провайдер для типов налогообложения
final taxTypesProvider = Provider<List<TaxType>>((ref) => TaxType.values);

/// Провайдер для текущего выбранного типа налогообложения
final selectedTaxTypeProvider = StateProvider<TaxType?>((ref) => null);

/// Провайдер для расчёта налога
final taxCalculationProvider = FutureProvider.family<
    TaxInfo,
    ({
      String userId,
      String specialistId,
      TaxType taxType,
      double income,
      String period
    })>((ref, params) async {
  final taxService = ref.read(taxServiceProvider);
  return taxService.calculateTax(
    userId: params.userId,
    specialistId: params.specialistId,
    taxType: params.taxType,
    income: params.income,
    period: params.period,
  );
});
