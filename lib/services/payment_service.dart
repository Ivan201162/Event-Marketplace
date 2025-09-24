import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/logger.dart';
import '../models/payment_models.dart';
import '../models/contract_models.dart';
import '../models/tax_models.dart';
import '../models/booking.dart';

/// Сервис для управления платежами
class PaymentService {
  factory PaymentService() => _instance;
  PaymentService._internal();
  static final PaymentService _instance = PaymentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Создать платёж
  Future<Payment> createPayment({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required double amount,
    required PaymentType type,
    required PaymentMethod method,
    required PaymentScheme scheme,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final paymentId = _uuid.v4();
      final now = DateTime.now();

      final payment = Payment(
        id: paymentId,
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        amount: amount,
        type: type,
        status: PaymentStatus.pending,
        method: method,
        scheme: scheme,
        createdAt: now,
        description: description,
        metadata: metadata,
      );

      await _firestore
          .collection('payments')
          .doc(paymentId)
          .set(payment.toMap());

      AppLogger.logI('Платёж создан: $paymentId', 'payment_service');
      return payment;
    } catch (e) {
      AppLogger.logE('Ошибка создания платежа: $e', 'payment_service');
      rethrow;
    }
  }

  /// Создать авансовый платёж
  Future<Payment> createPrepayment({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required double totalAmount,
    required PaymentMethod method,
    PaymentScheme scheme = PaymentScheme.partialPrepayment,
  }) async {
    try {
      // Рассчитываем сумму аванса в зависимости от схемы
      double prepaymentAmount;
      switch (scheme) {
        case PaymentScheme.partialPrepayment:
          prepaymentAmount = totalAmount * 0.3; // 30%
          break;
        case PaymentScheme.fullPrepayment:
          prepaymentAmount = totalAmount; // 100%
          break;
        case PaymentScheme.postPayment:
          prepaymentAmount = 0.0; // 0% для постоплаты
          break;
      }

      final payment = await createPayment(
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        amount: prepaymentAmount,
        type: PaymentType.prepayment,
        method: method,
        scheme: scheme,
        description: 'Авансовый платёж',
        metadata: {
          'totalAmount': totalAmount,
          'prepaymentPercentage': scheme == PaymentScheme.partialPrepayment ? 30 : 
                                 scheme == PaymentScheme.fullPrepayment ? 100 : 0,
        },
      );

      AppLogger.logI('Авансовый платёж создан: ${payment.id}', 'payment_service');
      return payment;
    } catch (e) {
      AppLogger.logE('Ошибка создания авансового платежа: $e', 'payment_service');
      rethrow;
    }
  }

  /// Создать финальный платёж
  Future<Payment> createFinalPayment({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required double totalAmount,
    required PaymentMethod method,
    PaymentScheme scheme = PaymentScheme.partialPrepayment,
  }) async {
    try {
      // Рассчитываем сумму финального платежа
      double finalAmount;
      switch (scheme) {
        case PaymentScheme.partialPrepayment:
          finalAmount = totalAmount * 0.7; // 70%
          break;
        case PaymentScheme.fullPrepayment:
          finalAmount = 0.0; // Уже оплачено
          break;
        case PaymentScheme.postPayment:
          finalAmount = totalAmount; // 100% для постоплаты
          break;
      }

      final payment = await createPayment(
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        amount: finalAmount,
        type: PaymentType.finalPayment,
        method: method,
        scheme: scheme,
        description: 'Финальный платёж',
        metadata: {
          'totalAmount': totalAmount,
          'finalPercentage': scheme == PaymentScheme.partialPrepayment ? 70 : 
                            scheme == PaymentScheme.fullPrepayment ? 0 : 100,
        },
      );

      AppLogger.logI('Финальный платёж создан: ${payment.id}', 'payment_service');
      return payment;
    } catch (e) {
      AppLogger.logE('Ошибка создания финального платежа: $e', 'payment_service');
      rethrow;
    }
  }

