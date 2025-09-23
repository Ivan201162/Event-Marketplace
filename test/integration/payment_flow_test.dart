import 'package:flutter_test/flutter_test.dart';
import 'package:event_marketplace_app/models/payment.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/services/payment_service.dart';

void main() {
  group('Payment Flow Integration Tests', () {
    late PaymentService paymentService;
    late Booking testBooking;

    setUp(() {
      paymentService = PaymentService();
      testBooking = Booking(
        id: 'test_booking_123',
        userId: 'customer_123',
        specialistId: 'specialist_456',
        eventTitle: 'Тестовое мероприятие',
        eventDate: DateTime.now().add(const Duration(days: 30)),
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

    group('Payment Configuration Tests', () {
      test('should create correct configuration for individual', () {
        final config = PaymentConfiguration.getDefault(OrganizationType.individual);
        
        expect(config.organizationType, equals(OrganizationType.individual));
        expect(config.advancePercentage, equals(30));
        expect(config.requiresAdvance, isTrue);
        expect(config.allowsPostPayment, isFalse);
      });

      test('should create correct configuration for government', () {
        final config = PaymentConfiguration.getDefault(OrganizationType.government);
        
        expect(config.organizationType, equals(OrganizationType.government));
        expect(config.advancePercentage, equals(0));
        expect(config.requiresAdvance, isFalse);
        expect(config.allowsPostPayment, isTrue);
      });
    });

    group('Advance Amount Calculation', () {
      test('should calculate 30% advance for individual', () {
        final config = PaymentConfiguration.getDefault(OrganizationType.individual);
        const totalAmount = 10000.0;
        
        final advanceAmount = config.calculateAdvanceAmount(totalAmount);
        
        expect(advanceAmount, equals(3000));
      });

      test('should calculate 0% advance for government', () {
        final config = PaymentConfiguration.getDefault(OrganizationType.government);
        const totalAmount = 10000.0;
        
        final advanceAmount = config.calculateAdvanceAmount(totalAmount);
        
        expect(advanceAmount, equals(0));
      });
    });

    group('Complete Payment Flow', () {
      test('should create advance and final payments for individual', () async {
        final payments = await paymentService.createPaymentsForBooking(
          booking: testBooking,
          organizationType: OrganizationType.individual,
        );
        
        expect(payments.length, equals(2));
        
        final advancePayment = payments.firstWhere((p) => p.type == PaymentType.advance);
        expect(advancePayment.amount, equals(3000));
        expect(advancePayment.status, equals(PaymentStatus.pending));
        
        final finalPayment = payments.firstWhere((p) => p.type == PaymentType.finalPayment);
        expect(finalPayment.amount, equals(7000));
        expect(finalPayment.status, equals(PaymentStatus.pending));
      });

      test('should create only final payment for government', () async {
        final payments = await paymentService.createPaymentsForBooking(
          booking: testBooking,
          organizationType: OrganizationType.government,
        );
        
        expect(payments.length, equals(1));
        
        final payment = payments.first;
        expect(payment.type, equals(PaymentType.fullPayment));
        expect(payment.amount, equals(10000));
        expect(payment.status, equals(PaymentStatus.pending));
      });
    });
  });
}