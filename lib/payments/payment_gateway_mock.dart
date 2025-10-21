import 'dart:math';
import '../core/feature_flags.dart';
import '../core/safe_log.dart';
import 'payment_gateway.dart';

/// Mock-реализация платежного шлюза
class PaymentGatewayMock implements PaymentGateway {
  bool _isInitialized = false;
  final Map<String, PaymentInfo> _payments = {};
  final Random _random = Random();

  @override
  Future<void> initialize() async {
    if (!FeatureFlags.paymentsEnabled) {
      SafeLog.info('PaymentGatewayMock: Payments are disabled via feature flag');
      return;
    }

    SafeLog.info('PaymentGatewayMock: Initializing mock payment gateway');
    _isInitialized = true;
  }

  @override
  bool get isAvailable => FeatureFlags.paymentsEnabled && _isInitialized;

  @override
  List<PaymentMethod> getAvailablePaymentMethods() {
    if (!FeatureFlags.paymentsEnabled) {
      return [];
    }

    return [
      PaymentMethod.card,
      PaymentMethod.applePay,
      PaymentMethod.googlePay,
      PaymentMethod.yooMoney,
      PaymentMethod.qiwi,
    ];
  }

  @override
  Future<PaymentResult> createPayment({
    required String bookingId,
    required double amount,
    required String currency,
    required PaymentType type,
    required PaymentMethod method,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    if (!FeatureFlags.paymentsEnabled) {
      SafeLog.info('PaymentGatewayMock: Payment creation disabled');
      return const PaymentResult(
        paymentId: '',
        status: PaymentStatus.failed,
        errorMessage: 'Платежи отключены',
      );
    }

    SafeLog.info(
      'PaymentGatewayMock: Creating payment for booking $bookingId, amount: $amount $currency',
    );

    // Валидация
    if (amount < getMinimumAmount()) {
      return PaymentResult(
        paymentId: '',
        status: PaymentStatus.failed,
        errorMessage: 'Сумма меньше минимальной (${getMinimumAmount()} $currency)',
      );
    }

    if (amount > getMaximumAmount()) {
      return PaymentResult(
        paymentId: '',
        status: PaymentStatus.failed,
        errorMessage: 'Сумма больше максимальной (${getMaximumAmount()} $currency)',
      );
    }

    if (!getSupportedCurrencies().contains(currency)) {
      return PaymentResult(
        paymentId: '',
        status: PaymentStatus.failed,
        errorMessage: 'Неподдерживаемая валюта: $currency',
      );
    }

    // Создаем mock платеж
    final paymentId =
        'mock_payment_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
    final transactionId = 'txn_${_random.nextInt(1000000)}';

    // Имитируем задержку обработки
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));

    // 90% успешных платежей
    final isSuccess = _random.nextDouble() > 0.1;
    final status = isSuccess ? PaymentStatus.completed : PaymentStatus.failed;

    final paymentInfo = PaymentInfo(
      id: paymentId,
      bookingId: bookingId,
      amount: amount,
      currency: currency,
      type: type,
      method: method,
      status: status,
      createdAt: DateTime.now(),
      completedAt: isSuccess ? DateTime.now() : null,
      description: description,
      metadata: metadata,
    );

    _payments[paymentId] = paymentInfo;

    SafeLog.info('PaymentGatewayMock: Payment $paymentId created with status $status');

