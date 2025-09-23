import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logger.dart';
import '../models/booking.dart';
import '../models/app_user.dart';

/// Сервис для работы с платежами через российские провайдеры
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Конфигурация для ЮKassa (основной провайдер)
  static const String _yookassaShopId = 'YOUR_SHOP_ID';
  static const String _yookassaSecretKey = 'YOUR_SECRET_KEY';
  static const String _yookassaBaseUrl = 'https://api.yookassa.ru/v3';
  
  // Конфигурация для CloudPayments (резервный)
  static const String _cloudpaymentsPublicId = 'YOUR_PUBLIC_ID';
  static const String _cloudpaymentsApiSecret = 'YOUR_API_SECRET';
  static const String _cloudpaymentsBaseUrl = 'https://api.cloudpayments.ru';

  /// Типы платежей
  static const String paymentTypeAdvance = 'advance'; // Аванс (30% или 70%)
  static const String paymentTypeFinal = 'final'; // Окончательная оплата
  static const String paymentTypeFull = 'full'; // Полная предоплата
  static const String paymentTypeRefund = 'refund'; // Возврат

  /// Статусы платежей
  static const String paymentStatusPending = 'pending'; // В ожидании
  static const String paymentStatusProcessing = 'processing'; // Обрабатывается
  static const String paymentStatusSucceeded = 'succeeded'; // Успешно
  static const String paymentStatusFailed = 'failed'; // Неудачно
  static const String paymentStatusCanceled = 'canceled'; // Отменен
  static const String paymentStatusRefunded = 'refunded'; // Возвращен

  /// Заморозить аванс
  Future<PaymentResult> holdAdvancePayment({
    required String bookingId,
    required double totalAmount,
    required String currency,
    required AppUser customer,
    bool isGovernmentOrganization = false,
  }) async {
    // 30% для обычных организаций, 70% для госорганизаций
    final advancePercentage = isGovernmentOrganization ? 0.7 : 0.3;
    final advanceAmount = totalAmount * advancePercentage;
    
    final paymentType = isGovernmentOrganization ? paymentTypeAdvance : paymentTypeAdvance;
    
    return await createYookassaPayment(
      bookingId: bookingId,
      amount: advanceAmount,
      currency: currency,
      paymentType: paymentType,
      customer: customer,
      description: 'Аванс за услуги (${(advancePercentage * 100).round()}%)',
    );
  }

  /// Создать окончательную оплату
  Future<PaymentResult> createFinalPayment({
    required String bookingId,
    required double remainingAmount,
    required String currency,
    required AppUser customer,
  }) async {
    return await createYookassaPayment(
      bookingId: bookingId,
      amount: remainingAmount,
      currency: currency,
      paymentType: PaymentType.finalPayment,
      customer: customer,
      description: 'Окончательная оплата услуг',
    );
  }

  /// Создать платеж через ЮKassa
  Future<PaymentResult> createYookassaPayment({
    required String bookingId,
    required double amount,
    required String currency,
    required String paymentType,
    required AppUser customer,
    String? description,
  }) async {
    try {
      AppLogger.logI('Создание платежа ЮKassa для бронирования $bookingId', 'payment_service');
      
      final paymentId = 'payment_${bookingId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Создаем платеж в ЮKassa
      final response = await http.post(
        Uri.parse('$_yookassaBaseUrl/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_yookassaShopId:$_yookassaSecretKey'))}',
        },
        body: jsonEncode({
          'amount': {
            'value': amount.toStringAsFixed(2),
            'currency': currency,
          },
          'confirmation': {
            'type': 'redirect',
            'return_url': 'https://your-app.com/payment/success',
          },
          'description': description ?? _getPaymentDescription(paymentType, bookingId),
          'metadata': {
            'booking_id': bookingId,
            'payment_type': paymentType.name,
            'customer_id': customer.id,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Сохраняем платеж в Firestore
        await _savePayment(
          paymentId: paymentId,
          bookingId: bookingId,
          amount: amount,
          currency: currency,
          paymentType: paymentType,
          status: PaymentStatus.pending,
          provider: 'yookassa',
          externalId: data['id'],
          confirmationUrl: data['confirmation']?['confirmation_url'],
        );

        return PaymentResult.success(
          paymentId: paymentId,
          confirmationUrl: data['confirmation']?['confirmation_url'],
          externalPaymentId: data['id'],
        );
      } else {
        AppLogger.logE('Ошибка создания платежа ЮKassa: ${response.body}', 'payment_service');
        return PaymentResult.error('Ошибка создания платежа: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.logE('Исключение при создании платежа ЮKassa', 'payment_service', e, stackTrace);
      return PaymentResult.error('Ошибка при создании платежа: $e');
    }
  }

  /// Сохранить платеж в Firestore
  Future<void> _savePayment({
    required String paymentId,
    required String bookingId,
    required double amount,
    required String currency,
    required String paymentType,
    required String status,
    required String provider,
    required String? externalId,
    required String? confirmationUrl,
  }) async {
    try {
      await _firestore.collection('payments').doc(paymentId).set({
        'bookingId': bookingId,
        'amount': amount,
        'currency': currency,
        'paymentType': paymentType.name,
        'status': status.name,
        'provider': provider,
        'externalId': externalId,
        'confirmationUrl': confirmationUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.logI('Платеж $paymentId сохранен в Firestore', 'payment_service');
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка сохранения платежа', 'payment_service', e, stackTrace);
    }
  }

  /// Получить описание платежа
  String _getPaymentDescription(PaymentType paymentType, String bookingId) {
    switch (paymentType) {
      case PaymentType.advance:
        return 'Аванс за бронирование $bookingId';
      case PaymentType.finalPayment:
        return 'Окончательная оплата за бронирование $bookingId';
      case PaymentType.full:
        return 'Полная оплата за бронирование $bookingId';
      case PaymentType.refund:
        return 'Возврат за бронирование $bookingId';
    }
  }
}

/// Результат платежа
class PaymentResult {
  final bool isSuccess;
  final String? error;
  final String? paymentId;
  final String? confirmationUrl;
  final String? externalPaymentId;

  PaymentResult._({
    required this.isSuccess,
    this.error,
    this.paymentId,
    this.confirmationUrl,
    this.externalPaymentId,
  });

  factory PaymentResult.success({
    required String paymentId,
    String? confirmationUrl,
    String? externalPaymentId,
  }) {
    return PaymentResult._(
      isSuccess: true,
      paymentId: paymentId,
      confirmationUrl: confirmationUrl,
      externalPaymentId: externalPaymentId,
    );
  }

  factory PaymentResult.error(String error) {
    return PaymentResult._(
      isSuccess: false,
      error: error,
    );
  }
}