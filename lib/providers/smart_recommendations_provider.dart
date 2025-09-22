import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/smart_recommendations_service.dart';
import '../models/booking.dart';

/// Провайдер для сервиса умных рекомендаций
final smartRecommendationsServiceProvider = Provider<SmartRecommendationsService>((ref) => SmartRecommendationsService());

/// Провайдер для анализа бронирования и отправки рекомендаций
final bookingAnalysisProvider = FutureProvider.family<void, Booking>((ref, booking) async {
  final service = ref.read(smartRecommendationsServiceProvider);
  await service.analyzeBookingAndRecommend(booking);
});

/// Провайдер для ежедневной проверки напоминаний
final dailyRemindersProvider = FutureProvider<void>((ref) async {
  final service = ref.read(smartRecommendationsServiceProvider);
  await service.runDailyRemindersCheck();
});

/// Провайдер для отправки напоминания специалисту об обновлении цен
final priceUpdateReminderProvider = FutureProvider.family<void, String>((ref, specialistId) async {
  final service = ref.read(smartRecommendationsServiceProvider);
  await service.sendPriceUpdateReminderToSpecialist(specialistId);
});

/// Провайдер для уведомления о новой публикации от избранного специалиста
final favoriteSpecialistUpdateProvider = FutureProvider.family<void, Map<String, String>>((ref, params) async {
  final service = ref.read(smartRecommendationsServiceProvider);
  await service.notifyFavoriteSpecialistUpdate(
    params['customerId']!,
    params['specialistId']!,
  );
});

/// Провайдер для отправки уведомления о чате с учетом рабочего времени
final chatNotificationProvider = FutureProvider.family<void, Map<String, String>>((ref, params) async {
  final service = ref.read(smartRecommendationsServiceProvider);
  await service.sendChatNotificationRespectingHours(
    specialistId: params['specialistId']!,
    customerId: params['customerId']!,
    message: params['message']!,
  );
});

/// Провайдер для персонализированных рекомендаций
final personalizedRecommendationsProvider = FutureProvider.family<void, String>((ref, userId) async {
  final service = ref.read(smartRecommendationsServiceProvider);
  await service.sendPersonalizedRecommendations(userId);
});
