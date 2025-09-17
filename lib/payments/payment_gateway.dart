/// Статус платежа
enum PaymentStatus {
  pending, // Ожидает обработки
  processing, // Обрабатывается
  completed, // Завершен
  failed, // Неудачный
  cancelled, // Отменен
  refunded, // Возвращен
}

/// Тип платежа
enum PaymentType {
  prepayment, // Предоплата
  finalPayment, // Финальный платеж
  fullPayment, // Полная оплата
  refund, // Возврат
}

/// Способ оплаты
enum PaymentMethod {
  card, // Банковская карта
  applePay, // Apple Pay
  googlePay, // Google Pay
  yooMoney, // ЮMoney
  qiwi, // QIWI
  webmoney, // WebMoney
  bankTransfer, // Банковский перевод
}

/// Результат платежа
class PaymentResult {
  final String paymentId;
  final PaymentStatus status;
  final String? transactionId;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const PaymentResult({
    required this.paymentId,
    required this.status,
    this.transactionId,
    this.errorMessage,
    this.metadata,
  });

  bool get isSuccess => status == PaymentStatus.completed;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isPending => status == PaymentStatus.pending;
}

/// Информация о платеже
class PaymentInfo {
  final String id;
  final String bookingId;
  final double amount;
  final String currency;
  final PaymentType type;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? description;
  final Map<String, dynamic>? metadata;

  const PaymentInfo({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.method,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.description,
    this.metadata,
  });
}

/// Абстрактный шлюз для платежей
abstract class PaymentGateway {
  /// Инициализация платежного шлюза
  Future<void> initialize();

  /// Проверить, доступен ли платежный шлюз
  bool get isAvailable;

  /// Получить доступные способы оплаты
  List<PaymentMethod> getAvailablePaymentMethods();

  /// Создать платеж
  Future<PaymentResult> createPayment({
    required String bookingId,
    required double amount,
    required String currency,
    required PaymentType type,
    required PaymentMethod method,
    String? description,
    Map<String, dynamic>? metadata,
  });

  /// Подтвердить платеж
  Future<PaymentResult> confirmPayment(String paymentId);

  /// Отменить платеж
  Future<PaymentResult> cancelPayment(String paymentId);

  /// Возврат платежа
  Future<PaymentResult> refundPayment(String paymentId, {double? amount});

  /// Получить информацию о платеже
  Future<PaymentInfo?> getPaymentInfo(String paymentId);

  /// Получить историю платежей для бронирования
  Future<List<PaymentInfo>> getPaymentHistory(String bookingId);

  /// Проверить статус платежа
  Future<PaymentStatus> checkPaymentStatus(String paymentId);

  /// Валидировать платежную информацию
  Future<bool> validatePaymentData({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardholderName,
  });

  /// Получить комиссию за платеж
  Future<double> getPaymentFee({
    required double amount,
    required PaymentMethod method,
  });

  /// Получить минимальную сумму платежа
  double getMinimumAmount();

  /// Получить максимальную сумму платежа
  double getMaximumAmount();

  /// Получить поддерживаемые валюты
  List<String> getSupportedCurrencies();

  /// Обработать webhook уведомление
  Future<void> processWebhook(Map<String, dynamic> webhookData);

  /// Очистить ресурсы
  void dispose();
}
