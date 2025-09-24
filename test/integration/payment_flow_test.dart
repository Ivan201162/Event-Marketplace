import 'package:flutter_test/flutter_test.dart';
import 'package:event_marketplace_app/models/payment_models.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/models/event.dart';
import 'package:event_marketplace_app/services/payment_service.dart';

void main() {
  group('Payment Flow Integration Tests', () {
    late PaymentService paymentService;
    late Booking testBooking;

    setUp(() {
      paymentService = PaymentService();
      testBooking = Booking(
        id: 'test_booking_123',
        eventId: 'test_event_123',
        userId: 'customer_123',
        customerId: 'customer_123',
        specialistId: 'specialist_456',
        eventTitle: 'Тестовое мероприятие',
        eventDate: DateTime.now().add(const Duration(days: 30)),
        bookingDate: DateTime.now().add(const Duration(days: 30)),
        participantsCount: 50,
        totalPrice: 10000,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        organizerName: 'Тестовый организатор',
        userName: 'Тестовый пользователь',
      );
    });

    group('Payment Creation Tests', () {
      test('should create prepayment for booking', () async {
        final paymentId = await paymentService.createPayment(
          bookingId: testBooking.id,
          amount: 3000,
          type: PaymentType.prepayment,
          method: PaymentMethod.sbp,
          customerId: testBooking.customerId!,
          specialistId: testBooking.specialistId!,
          taxStatus: TaxStatus.none,
        );
        
        expect(paymentId, isNotEmpty);
        expect(paymentId, isA<String>());
      });

      test('should create postpayment for booking', () async {
        final paymentId = await paymentService.createPayment(
          bookingId: testBooking.id,
          amount: 7000,
          type: PaymentType.postpayment,
          method: PaymentMethod.yookassa,
          customerId: testBooking.customerId!,
          specialistId: testBooking.specialistId!,
          taxStatus: TaxStatus.none,
        );
        
        expect(paymentId, isNotEmpty);
        expect(paymentId, isA<String>());
      });
    });
  });
}