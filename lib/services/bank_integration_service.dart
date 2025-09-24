import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../core/logger.dart';
import '../models/payment_models.dart';

/// Сервис для интеграции с банковскими системами
class BankIntegrationService {
  factory BankIntegrationService() => _instance;
  BankIntegrationService._internal();
  static final BankIntegrationService _instance = BankIntegrationService._internal();

  final Uuid _uuid = const Uuid();
  
  // Тестовые ключи для демонстрации
  static const String _yookassaShopId = 'test_shop_id';
  static const String _yookassaSecretKey = 'test_secret_key';
  static const String _sbpSecretKey = 'test_secret_key';

  /// Создать платёж через ЮKassa
  Future<PaymentResult> createYooKassaPayment({
    required String paymentId,
    required double amount,
    required String description,
    required String returnUrl,
    String? customerEmail,
    String? customerPhone,
  }) async {
    try {
      final requestId = _uuid.v4();
      
      final requestBody = {
        'amount': {
          'value': amount.toStringAsFixed(2),
          'currency': 'RUB',
        },
        'confirmation': {
          'type': 'redirect',
          'return_url': returnUrl,
        },
        'description': description,
        'metadata': {
          'payment_id': paymentId,
          'request_id': requestId,
        },
        if (customerEmail != null) 'receipt': {
          'customer': {
            'email': customerEmail,
          },
          'items': [
            {
              'description': description,
              'amount': {
                'value': amount.toStringAsFixed(2),
                'currency': 'RUB',
              },
              'vat_code': 1,
              'quantity': '1',
            },
          ],
        },
      };

      final response = await http.post(
        Uri.parse('https://api.yookassa.ru/v3/payments'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_yookassaShopId:$_yookassaSecretKey'))}',
          'Idempotence-Key': requestId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        return PaymentResult(
          success: true,
          paymentUrl: responseData['confirmation']['confirmation_url'] as String?,
          transactionId: responseData['id'] as String?,
          status: _mapYooKassaStatus(responseData['status'] as String),
          metadata: responseData as Map<String, dynamic>?,
        );
      } else {
        AppLogger.logE('Ошибка создания платежа ЮKassa: ${response.statusCode} - ${response.body}', 'bank_integration');
        return PaymentResult(
          success: false,
          error: 'Ошибка создания платежа: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.logE('Ошибка создания платежа ЮKassa: $e', 'bank_integration');
      return PaymentResult(
        success: false,
        error: 'Ошибка создания платежа: $e',
      );
    }
  }

  /// Создать платёж через СБП
  Future<PaymentResult> createSBPPayment({
    required String paymentId,
    required double amount,
    required String description,
    String? customerPhone,
  }) async {
    try {
      final requestId = _uuid.v4();
      
      final requestBody = {
        'amount': amount.toStringAsFixed(2),
        'currency': 'RUB',
        'description': description,
        'order_id': paymentId,
        'customer_phone': customerPhone,
        'metadata': {
          'payment_id': paymentId,
          'request_id': requestId,
        },
      };

      // Для демонстрации используем тестовый URL
      final response = await http.post(
        Uri.parse('https://api.sbp.test/payment/create'),
        headers: {
          'Authorization': 'Bearer $_sbpSecretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        return PaymentResult(
          success: true,
          paymentUrl: responseData['payment_url'] as String?,
          transactionId: responseData['transaction_id'] as String?,
          status: PaymentStatus.pending,
          metadata: responseData as Map<String, dynamic>?,
        );
      } else {
        AppLogger.logE('Ошибка создания платежа СБП: ${response.statusCode} - ${response.body}', 'bank_integration');
        return PaymentResult(
          success: false,
          error: 'Ошибка создания платежа: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.logE('Ошибка создания платежа СБП: $e', 'bank_integration');
      return PaymentResult(
        success: false,
        error: 'Ошибка создания платежа: $e',
      );
    }
  }

  /// Проверить статус платежа ЮKassa
  Future<PaymentStatus> checkYooKassaPaymentStatus(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.yookassa.ru/v3/payments/$transactionId'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_yookassaShopId:$_yookassaSecretKey'))}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return _mapYooKassaStatus(responseData['status'] as String);
      } else {
        AppLogger.logE('Ошибка проверки статуса платежа ЮKassa: ${response.statusCode}', 'bank_integration');
        return PaymentStatus.failed;
      }
    } catch (e) {
      AppLogger.logE('Ошибка проверки статуса платежа ЮKassa: $e', 'bank_integration');
      return PaymentStatus.failed;
    }
  }

