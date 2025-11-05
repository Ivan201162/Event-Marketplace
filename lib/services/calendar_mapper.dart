import 'package:event_marketplace_app/models/booking.dart';

/// Маппинг статусов бронирований в статусы календаря
class CalendarMapper {
  /// Определяет статус дня на основе списка бронирований
  /// Приоритет: accepted > pending > free
  static String getDayStatus(List<Booking> bookings) {
    if (bookings.isEmpty) return 'free';

    // Проверяем наличие accepted
    final hasAccepted = bookings.any((b) => b.status == BookingStatus.accepted);
    if (hasAccepted) return 'accepted';

    // Проверяем наличие pending
    final hasPending = bookings.any((b) => b.status == BookingStatus.pending);
    if (hasPending) return 'pending';

    return 'free';
  }

  /// Получает цвет для статуса
  static int getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return 0xFFFF0000; // Красный
      case 'pending':
        return 0xFFFFA500; // Оранжевый/жёлтый
      case 'free':
      default:
        return 0xFF00FF00; // Зелёный
    }
  }
}


