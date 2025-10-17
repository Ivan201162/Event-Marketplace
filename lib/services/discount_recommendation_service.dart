import '../models/booking.dart';
import '../services/notification_service.dart';

/// Сервис для автоматических рекомендаций по скидкам
class DiscountRecommendationService {
  DiscountRecommendationService(this._notificationService);
  final NotificationService _notificationService;

  /// Анализирует заявку и предлагает рекомендации по увеличению бюджета
  Future<List<String>> analyzeBookingAndSuggest(Booking booking) async {
    final suggestions = <String>[];

    // Проверяем количество участников
    if (booking.participantsCount < 10) {
      suggestions.add(
        'Для небольшого мероприятия (${booking.participantsCount} чел.) рассмотрите возможность добавления фотографа или видеографа для лучшего качества съемки.',
      );
    }

    // Проверяем стоимость
    if (booking.totalPrice < 10000) {
      suggestions.add(
        'При бюджете до 10,000₽ можно рассмотреть пакетные предложения с дополнительными услугами.',
      );
    }

    // Проверяем тип события
    if (booking.eventType != null) {
      switch (booking.eventType!.toLowerCase()) {
        case 'свадьба':
        case 'wedding':
          suggestions.add(
            'Для свадьбы рекомендуем полный пакет услуг: фотограф + видеограф + ведущий. Это обеспечит полное покрытие мероприятия.',
          );
          break;
        case 'корпоратив':
        case 'corporate':
          suggestions.add(
            'Для корпоративного мероприятия рассмотрите возможность добавления ведущего или DJ для создания атмосферы.',
          );
          break;
        case 'день рождения':
        case 'birthday':
          suggestions.add(
            'Для дня рождения можно добавить аниматора или ведущего для развлечения гостей.',
          );
          break;
      }
    }

    return suggestions;
  }

  /// Отправляет уведомление о предоставленной скидке
  Future<void> sendDiscountNotification(Booking booking) async {
    if (booking.hasDiscount) {
      await _notificationService.sendNotification(
        booking.customerId,
        '🎉 Вам предоставлена скидка!',
        'Специалист ${booking.specialistName ?? 'предоставил'} скидку ${booking.discount!.toInt()}% на ваше мероприятие. Экономия: ${booking.discountAmount.toInt()}₽',
      );
    }
  }

  /// Отправляет уведомление с рекомендациями по увеличению бюджета
  Future<void> sendBudgetRecommendation(
    Booking booking,
    List<String> suggestions,
  ) async {
    if (suggestions.isNotEmpty) {
      await _notificationService.sendNotification(
        booking.customerId,
        '💡 Рекомендации по вашему мероприятию',
        suggestions.first, // Отправляем первую рекомендацию
      );
    }
  }

  /// Проверяет, нужно ли предложить скидку на основе анализа заявки
  bool shouldOfferDiscount(Booking booking) {
    // Предлагаем скидку если:
    // 1. Заявка на большую сумму (>50000₽)
    // 2. Много участников (>50 чел.)
    // 3. Долгосрочное бронирование (>30 дней)

    final daysUntilEvent = booking.eventDate.difference(DateTime.now()).inDays;

    return booking.totalPrice > 50000 || booking.participantsCount > 50 || daysUntilEvent > 30;
  }

  /// Рассчитывает рекомендуемый размер скидки
  double calculateRecommendedDiscount(Booking booking) {
    var discount = 0;

    // Базовая скидка за объем
    if (booking.totalPrice > 100000) {
      discount += 15.0;
    } else if (booking.totalPrice > 50000) {
      discount += 10.0;
    } else if (booking.totalPrice > 20000) {
      discount += 5.0;
    }

    // Дополнительная скидка за количество участников
    if (booking.participantsCount > 100) {
      discount += 10.0;
    } else if (booking.participantsCount > 50) {
      discount += 5.0;
    }

    // Дополнительная скидка за раннее бронирование
    final daysUntilEvent = booking.eventDate.difference(DateTime.now()).inDays;
    if (daysUntilEvent > 60) {
      discount += 10.0;
    } else if (daysUntilEvent > 30) {
      discount += 5.0;
    }

    // Ограничиваем максимальную скидку 30%
    return discount.clamp(0.0, 30.0);
  }
}