  /// Проверить статус платежа СБП
  Future<PaymentStatus> checkSBPPaymentStatus(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.sbp.test/payment/status/$transactionId'),
        headers: {
          'Authorization': 'Bearer $_sbpSecretKey',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return _mapSBPStatus(responseData['status'] as String);
      } else {
        AppLogger.logE('Ошибка проверки статуса платежа СБП: ${response.statusCode}', 'bank_integration');
        return PaymentStatus.failed;
      }
    } catch (e) {
      AppLogger.logE('Ошибка проверки статуса платежа СБП: $e', 'bank_integration');
      return PaymentStatus.failed;
    }
  }

  /// Создать возврат через ЮKassa
  Future<RefundResult> createYooKassaRefund({
    required String paymentId,
    required double amount,
    required String reason,
  }) async {
    try {
      final requestId = _uuid.v4();
      
      final requestBody = {
        'amount': {
          'value': amount.toStringAsFixed(2),
          'currency': 'RUB',
        },
        'payment_id': paymentId,
        'description': reason,
      };

      final response = await http.post(
        Uri.parse('https://api.yookassa.ru/v3/refunds'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_yookassaShopId:$_yookassaSecretKey'))}',
          'Idempotence-Key': requestId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        return RefundResult(
          success: true,
          refundId: responseData['id'] as String?,
          status: _mapYooKassaRefundStatus(responseData['status'] as String),
          metadata: responseData as Map<String, dynamic>?,
        );
      } else {
        AppLogger.logE('Ошибка создания возврата ЮKassa: ${response.statusCode} - ${response.body}', 'bank_integration');
        return RefundResult(
          success: false,
          error: 'Ошибка создания возврата: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.logE('Ошибка создания возврата ЮKassa: $e', 'bank_integration');
      return RefundResult(
        success: false,
        error: 'Ошибка создания возврата: $e',
      );
    }
  }

  /// Создать возврат через СБП
  Future<RefundResult> createSBPRefund({
    required String paymentId,
    required double amount,
    required String reason,
  }) async {
    try {
      final requestId = _uuid.v4();
      
      final requestBody = {
        'payment_id': paymentId,
        'amount': amount.toStringAsFixed(2),
        'reason': reason,
        'request_id': requestId,
      };

      final response = await http.post(
        Uri.parse('https://api.sbp.test/refund/create'),
        headers: {
          'Authorization': 'Bearer $_sbpSecretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        return RefundResult(
          success: true,
          refundId: responseData['refund_id'] as String?,
          status: 'pending',
          metadata: responseData as Map<String, dynamic>?,
        );
      } else {
        AppLogger.logE('Ошибка создания возврата СБП: ${response.statusCode} - ${response.body}', 'bank_integration');
        return RefundResult(
          success: false,
          error: 'Ошибка создания возврата: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.logE('Ошибка создания возврата СБП: $e', 'bank_integration');
      return RefundResult(
        success: false,
        error: 'Ошибка создания возврата: $e',
      );
    }
  }

  /// Маппинг статуса ЮKassa в наш статус
  PaymentStatus _mapYooKassaStatus(String yookassaStatus) {
    switch (yookassaStatus) {
      case 'pending':
        return PaymentStatus.pending;
      case 'waiting_for_capture':
        return PaymentStatus.processing;
      case 'succeeded':
        return PaymentStatus.completed;
      case 'canceled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.failed;
    }
  }

  /// Маппинг статуса СБП в наш статус
  PaymentStatus _mapSBPStatus(String sbpStatus) {
    switch (sbpStatus) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'completed':
        return PaymentStatus.completed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.failed;
    }
  }

  /// Маппинг статуса возврата ЮKassa
  String _mapYooKassaRefundStatus(String yookassaStatus) {
    switch (yookassaStatus) {
      case 'pending':
        return 'pending';
      case 'succeeded':
        return 'completed';
      case 'canceled':
        return 'cancelled';
      default:
        return 'failed';
    }
  }

  /// Получить доступные методы оплаты
  List<PaymentMethod> getAvailablePaymentMethods() {
    return [
      PaymentMethod.card,
      PaymentMethod.sbp,
      PaymentMethod.yookassa,
    ];
  }

  /// Проверить, поддерживается ли метод оплаты
  bool isPaymentMethodSupported(PaymentMethod method) {
    return getAvailablePaymentMethods().contains(method);
  }

  /// Получить комиссию за платёж
  double getPaymentFee(PaymentMethod method, double amount) {
    switch (method) {
      case PaymentMethod.card:
        return amount * 0.029; // 2.9%
      case PaymentMethod.sbp:
        return amount * 0.01; // 1%
      case PaymentMethod.yookassa:
        return amount * 0.029; // 2.9%
      case PaymentMethod.bankTransfer:
        return 0.0; // Без комиссии
    }
  }

  /// Получить минимальную сумму платежа
  double getMinimumPaymentAmount(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 1.0;
      case PaymentMethod.sbp:
        return 1.0;
      case PaymentMethod.yookassa:
        return 1.0;
      case PaymentMethod.bankTransfer:
        return 100.0;
    }
  }

  /// Получить максимальную сумму платежа
  double getMaximumPaymentAmount(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 1000000.0;
      case PaymentMethod.sbp:
        return 1000000.0;
      case PaymentMethod.yookassa:
        return 1000000.0;
      case PaymentMethod.bankTransfer:
        return 10000000.0;
    }
  }
}

/// Результат создания платежа
class PaymentResult {
  const PaymentResult({
    required this.success,
    this.paymentUrl,
    this.transactionId,
    this.status,
    this.error,
    this.metadata,
  });

  final bool success;
  final String? paymentUrl;
  final String? transactionId;
  final PaymentStatus? status;
  final String? error;
  final Map<String, dynamic>? metadata;
}

/// Результат создания возврата
class RefundResult {
  const RefundResult({
    required this.success,
    this.refundId,
    this.status,
    this.error,
    this.metadata,
  });

  final bool success;
  final String? refundId;
  final String? status;
  final String? error;
  final Map<String, dynamic>? metadata;
} 
 