import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/subscription_plan.dart';
import '../models/promotion_boost.dart';
import '../models/advertisement.dart';
import '../config/payment_config.dart';

enum PaymentProvider {
  stripe,
  yookassa,
  cloudPayments,
  tinkoffPay,
}

enum PaymentMethod {
  card,
  applePay,
  googlePay,
  yooMoney,
  qiwi,
  webmoney,
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? externalTransactionId;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.externalTransactionId,
    this.errorMessage,
    this.metadata,
  });
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final String _baseUrl = 'https://api.stripe.com/v1';
  final String _yookassaUrl = 'https://api.yookassa.ru/v3';

  /// Создание платежа для подписки
  Future<PaymentResult> createSubscriptionPayment({
    required String userId,
    required SubscriptionPlan plan,
    required PaymentMethod paymentMethod,
    PaymentProvider provider = PaymentProvider.stripe,
  }) async {
    try {
      debugPrint(
          'INFO: [payment_service] Создание платежа для подписки ${plan.name}');

      final amount = (plan.price * 100).round(); // Конвертируем в копейки

      switch (provider) {
        case PaymentProvider.stripe:
          return await _createStripePayment(
            amount: amount,
            currency: PaymentConfig.defaultCurrency.toLowerCase(),
            description: 'Подписка ${plan.name}',
            metadata: {
              'type': 'subscription',
              'planId': plan.id,
              'userId': userId,
              'durationDays': plan.durationDays.toString(),
            },
          );
        case PaymentProvider.yookassa:
          return await _createYooKassaPayment(
            amount: amount,
            currency: PaymentConfig.defaultCurrency,
            description: 'Подписка ${plan.name}',
            metadata: {
              'type': 'subscription',
              'planId': plan.id,
              'userId': userId,
              'durationDays': plan.durationDays.toString(),
            },
          );
        default:
          throw Exception('Неподдерживаемый провайдер платежей');
      }
    } catch (e) {
      debugPrint(
          'ERROR: [payment_service] Ошибка создания платежа подписки: $e');
      return PaymentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Создание платежа для продвижения
  Future<PaymentResult> createPromotionPayment({
    required String userId,
    required PromotionPackage package,
    required PaymentMethod paymentMethod,
    PaymentProvider provider = PaymentProvider.stripe,
  }) async {
    try {
      debugPrint(
          'INFO: [payment_service] Создание платежа для продвижения ${package.name}');

      final amount = (package.price * 100).round();

      switch (provider) {
        case PaymentProvider.stripe:
          return await _createStripePayment(
            amount: amount,
            currency: PaymentConfig.defaultCurrency.toLowerCase(),
            description: 'Продвижение ${package.name}',
            metadata: {
              'type': 'promotion',
              'packageId': package.id,
              'userId': userId,
              'durationDays': package.durationDays.toString(),
              'priorityLevel': package.priorityLevel.toString(),
            },
          );
        case PaymentProvider.yookassa:
          return await _createYooKassaPayment(
            amount: amount,
            currency: PaymentConfig.defaultCurrency,
            description: 'Продвижение ${package.name}',
            metadata: {
              'type': 'promotion',
              'packageId': package.id,
              'userId': userId,
              'durationDays': package.durationDays.toString(),
              'priorityLevel': package.priorityLevel.toString(),
            },
          );
        default:
          throw Exception('Неподдерживаемый провайдер платежей');
      }
    } catch (e) {
      debugPrint(
          'ERROR: [payment_service] Ошибка создания платежа продвижения: $e');
      return PaymentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Создание платежа для рекламы
  Future<PaymentResult> createAdvertisementPayment({
    required String userId,
    required Advertisement ad,
    required PaymentMethod paymentMethod,
    PaymentProvider provider = PaymentProvider.stripe,
  }) async {
    try {
      debugPrint('INFO: [payment_service] Создание платежа для рекламы');

      final amount = (ad.price * 100).round();

      switch (provider) {
        case PaymentProvider.stripe:
          return await _createStripePayment(
            amount: amount,
            currency: PaymentConfig.defaultCurrency.toLowerCase(),
            description: 'Реклама ${ad.title ?? 'Без названия'}',
            metadata: {
              'type': 'advertisement',
              'adId': ad.id,
              'userId': userId,
              'adType': ad.type.toString(),
              'placement': ad.placement.toString(),
            },
          );
        case PaymentProvider.yookassa:
          return await _createYooKassaPayment(
            amount: amount,
            currency: PaymentConfig.defaultCurrency,
            description: 'Реклама ${ad.title ?? 'Без названия'}',
            metadata: {
              'type': 'advertisement',
              'adId': ad.id,
              'userId': userId,
              'adType': ad.type.toString(),
              'placement': ad.placement.toString(),
            },
          );
        default:
          throw Exception('Неподдерживаемый провайдер платежей');
      }
    } catch (e) {
      debugPrint(
          'ERROR: [payment_service] Ошибка создания платежа рекламы: $e');
      return PaymentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Создание платежа через Stripe
  Future<PaymentResult> _createStripePayment({
    required int amount,
    required String currency,
    required String description,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer ${PaymentConfig.stripeSecretKey}',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      final body = {
        'amount': amount.toString(),
        'currency': currency,
        'description': description,
        'metadata':
            metadata.map((key, value) => MapEntry(key, value.toString())),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentResult(
          success: true,
          externalTransactionId: data['id'],
          metadata: data,
        );
      } else {
        final error = json.decode(response.body);
        return PaymentResult(
          success: false,
          errorMessage: error['error']?['message'] ?? 'Ошибка платежа',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Ошибка соединения с Stripe: $e',
      );
    }
  }

  /// Создание платежа через YooKassa
  Future<PaymentResult> _createYooKassaPayment({
    required int amount,
    required String currency,
    required String description,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final headers = {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${PaymentConfig.yookassaShopId}:${PaymentConfig.yookassaSecretKey}'))}',
        'Content-Type': 'application/json',
        'Idempotence-Key': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final body = {
        'amount': {
          'value': (amount / 100).toStringAsFixed(2),
          'currency': currency,
        },
        'confirmation': {
          'type': 'redirect',
          'return_url': 'https://eventmarketplace.app/payment/success',
        },
        'description': description,
        'metadata': metadata,
      };

      final response = await http.post(
        Uri.parse('$_yookassaUrl/payments'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentResult(
          success: true,
          externalTransactionId: data['id'],
          metadata: data,
        );
      } else {
        final error = json.decode(response.body);
        return PaymentResult(
          success: false,
          errorMessage: error['description'] ?? 'Ошибка платежа',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Ошибка соединения с YooKassa: $e',
      );
    }
  }

  /// Подтверждение платежа
  Future<PaymentResult> confirmPayment({
    required String externalTransactionId,
    required PaymentProvider provider,
  }) async {
    try {
      debugPrint(
          'INFO: [payment_service] Подтверждение платежа $externalTransactionId');

      switch (provider) {
        case PaymentProvider.stripe:
          return await _confirmStripePayment(externalTransactionId);
        case PaymentProvider.yookassa:
          return await _confirmYooKassaPayment(externalTransactionId);
        default:
          throw Exception('Неподдерживаемый провайдер платежей');
      }
    } catch (e) {
      debugPrint('ERROR: [payment_service] Ошибка подтверждения платежа: $e');
      return PaymentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Подтверждение платежа Stripe
  Future<PaymentResult> _confirmStripePayment(String paymentIntentId) async {
    try {
      final headers = {
        'Authorization': 'Bearer ${PaymentConfig.stripeSecretKey}',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];

        return PaymentResult(
          success: status == 'succeeded',
          externalTransactionId: paymentIntentId,
          metadata: data,
        );
      } else {
        return PaymentResult(
          success: false,
          errorMessage: 'Ошибка получения статуса платежа',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Ошибка соединения с Stripe: $e',
      );
    }
  }

  /// Подтверждение платежа YooKassa
  Future<PaymentResult> _confirmYooKassaPayment(String paymentId) async {
    try {
      final headers = {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${PaymentConfig.yookassaShopId}:${PaymentConfig.yookassaSecretKey}'))}',
      };

      final response = await http.get(
        Uri.parse('$_yookassaUrl/payments/$paymentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];

        return PaymentResult(
          success: status == 'succeeded',
          externalTransactionId: paymentId,
          metadata: data,
        );
      } else {
        return PaymentResult(
          success: false,
          errorMessage: 'Ошибка получения статуса платежа',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Ошибка соединения с YooKassa: $e',
      );
    }
  }

  /// Возврат средств
  Future<PaymentResult> refundPayment({
    required String externalTransactionId,
    required double amount,
    required PaymentProvider provider,
    String? reason,
  }) async {
    try {
      debugPrint(
          'INFO: [payment_service] Возврат средств $externalTransactionId');

      switch (provider) {
        case PaymentProvider.stripe:
          return await _refundStripePayment(
              externalTransactionId, amount, reason);
        case PaymentProvider.yookassa:
          return await _refundYooKassaPayment(
              externalTransactionId, amount, reason);
        default:
          throw Exception('Неподдерживаемый провайдер платежей');
      }
    } catch (e) {
      debugPrint('ERROR: [payment_service] Ошибка возврата средств: $e');
      return PaymentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Возврат средств через Stripe
  Future<PaymentResult> _refundStripePayment(
      String paymentIntentId, double amount, String? reason) async {
    try {
      final headers = {
        'Authorization': 'Bearer ${PaymentConfig.stripeSecretKey}',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      final body = {
        'payment_intent': paymentIntentId,
        'amount': (amount * 100).round().toString(),
        if (reason != null) 'reason': reason,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/refunds'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentResult(
          success: true,
          externalTransactionId: data['id'],
          metadata: data,
        );
      } else {
        final error = json.decode(response.body);
        return PaymentResult(
          success: false,
          errorMessage: error['error']?['message'] ?? 'Ошибка возврата',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Ошибка соединения с Stripe: $e',
      );
    }
  }

  /// Возврат средств через YooKassa
  Future<PaymentResult> _refundYooKassaPayment(
      String paymentId, double amount, String? reason) async {
    try {
      final headers = {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${PaymentConfig.yookassaShopId}:${PaymentConfig.yookassaSecretKey}'))}',
        'Content-Type': 'application/json',
        'Idempotence-Key': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final body = {
        'amount': {
          'value': amount.toStringAsFixed(2),
          'currency': PaymentConfig.defaultCurrency,
        },
        if (reason != null) 'description': reason,
      };

      final response = await http.post(
        Uri.parse('$_yookassaUrl/refunds'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentResult(
          success: true,
          externalTransactionId: data['id'],
          metadata: data,
        );
      } else {
        final error = json.decode(response.body);
        return PaymentResult(
          success: false,
          errorMessage: error['description'] ?? 'Ошибка возврата',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Ошибка соединения с YooKassa: $e',
      );
    }
  }

  /// Получение истории транзакций пользователя
  Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      // Здесь должна быть интеграция с вашей базой данных
      // Возвращаем пустой список для примера
      return [];
    } catch (e) {
      debugPrint(
          'ERROR: [payment_service] Ошибка получения истории транзакций: $e');
      return [];
    }
  }

  /// Проверка статуса платежа
  Future<TransactionStatus> getPaymentStatus(
      String externalTransactionId, PaymentProvider provider) async {
    try {
      final result = await confirmPayment(
        externalTransactionId: externalTransactionId,
        provider: provider,
      );

      if (result.success) {
        return TransactionStatus.success;
      } else {
        return TransactionStatus.failed;
      }
    } catch (e) {
      debugPrint(
          'ERROR: [payment_service] Ошибка проверки статуса платежа: $e');
      return TransactionStatus.failed;
    }
  }
}
