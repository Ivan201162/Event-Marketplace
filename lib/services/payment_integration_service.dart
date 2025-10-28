import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/models/payment_models.dart';
import 'package:event_marketplace_app/services/payment_service.dart';
import 'package:event_marketplace_app/services/tax_calculation_service.dart';
import 'package:flutter/foundation.dart';

class PaymentIntegrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();
  final TaxCalculationService _taxCalculationService = TaxCalculationService();

  /// Creates a payment for a booking
  Future<Payment> createBookingPayment({
    required String bookingId,
    required PaymentType type,
    required PaymentMethod method,
    required String customerId,
    required String specialistId,
  }) async {
    try {
      // Get booking details
      final booking = await _getBooking(bookingId);
      if (booking == null) {
        throw Exception('Бронирование не найдено');
      }

      // Calculate payment amount based on type
      final amount = _calculatePaymentAmount(booking, type);

      // Get specialist's tax status
      final specialistTaxStatus = await _getSpecialistTaxStatus(specialistId);

      // Create payment
      final payment = await _paymentService.createPayment(
        bookingId: bookingId,
        amount: amount,
        type: type,
        method: method,
        customerId: customerId,
        specialistId: specialistId,
      );

      // Calculate tax
      final taxCalculation = await _taxCalculationService.calculateTax(
        paymentId: payment.id,
        grossAmount: amount,
        taxStatus: specialistTaxStatus,
      );

      // Update payment with tax information
      await _paymentService.updatePayment(
        payment.id,
        taxAmount: taxCalculation.taxAmount,
        netAmount: taxCalculation.netAmount,
        taxCalculationId: taxCalculation.id,
      );

      // Update booking with payment information
      await _updateBookingPayment(bookingId, payment.id, type);

      debugPrint('Booking payment created: ${payment.id}');
      return payment;
    } catch (e) {
      debugPrint('Error creating booking payment: $e');
      throw Exception('Ошибка создания платежа для бронирования: $e');
    }
  }

  /// Processes a booking payment
  Future<void> processBookingPayment(String paymentId) async {
    try {
      final payment = await _paymentService.getPayment(paymentId);
      if (payment == null) {
        throw Exception('Платеж не найден');
      }

      // Process payment through gateway
      await _paymentService.processPayment(paymentId);

      // Update booking status based on payment type
      await _updateBookingStatus(payment.bookingId, payment.type);

      debugPrint('Booking payment processed: $paymentId');
    } catch (e) {
      debugPrint('Error processing booking payment: $e');
      throw Exception('Ошибка обработки платежа бронирования: $e');
    }
  }

  /// Completes a booking payment
  Future<void> completeBookingPayment(String paymentId) async {
    try {
      final payment = await _paymentService.getPayment(paymentId);
      if (payment == null) {
        throw Exception('Платеж не найден');
      }

      // Complete payment
      await _paymentService.completePayment(paymentId);

      // Update booking status
      await _updateBookingStatus(payment.bookingId, payment.type);

      // Send notifications
      await _sendPaymentNotifications(payment);

      debugPrint('Booking payment completed: $paymentId');
    } catch (e) {
      debugPrint('Error completing booking payment: $e');
      throw Exception('Ошибка завершения платежа бронирования: $e');
    }
  }

  /// Cancels a booking payment
  Future<void> cancelBookingPayment(String paymentId) async {
    try {
      final payment = await _paymentService.getPayment(paymentId);
      if (payment == null) {
        throw Exception('Платеж не найден');
      }

      // Cancel payment
      await _paymentService.cancelPayment(paymentId);

      // Update booking status
      await _updateBookingStatus(payment.bookingId, payment.type,
          isCancelled: true,);

      debugPrint('Booking payment cancelled: $paymentId');
    } catch (e) {
      debugPrint('Error cancelling booking payment: $e');
      throw Exception('Ошибка отмены платежа бронирования: $e');
    }
  }

  /// Gets payments for a booking
  Future<List<Payment>> getBookingPayments(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Payment.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting booking payments: $e');
      return [];
    }
  }

  /// Gets payment summary for a booking
  Future<BookingPaymentSummary> getBookingPaymentSummary(
      String bookingId,) async {
    try {
      final payments = await getBookingPayments(bookingId);
      final booking = await _getBooking(bookingId);

      if (booking == null) {
        throw Exception('Бронирование не найдено');
      }

      var totalPaid = 0;
      var totalTax = 0;
      var totalNet = 0;
      var hasPrepayment = false;
      var hasPostpayment = false;

      for (final payment in payments) {
        if (payment.status == PaymentStatus.completed) {
          totalPaid += payment.amount;
          totalTax += payment.taxAmount;
          totalNet += payment.netAmount;

          if (payment.type == PaymentType.prepayment) {
            hasPrepayment = true;
          } else if (payment.type == PaymentType.postpayment) {
            hasPostpayment = true;
          }
        }
      }

      final totalAmount = booking.totalAmount;
      final remainingAmount = totalAmount - totalPaid;
      final prepaymentAmount = totalAmount * 0.3; // 30% prepayment
      final postpaymentAmount = totalAmount - prepaymentAmount;

      return BookingPaymentSummary(
        bookingId: bookingId,
        totalAmount: totalAmount,
        totalPaid: totalPaid,
        totalTax: totalTax,
        totalNet: totalNet,
        remainingAmount: remainingAmount,
        prepaymentAmount: prepaymentAmount,
        postpaymentAmount: postpaymentAmount,
        hasPrepayment: hasPrepayment,
        hasPostpayment: hasPostpayment,
        payments: payments,
        isFullyPaid: remainingAmount <= 0,
      );
    } catch (e) {
      debugPrint('Error getting booking payment summary: $e');
      throw Exception('Ошибка получения сводки платежей бронирования: $e');
    }
  }

  /// Creates a contract for a booking
  Future<Contract> createBookingContract(String bookingId) async {
    try {
      final booking = await _getBooking(bookingId);
      if (booking == null) {
        throw Exception('Бронирование не найдено');
      }

      final paymentSummary = await getBookingPaymentSummary(bookingId);

      final contract = Contract(
        id: _firestore.collection('contracts').doc().id,
        bookingId: bookingId,
        customerId: booking.customerId,
        specialistId: booking.specialistId,
        totalAmount: booking.totalAmount,
        prepaymentAmount: paymentSummary.prepaymentAmount,
        postpaymentAmount: paymentSummary.postpaymentAmount,
        status: ContractStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('contracts')
          .doc(contract.id)
          .set(contract.toMap());

      debugPrint('Booking contract created: ${contract.id}');
      return contract;
    } catch (e) {
      debugPrint('Error creating booking contract: $e');
      throw Exception('Ошибка создания договора бронирования: $e');
    }
  }

  /// Updates contract status
  Future<void> updateContractStatus(
      String contractId, ContractStatus status,) async {
    try {
      await _firestore.collection('contracts').doc(contractId).update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('Contract status updated: $contractId to $status');
    } catch (e) {
      debugPrint('Error updating contract status: $e');
      throw Exception('Ошибка обновления статуса договора: $e');
    }
  }

  /// Gets contract by ID
  Future<Contract?> getContract(String contractId) async {
    try {
      final doc =
          await _firestore.collection('contracts').doc(contractId).get();
      if (!doc.exists) return null;
      return Contract.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error getting contract: $e');
      return null;
    }
  }

  /// Gets contract for a booking
  Future<Contract?> getBookingContract(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('contracts')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return Contract.fromMap(snapshot.docs.first.data());
    } catch (e) {
      debugPrint('Error getting booking contract: $e');
      return null;
    }
  }

  /// Helper methods
  Future<Booking?> _getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!doc.exists) return null;
      return Booking.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error getting booking: $e');
      return null;
    }
  }

  double _calculatePaymentAmount(Booking booking, PaymentType type) {
    switch (type) {
      case PaymentType.prepayment:
        return booking.totalAmount * 0.3; // 30% prepayment
      case PaymentType.postpayment:
        return booking.totalAmount * 0.7; // 70% postpayment
      case PaymentType.fullPayment:
        return booking.totalAmount; // 100% payment
    }
  }

  Future<TaxStatus> _getSpecialistTaxStatus(String specialistId) async {
    try {
      final doc =
          await _firestore.collection('specialists').doc(specialistId).get();
      if (!doc.exists) {
        return TaxStatus.individual; // Default to individual
      }

      final data = doc.data()!;
      final taxStatusString = data['taxStatus'] as String?;

      if (taxStatusString != null) {
        return TaxStatus.values.firstWhere(
          (e) => e.toString().split('.').last == taxStatusString,
          orElse: () => TaxStatus.individual,
        );
      }

      return TaxStatus.individual;
    } catch (e) {
      debugPrint('Error getting specialist tax status: $e');
      return TaxStatus.individual;
    }
  }

  Future<void> _updateBookingPayment(
      String bookingId, String paymentId, PaymentType type,) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      switch (type) {
        case PaymentType.prepayment:
          updateData['prepaymentId'] = paymentId;
        case PaymentType.postpayment:
          updateData['postpaymentId'] = paymentId;
        case PaymentType.fullPayment:
          updateData['fullPaymentId'] = paymentId;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updateData);
    } catch (e) {
      debugPrint('Error updating booking payment: $e');
    }
  }

  Future<void> _updateBookingStatus(
    String bookingId,
    PaymentType type, {
    bool isCancelled = false,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (isCancelled) {
        updateData['status'] = 'cancelled';
      } else {
        switch (type) {
          case PaymentType.prepayment:
            updateData['status'] = 'confirmed';
          case PaymentType.postpayment:
            updateData['status'] = 'completed';
          case PaymentType.fullPayment:
            updateData['status'] = 'confirmed';
        }
      }

      await _firestore.collection('bookings').doc(bookingId).update(updateData);
    } catch (e) {
      debugPrint('Error updating booking status: $e');
    }
  }

  Future<void> _sendPaymentNotifications(Payment payment) async {
    try {
      // Send notification to customer
      await _firestore.collection('notifications').add({
        'userId': payment.customerId,
        'type': 'payment_completed',
        'title': 'Платеж завершен',
        'message':
            'Ваш платеж на сумму ${payment.amount.toStringAsFixed(0)} ₽ успешно завершен',
        'data': {'paymentId': payment.id, 'bookingId': payment.bookingId},
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'read': false,
      });

      // Send notification to specialist
      await _firestore.collection('notifications').add({
        'userId': payment.specialistId,
        'type': 'payment_received',
        'title': 'Получен платеж',
        'message':
            'Вы получили платеж на сумму ${payment.netAmount.toStringAsFixed(0)} ₽',
        'data': {'paymentId': payment.id, 'bookingId': payment.bookingId},
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'read': false,
      });
    } catch (e) {
      debugPrint('Error sending payment notifications: $e');
    }
  }
}

