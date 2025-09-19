import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/feature_flags.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import 'bank_integration_service.dart';

/// Сервис для управления авансами и финальными платежами
class AdvancePaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BankIntegrationService _bankService = BankIntegrationService();

  /// Создать авансовый платеж
  Future<Payment> createAdvancePayment({
    required String bookingId,
    required double advanceAmount,
    required double totalAmount,
    required String customerId,
    required String specialistId,
    required String bankId,
    String? description,
  }) async {
    if (!FeatureFlags.advancePaymentEnabled) {
      throw Exception('Авансовые платежи отключены');
    }

    try {
      // Проверяем, что аванс не превышает 50% от общей суммы
      final maxAdvance = totalAmount * 0.5;
      if (advanceAmount > maxAdvance) {
        throw Exception('Аванс не может превышать 50% от общей суммы');
      }

      // Создаем платеж
      final payment = Payment(
        id: '',
        bookingId: bookingId,
        userId: customerId,
        amount: advanceAmount,
        currency: 'RUB',
        status: PaymentStatus.pending,
        type: PaymentType.advance,
        description: description ?? 'Авансовый платеж за бронирование',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paymentMethod: 'bank_transfer',
        bankId: bankId,
        metadata: {
          'totalAmount': totalAmount,
          'remainingAmount': totalAmount - advanceAmount,
          'specialistId': specialistId,
        },
      );

      // Сохраняем в Firestore
      final docRef =
          await _firestore.collection('payments').add(payment.toMap());

      // Обновляем бронирование
      await _updateBookingPaymentStatus(bookingId, advanceAmount, totalAmount);

      return payment.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания авансового платежа: $e');
    }
  }

  /// Создать финальный платеж
  Future<Payment> createFinalPayment({
    required String bookingId,
    required double finalAmount,
    required String customerId,
    required String specialistId,
    required String bankId,
    String? description,
  }) async {
    if (!FeatureFlags.finalPaymentEnabled) {
      throw Exception('Финальные платежи отключены');
    }

    try {
      // Получаем информацию о бронировании
      final booking = await _getBooking(bookingId);
      if (booking == null) {
        throw Exception('Бронирование не найдено');
      }

      // Проверяем, что аванс уже оплачен
      final advancePayments = await _getAdvancePayments(bookingId);
      final totalAdvancePaid = advancePayments
          .where((p) => p.status == PaymentStatus.completed)
          .fold(0, (sum, payment) => sum + payment.amount);

      if (totalAdvancePaid == 0) {
        throw Exception('Сначала необходимо оплатить аванс');
      }

      // Проверяем, что финальная сумма корректна
      final expectedFinalAmount = booking.totalPrice - totalAdvancePaid;
      if ((finalAmount - expectedFinalAmount).abs() > 0.01) {
        throw Exception('Неверная сумма финального платежа');
      }

      // Создаем платеж
      final payment = Payment(
        id: '',
        bookingId: bookingId,
        userId: customerId,
        amount: finalAmount,
        currency: 'RUB',
        status: PaymentStatus.pending,
        type: PaymentType.finalPayment,
        description: description ?? 'Финальный платеж за услугу',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paymentMethod: 'bank_transfer',
        bankId: bankId,
        metadata: {
          'totalAmount': booking.totalPrice,
          'advancePaid': totalAdvancePaid,
          'specialistId': specialistId,
        },
      );

      // Сохраняем в Firestore
      final docRef =
          await _firestore.collection('payments').add(payment.toMap());

      // Обновляем бронирование
      await _updateBookingPaymentStatus(
        bookingId,
        totalAdvancePaid + finalAmount,
        booking.totalPrice,
      );

      return payment.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания финального платежа: $e');
    }
  }

  /// Получить информацию о платежах по бронированию
  Future<PaymentSummary> getPaymentSummary(String bookingId) async {
    try {
      final booking = await _getBooking(bookingId);
      if (booking == null) {
        throw Exception('Бронирование не найдено');
      }

      final payments = await _getAllPayments(bookingId);
      final advancePayments =
          payments.where((p) => p.type == PaymentType.advance).toList();
      final finalPayments =
          payments.where((p) => p.type == PaymentType.finalPayment).toList();

      final totalAdvancePaid = advancePayments
          .where((p) => p.status == PaymentStatus.completed)
          .fold(0, (sum, payment) => sum + payment.amount);

      final totalFinalPaid = finalPayments
          .where((p) => p.status == PaymentStatus.completed)
          .fold(0, (sum, payment) => sum + payment.amount);

      final totalPaid = totalAdvancePaid + totalFinalPaid;
      final remainingAmount = booking.totalPrice - totalPaid;

      return PaymentSummary(
        bookingId: bookingId,
        totalAmount: booking.totalPrice,
        advanceAmount: totalAdvancePaid,
        finalAmount: totalFinalPaid,
        totalPaid: totalPaid,
        remainingAmount: remainingAmount,
        isAdvancePaid: totalAdvancePaid > 0,
        isFullyPaid: remainingAmount <= 0.01,
        advancePayments: advancePayments,
        finalPayments: finalPayments,
        nextPaymentDue: _calculateNextPaymentDue(booking, totalPaid),
      );
    } catch (e) {
      throw Exception('Ошибка получения информации о платежах: $e');
    }
  }

  /// Обновить статус платежа
  Future<void> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? transactionId,
  }) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': status.name,
        'transactionId': transactionId,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Если платеж завершен, обновляем статус бронирования
      if (status == PaymentStatus.completed) {
        final paymentDoc =
            await _firestore.collection('payments').doc(paymentId).get();
        if (paymentDoc.exists) {
          final paymentData = paymentDoc.data();
          final bookingId = paymentData['bookingId'] as String;
          await _updateBookingStatus(bookingId);
        }
      }
    } catch (e) {
      throw Exception('Ошибка обновления статуса платежа: $e');
    }
  }

  /// Отменить платеж
  Future<void> cancelPayment(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': PaymentStatus.cancelled.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка отмены платежа: $e');
    }
  }

  /// Получить рекомендуемую сумму аванса
  double calculateRecommendedAdvance(double totalAmount) {
    // Рекомендуем 30% от общей суммы, но не более 50%
    final recommended = totalAmount * 0.3;
    final maxAllowed = totalAmount * 0.5;
    return recommended > maxAllowed ? maxAllowed : recommended;
  }

  /// Проверить, можно ли создать финальный платеж
  Future<bool> canCreateFinalPayment(String bookingId) async {
    try {
      final summary = await getPaymentSummary(bookingId);
      return summary.isAdvancePaid && !summary.isFullyPaid;
    } catch (e) {
      return false;
    }
  }

  /// Получить историю платежей
  Future<List<Payment>> getPaymentHistory(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(Payment.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения истории платежей: $e');
    }
  }

  // Приватные методы

  Future<Booking?> _getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromDocument(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Payment>> _getAdvancePayments(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('bookingId', isEqualTo: bookingId)
          .where('type', isEqualTo: PaymentType.advance.name)
          .get();

      return snapshot.docs.map(Payment.fromDocument).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Payment>> _getAllPayments(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('bookingId', isEqualTo: bookingId)
          .get();

      return snapshot.docs.map(Payment.fromDocument).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _updateBookingPaymentStatus(
    String bookingId,
    double paidAmount,
    double totalAmount,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'paidAmount': paidAmount,
        'paymentStatus':
            paidAmount >= totalAmount ? 'fully_paid' : 'partially_paid',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Игнорируем ошибки обновления
    }
  }

  Future<void> _updateBookingStatus(String bookingId) async {
    try {
      final summary = await getPaymentSummary(bookingId);
      var status = 'confirmed';

      if (summary.isFullyPaid) {
        status = 'paid';
      } else if (summary.isAdvancePaid) {
        status = 'advance_paid';
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Игнорируем ошибки обновления
    }
  }

  DateTime? _calculateNextPaymentDue(Booking booking, double totalPaid) {
    if (totalPaid >= booking.totalPrice) {
      return null; // Полностью оплачено
    }

    // Если аванс не оплачен, срок - до начала мероприятия
    if (totalPaid == 0) {
      return booking.eventDate.subtract(const Duration(days: 7));
    }

    // Если аванс оплачен, финальный платеж - до начала мероприятия
    return booking.eventDate.subtract(const Duration(days: 1));
  }
}

/// Сводка по платежам
class PaymentSummary {
  const PaymentSummary({
    required this.bookingId,
    required this.totalAmount,
    required this.advanceAmount,
    required this.finalAmount,
    required this.totalPaid,
    required this.remainingAmount,
    required this.isAdvancePaid,
    required this.isFullyPaid,
    required this.advancePayments,
    required this.finalPayments,
    this.nextPaymentDue,
  });
  final String bookingId;
  final double totalAmount;
  final double advanceAmount;
  final double finalAmount;
  final double totalPaid;
  final double remainingAmount;
  final bool isAdvancePaid;
  final bool isFullyPaid;
  final List<Payment> advancePayments;
  final List<Payment> finalPayments;
  final DateTime? nextPaymentDue;
}