  /// Обновить статус платежа
  Future<void> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? transactionId,
    String? paymentUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
      };

      final now = DateTime.now();
      switch (status) {
        case PaymentStatus.processing:
          updateData['processedAt'] = Timestamp.fromDate(now);
          break;
        case PaymentStatus.completed:
          updateData['completedAt'] = Timestamp.fromDate(now);
          break;
        case PaymentStatus.failed:
          updateData['failedAt'] = Timestamp.fromDate(now);
          break;
        case PaymentStatus.cancelled:
          updateData['cancelledAt'] = Timestamp.fromDate(now);
          break;
        case PaymentStatus.refunded:
          updateData['refundedAt'] = Timestamp.fromDate(now);
          break;
        case PaymentStatus.pending:
          break;
      }

      if (transactionId != null) {
        updateData['transactionId'] = transactionId;
      }
      if (paymentUrl != null) {
        updateData['paymentUrl'] = paymentUrl;
      }
      if (metadata != null) {
        updateData['metadata'] = metadata;
      }

      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update(updateData);

      AppLogger.logI('Статус платежа обновлён: $paymentId -> $status', 'payment_service');
    } catch (e) {
      AppLogger.logE('Ошибка обновления статуса платежа: $e', 'payment_service');
      rethrow;
    }
  }

  /// Получить платежи по бронированию
  Future<List<Payment>> getPaymentsByBooking(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: false)
          .get();

      final payments = snapshot.docs
          .map((doc) => Payment.fromMap(doc.data()))
          .toList();

      AppLogger.logI('Получено платежей для бронирования $bookingId: ${payments.length}', 'payment_service');
      return payments;
    } catch (e) {
      AppLogger.logE('Ошибка получения платежей: $e', 'payment_service');
      rethrow;
    }
  }

  /// Получить платежи по специалисту
  Future<List<Payment>> getPaymentsBySpecialist(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      final payments = snapshot.docs
          .map((doc) => Payment.fromMap(doc.data()))
          .toList();

      AppLogger.logI('Получено платежей для специалиста $specialistId: ${payments.length}', 'payment_service');
      return payments;
    } catch (e) {
      AppLogger.logE('Ошибка получения платежей специалиста: $e', 'payment_service');
      rethrow;
    }
  }

  /// Получить платежи по клиенту
  Future<List<Payment>> getPaymentsByCustomer(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      final payments = snapshot.docs
          .map((doc) => Payment.fromMap(doc.data()))
          .toList();

      AppLogger.logI('Получено платежей для клиента $customerId: ${payments.length}', 'payment_service');
      return payments;
    } catch (e) {
      AppLogger.logE('Ошибка получения платежей клиента: $e', 'payment_service');
      rethrow;
    }
  }

  /// Получить платёж по ID
  Future<Payment?> getPaymentById(String paymentId) async {
    try {
      final doc = await _firestore
          .collection('payments')
          .doc(paymentId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Payment.fromMap(doc.data()!);
    } catch (e) {
      AppLogger.logE('Ошибка получения платежа: $e', 'payment_service');
      rethrow;
    }
  }

  /// Рассчитать налоги для платежа
  Future<TaxRecord> calculateTaxes({
    required String specialistId,
    required String paymentId,
    required double amount,
    required TaxpayerStatus taxpayerStatus,
  }) async {
    try {
      final taxRecordId = _uuid.v4();
      final now = DateTime.now();
      final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Получаем налоговый профиль специалиста
      final taxProfile = await _getTaxProfile(specialistId);
      
      // Рассчитываем налоги
      final taxRate = taxProfile?.taxRate ?? _getDefaultTaxRate(taxpayerStatus);
      final taxAmount = amount * (taxRate / 100);
      final netAmount = amount - taxAmount;

      final taxRecord = TaxRecord(
        id: taxRecordId,
        specialistId: specialistId,
        paymentId: paymentId,
        amount: amount,
        taxType: taxProfile?.taxType ?? _getDefaultTaxType(taxpayerStatus),
        taxRate: taxRate,
        taxAmount: taxAmount,
        netAmount: netAmount,
        period: period,
        createdAt: now,
        deadline: _calculateTaxDeadline(now),
        status: 'pending',
      );

      // Сохраняем налоговую запись
      await _firestore
          .collection('tax_records')
          .doc(taxRecordId)
          .set(taxRecord.toMap());

      AppLogger.logI('Налоги рассчитаны для платежа $paymentId: $taxAmount руб.', 'payment_service');
      return taxRecord;
    } catch (e) {
      AppLogger.logE('Ошибка расчёта налогов: $e', 'payment_service');
      rethrow;
    }
  }

  /// Получить налоговый профиль специалиста
  Future<TaxProfile?> _getTaxProfile(String specialistId) async {
    try {
      final doc = await _firestore
          .collection('tax_profiles')
          .doc(specialistId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return TaxProfile.fromMap(doc.data()!);
    } catch (e) {
      AppLogger.logE('Ошибка получения налогового профиля: $e', 'payment_service');
      return null;
    }
  }

  /// Получить ставку налога по умолчанию
  double _getDefaultTaxRate(TaxpayerStatus status) {
    switch (status) {
      case TaxpayerStatus.individual:
        return 13.0; // НДФЛ
      case TaxpayerStatus.individualEntrepreneur:
        return 6.0; // УСН "Доходы"
      case TaxpayerStatus.selfEmployed:
        return 4.0; // НПД для услуг
      case TaxpayerStatus.governmentInstitution:
        return 0.0; // Освобождены от налогов
      case TaxpayerStatus.nonProfit:
        return 0.0; // Освобождены от налогов
    }
  }

  /// Получить тип налога по умолчанию
  TaxType _getDefaultTaxType(TaxpayerStatus status) {
    switch (status) {
      case TaxpayerStatus.individual:
        return TaxType.incomeTax;
      case TaxpayerStatus.individualEntrepreneur:
        return TaxType.simplifiedTax;
      case TaxpayerStatus.selfEmployed:
        return TaxType.professionalIncomeTax;
      case TaxpayerStatus.governmentInstitution:
        return TaxType.incomeTax;
      case TaxpayerStatus.nonProfit:
        return TaxType.incomeTax;
    }
  }

  /// Рассчитать срок уплаты налога
  DateTime _calculateTaxDeadline(DateTime createdAt) {
    // Для НПД - до 25 числа следующего месяца
    // Для УСН - до 25 числа следующего месяца
    // Для НДФЛ - до 15 июля следующего года
    final nextMonth = DateTime(createdAt.year, createdAt.month + 1, 1);
    return DateTime(nextMonth.year, nextMonth.month, 25);
  }

  /// Создать или обновить налоговый профиль
  Future<void> createOrUpdateTaxProfile({
    required String specialistId,
    required TaxpayerStatus taxpayerStatus,
    required String taxNumber,
    String? inn,
    String? snils,
    String? ogrnip,
    double? taxRate,
    TaxType? taxType,
  }) async {
    try {
      final taxProfile = TaxProfile(
        specialistId: specialistId,
        taxpayerStatus: taxpayerStatus,
        taxNumber: taxNumber,
        updatedAt: DateTime.now(),
        inn: inn,
        snils: snils,
        ogrnip: ogrnip,
        taxRate: taxRate ?? _getDefaultTaxRate(taxpayerStatus),
        taxType: taxType ?? _getDefaultTaxType(taxpayerStatus),
        isActive: true,
      );

      await _firestore
          .collection('tax_profiles')
          .doc(specialistId)
          .set(taxProfile.toMap());

      AppLogger.logI('Налоговый профиль обновлён для специалиста $specialistId', 'payment_service');
    } catch (e) {
      AppLogger.logE('Ошибка обновления налогового профиля: $e', 'payment_service');
      rethrow;
    }
  }

  /// Получить налоговые записи специалиста
  Future<List<TaxRecord>> getTaxRecordsBySpecialist(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('tax_records')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      final taxRecords = snapshot.docs
          .map((doc) => TaxRecord.fromMap(doc.data()))
          .toList();

      AppLogger.logI('Получено налоговых записей для специалиста $specialistId: ${taxRecords.length}', 'payment_service');
      return taxRecords;
    } catch (e) {
      AppLogger.logE('Ошибка получения налоговых записей: $e', 'payment_service');
      rethrow;
    }
  }

  /// Отметить налог как оплаченный
  Future<void> markTaxAsPaid(String taxRecordId) async {
    try {
      await _firestore
          .collection('tax_records')
          .doc(taxRecordId)
          .update({
        'status': 'paid',
        'paidAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.logI('Налог отмечен как оплаченный: $taxRecordId', 'payment_service');
    } catch (e) {
      AppLogger.logE('Ошибка отметки налога как оплаченного: $e', 'payment_service');
      rethrow;
    }
  }
}