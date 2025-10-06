import 'package:flutter_test/flutter_test.dart';
import '../models/booking.dart';

void main() {
  group('Discount System Tests', () {
    test('Booking model should handle discount fields correctly', () {
      // Создаем заявку без скидки
      final booking = Booking(
        id: 'test_booking_1',
        eventId: 'event_1',
        eventTitle: 'Test Event',
        userId: 'user_1',
        userName: 'Test User',
        status: BookingStatus.pending,
        bookingDate: DateTime.now(),
        eventDate: DateTime.now().add(const Duration(days: 30)),
        participantsCount: 50,
        totalPrice: 50000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Проверяем, что скидки нет
      expect(booking.hasDiscount, false);
      expect(booking.effectivePrice, 50000.0);
      expect(booking.discountAmount, 0.0);

      // Применяем скидку 10%
      final discountedBooking = booking.applyDiscount(10);

      // Проверяем результат
      expect(discountedBooking.hasDiscount, true);
      expect(discountedBooking.discount, 10.0);
      expect(discountedBooking.finalPrice, 45000.0);
      expect(discountedBooking.effectivePrice, 45000.0);
      expect(discountedBooking.discountAmount, 5000.0);
    });

    test('Discount calculation logic should work correctly', () {
      // Тест расчета скидки 10%
      final booking = Booking(
        id: 'test_booking_2',
        eventId: 'event_2',
        eventTitle: 'Test Event 2',
        userId: 'user_2',
        userName: 'Test User 2',
        status: BookingStatus.pending,
        bookingDate: DateTime.now(),
        eventDate: DateTime.now().add(const Duration(days: 30)),
        participantsCount: 50,
        totalPrice: 10000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final discountedBooking = booking.applyDiscount(10);

      expect(discountedBooking.discount, 10.0);
      expect(discountedBooking.finalPrice, 9000.0);
      expect(discountedBooking.discountAmount, 1000.0);
      expect(discountedBooking.effectivePrice, 9000.0);
    });

    test('Discount should not exceed 100%', () {
      final booking = Booking(
        id: 'test_booking_3',
        eventId: 'event_3',
        eventTitle: 'Test Event 3',
        userId: 'user_3',
        userName: 'Test User 3',
        status: BookingStatus.pending,
        bookingDate: DateTime.now(),
        eventDate: DateTime.now().add(const Duration(days: 30)),
        participantsCount: 10,
        totalPrice: 5000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final discountedBooking = booking.applyDiscount(150); // 150% скидка

      // Финальная цена не должна быть отрицательной
      expect(discountedBooking.finalPrice, greaterThanOrEqualTo(0.0));
    });
  });
}