    return PaymentResult(
      paymentId: paymentId,
      status: status,
      transactionId: isSuccess ? transactionId : null,
      errorMessage: isSuccess ? null : 'Mock ошибка платежа',
      metadata: {'mock': true, 'processing_time': '${500 + _random.nextInt(1000)}ms'},
    );
  }

  @override
  Future<PaymentResult> confirmPayment(String paymentId) async {
    if (!FeatureFlags.paymentsEnabled) {
      SafeLog.info('PaymentGatewayMock: Payment confirmation disabled');
      return PaymentResult(
        paymentId: paymentId,
        status: PaymentStatus.failed,
        errorMessage: 'Платежи отключены',
      );
    }

    SafeLog.info('PaymentGatewayMock: Confirming payment $paymentId');

    final payment = _payments[paymentId];
    if (payment == null) {
      return PaymentResult(
        paymentId: paymentId,
        status: PaymentStatus.failed,
        errorMessage: 'Платеж не найден',
      );
    }

    if (payment.status != PaymentStatus.pending) {
      return PaymentResult(
        paymentId: paymentId,
        status: payment.status,
        errorMessage: 'Платеж уже обработан',
      );
    }

    // Имитируем задержку
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(500)));

    // 95% успешных подтверждений
    final isSuccess = _random.nextDouble() > 0.05;
    final newStatus = isSuccess ? PaymentStatus.completed : PaymentStatus.failed;

    _payments[paymentId] = PaymentInfo(
      id: payment.id,
      bookingId: payment.bookingId,
      amount: payment.amount,
      currency: payment.currency,
      type: payment.type,
      method: payment.method,
      status: newStatus,
      createdAt: payment.createdAt,
      completedAt: isSuccess ? DateTime.now() : null,
      description: payment.description,
      metadata: payment.metadata,
    );

    SafeLog.info('PaymentGatewayMock: Payment $paymentId confirmed with status $newStatus');

    return PaymentResult(
      paymentId: paymentId,
      status: newStatus,
      transactionId: isSuccess ? 'txn_${_random.nextInt(1000000)}' : null,
      errorMessage: isSuccess ? null : 'Mock ошибка подтверждения',
    );
  }

  @override
  Future<PaymentResult> cancelPayment(String paymentId) async {
    if (!FeatureFlags.paymentsEnabled) {
      SafeLog.info('PaymentGatewayMock: Payment cancellation disabled');
      return PaymentResult(
        paymentId: paymentId,
        status: PaymentStatus.failed,
        errorMessage: 'Платежи отключены',
      );
    }

    SafeLog.info('PaymentGatewayMock: Cancelling payment $paymentId');

    final payment = _payments[paymentId];
    if (payment == null) {
      return PaymentResult(
        paymentId: paymentId,
        status: PaymentStatus.failed,
        errorMessage: 'Платеж не найден',
      );
    }

    if (payment.status == PaymentStatus.completed) {
      return PaymentResult(
        paymentId: paymentId,
        status: PaymentStatus.failed,
        errorMessage: 'Нельзя отменить завершенный платеж',
      );
    }

    await Future.delayed(const Duration(milliseconds: 200));

    _payments[paymentId] = PaymentInfo(
      id: payment.id,
      bookingId: payment.bookingId,
      amount: payment.amount,
      currency: payment.currency,
      type: payment.type,
      method: payment.method,
      status: PaymentStatus.cancelled,
      createdAt: payment.createdAt,
      completedAt: DateTime.now(),
      description: payment.description,
      metadata: payment.metadata,
    );

    SafeLog.info('PaymentGatewayMock: Payment $paymentId cancelled');

    return PaymentResult(paymentId: paymentId, status: PaymentStatus.cancelled);
  }

  @override
  Future<PaymentResult> refundPayment(String paymentId, {double? amount}) async {
    if (!FeatureFlags.paymentsEnabled) {
      SafeLog.info('PaymentGatewayMock: Payment refund disabled');
      return PaymentResult(
        paymentId: paymentId,
        status: PaymentStatus.failed,
        errorMessage: 'Платежи отключены',
      );
    }

    SafeLog.info('PaymentGatewayMock: Refunding payment $paymentId');

    final payment = _payments[paymentId];
    if (payment == null) {
      return PaymentResult(
        paymentId: paymentId,
        status: PaymentStatus.failed,
        errorMessage: 'Платеж не найден',
      );
    }

    if (payment.status != PaymentStatus.completed) {
      return PaymentResult(
        paymentId: paymentId,
        status: PaymentStatus.failed,
        errorMessage: 'Можно вернуть только завершенный платеж',
      );
    }

    final refundAmount = amount ?? payment.amount;
    if (refundAmount > payment.amount) {
      return PaymentResult(
        paymentId: paymentId,
        status: PaymentStatus.failed,
        errorMessage: 'Сумма возврата не может превышать сумму платежа',
      );
    }

    await Future.delayed(Duration(milliseconds: 800 + _random.nextInt(1000)));

    // 98% успешных возвратов
    final isSuccess = _random.nextDouble() > 0.02;
    final newStatus = isSuccess ? PaymentStatus.refunded : PaymentStatus.failed;

    SafeLog.info('PaymentGatewayMock: Payment $paymentId refunded with status $newStatus');

    return PaymentResult(
      paymentId: paymentId,
      status: newStatus,
      transactionId: isSuccess ? 'refund_${_random.nextInt(1000000)}' : null,
      errorMessage: isSuccess ? null : 'Mock ошибка возврата',
    );
  }

  @override
  Future<PaymentInfo?> getPaymentInfo(String paymentId) async {
    if (!FeatureFlags.paymentsEnabled) {
      SafeLog.info('PaymentGatewayMock: Payment info retrieval disabled');
      return null;
    }

    SafeLog.info('PaymentGatewayMock: Getting payment info for $paymentId');

    await Future.delayed(const Duration(milliseconds: 100));
    return _payments[paymentId];
  }

  @override
  Future<List<PaymentInfo>> getPaymentHistory(String bookingId) async {
    if (!FeatureFlags.paymentsEnabled) {
      SafeLog.info('PaymentGatewayMock: Payment history retrieval disabled');
      return [];
    }

    SafeLog.info('PaymentGatewayMock: Getting payment history for booking $bookingId');

    await Future.delayed(const Duration(milliseconds: 200));

    return _payments.values.where((payment) => payment.bookingId == bookingId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<PaymentStatus> checkPaymentStatus(String paymentId) async {
    if (!FeatureFlags.paymentsEnabled) {
      SafeLog.info('PaymentGatewayMock: Payment status check disabled');
      return PaymentStatus.failed;
    }

    SafeLog.info('PaymentGatewayMock: Checking payment status for $paymentId');

    await Future.delayed(const Duration(milliseconds: 100));

    final payment = _payments[paymentId];
    return payment?.status ?? PaymentStatus.failed;
  }

  @override
  Future<bool> validatePaymentData({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardholderName,
  }) async {
    if (!FeatureFlags.paymentsEnabled) {
      SafeLog.info('PaymentGatewayMock: Payment validation disabled');
      return false;
    }

    SafeLog.info('PaymentGatewayMock: Validating payment data');

    await Future.delayed(const Duration(milliseconds: 300));

    // Простая валидация
    if (cardNumber.length < 16 || cardNumber.length > 19) return false;
    if (cvv.length < 3 || cvv.length > 4) return false;
    if (cardholderName.trim().isEmpty) return false;

    // Валидация даты истечения
    try {
      final parts = expiryDate.split('/');
      if (parts.length != 2) return false;

      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);

      if (month < 1 || month > 12) return false;
      if (year < DateTime.now().year % 100) return false;
    } catch (e) {
      return false;
    }

    return true;
  }

  @override
  Future<double> getPaymentFee({required double amount, required PaymentMethod method}) async {
    if (!FeatureFlags.paymentsEnabled) {
      return 0.0;
    }

    SafeLog.info('PaymentGatewayMock: Calculating payment fee for amount $amount, method $method');

    await Future.delayed(const Duration(milliseconds: 100));

    // Mock комиссии
    switch (method) {
      case PaymentMethod.card:
        return amount * 0.029 + 30; // 2.9% + 30 руб
      case PaymentMethod.applePay:
      case PaymentMethod.googlePay:
        return amount * 0.025 + 25; // 2.5% + 25 руб
      case PaymentMethod.yooMoney:
        return amount * 0.02 + 20; // 2% + 20 руб
      case PaymentMethod.qiwi:
        return amount * 0.03 + 35; // 3% + 35 руб
      case PaymentMethod.webmoney:
        return amount * 0.035 + 40; // 3.5% + 40 руб
      case PaymentMethod.bankTransfer:
        return 0.0; // Без комиссии
    }
  }

  @override
  double getMinimumAmount() => 1;

  @override
  double getMaximumAmount() => 1000000;

  @override
  List<String> getSupportedCurrencies() => ['RUB', 'USD', 'EUR'];

  @override
  Future<void> processWebhook(Map<String, dynamic> webhookData) async {
    if (!FeatureFlags.paymentsEnabled) {
      SafeLog.info('PaymentGatewayMock: Webhook processing disabled');
      return;
    }

    SafeLog.info('PaymentGatewayMock: Processing webhook: $webhookData');

    // Mock обработка webhook
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    SafeLog.info('PaymentGatewayMock: Disposing mock payment gateway');
    _payments.clear();
    _isInitialized = false;
  }
}
