import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/price_reminder_service.dart';

/// Провайдер для сервиса напоминаний о ценах
final priceReminderServiceProvider = Provider<PriceReminderService>(
  (ref) => PriceReminderService(),
);

/// Провайдер для статистики напоминаний
final priceReminderStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = ref.read(priceReminderServiceProvider);
  return service.getReminderStats();
});

/// Провайдер для списка специалистов с устаревшими ценами
final specialistsWithOutdatedPricesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.read(priceReminderServiceProvider);
  return service.getSpecialistsWithOutdatedPrices();
});

/// Провайдер для специалистов, которым нужно напомнить об обновлении цен
final specialistsNeedingPriceUpdateProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.read(priceReminderServiceProvider);
  final specialists = await service.getSpecialistsNeedingPriceUpdate();

  return specialists
      .map(
        (specialist) => {
          'id': specialist.id,
          'name': specialist.name,
          'email': specialist.email,
          'lastPriceUpdateAt': specialist.lastPriceUpdateAt,
          'daysSinceUpdate': specialist.lastPriceUpdateAt != null
              ? DateTime.now().difference(specialist.lastPriceUpdateAt!).inDays
              : null,
        },
      )
      .toList();
});