/// Booking Payment Summary
class BookingPaymentSummary {
  BookingPaymentSummary({
    required this.bookingId,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalTax,
    required this.totalNet,
    required this.remainingAmount,
    required this.prepaymentAmount,
    required this.postpaymentAmount,
    required this.hasPrepayment,
    required this.hasPostpayment,
    required this.payments,
    required this.isFullyPaid,
  });
  final String bookingId;
  final double totalAmount;
  final double totalPaid;
  final double totalTax;
  final double totalNet;
  final double remainingAmount;
  final double prepaymentAmount;
  final double postpaymentAmount;
  final bool hasPrepayment;
  final bool hasPostpayment;
  final List<Payment> payments;
  final bool isFullyPaid;
}

/// Contract model
class Contract {
  Contract({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.totalAmount,
    required this.prepaymentAmount,
    required this.postpaymentAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contract.fromMap(Map<String, dynamic> map) => Contract(
        id: map['id'] as String,
        bookingId: map['bookingId'] as String,
        customerId: map['customerId'] as String,
        specialistId: map['specialistId'] as String,
        totalAmount: (map['totalAmount'] as num).toDouble(),
        prepaymentAmount: (map['prepaymentAmount'] as num).toDouble(),
        postpaymentAmount: (map['postpaymentAmount'] as num).toDouble(),
        status: ContractStatus.values.firstWhere(
          (e) => e.toString().split('.').last == map['status'] as String,
        ),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      );
  final String id;
  final String bookingId;
  final String customerId;
  final String specialistId;
  final double totalAmount;
  final double prepaymentAmount;
  final double postpaymentAmount;
  final ContractStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'bookingId': bookingId,
        'customerId': customerId,
        'specialistId': specialistId,
        'totalAmount': totalAmount,
        'prepaymentAmount': prepaymentAmount,
        'postpaymentAmount': postpaymentAmount,
        'status': status.toString().split('.').last,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

/// Contract status
enum ContractStatus {
  draft, // Черновик
  active, // Активный
  completed, // Завершен
  cancelled, // Отменен
}
