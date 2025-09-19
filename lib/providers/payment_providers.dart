import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/feature_flags.dart';
import '../payments/payment_gateway.dart';
import '../payments/payment_gateway_mock.dart';

/// Провайдер платежного шлюза
final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  // Всегда используем mock-реализацию, так как платежи отключены через FeatureFlags
  return PaymentGatewayMock();
});

/// Провайдер для проверки доступности платежей
final paymentsAvailableProvider =
    Provider<bool>((ref) => FeatureFlags.paymentsEnabled);

/// Провайдер для инициализации платежей
final paymentInitializationProvider = FutureProvider<void>((ref) async {
  final paymentGateway = ref.read(paymentGatewayProvider);
  await paymentGateway.initialize();
});

/// Провайдер доступных способов оплаты
final availablePaymentMethodsProvider = Provider<List<PaymentMethod>>((ref) {
  final paymentGateway = ref.read(paymentGatewayProvider);
  if (!paymentGateway.isAvailable) return [];

  return paymentGateway.getAvailablePaymentMethods();
});

/// Провайдер информации о платеже
final paymentInfoProvider =
    FutureProvider.family<PaymentInfo?, String>((ref, paymentId) async {
  final paymentGateway = ref.read(paymentGatewayProvider);
  if (!paymentGateway.isAvailable) return null;

  return paymentGateway.getPaymentInfo(paymentId);
});

/// Провайдер истории платежей для бронирования
final paymentHistoryProvider =
    FutureProvider.family<List<PaymentInfo>, String>((ref, bookingId) async {
  final paymentGateway = ref.read(paymentGatewayProvider);
  if (!paymentGateway.isAvailable) return [];

  return paymentGateway.getPaymentHistory(bookingId);
});

/// Провайдер для платежей специалиста
final paymentsBySpecialistProvider =
    FutureProvider.family<List<PaymentInfo>, String>((ref, userId) async {
  // TODO: Реализовать получение платежей специалиста
  return [];
});

/// Провайдер для платежей клиента
final paymentsByCustomerProvider =
    FutureProvider.family<List<PaymentInfo>, String>((ref, userId) async {
  // TODO: Реализовать получение платежей клиента
  return [];
});

/// Провайдер для статистики платежей
final paymentStatisticsProvider =
    FutureProvider.family<PaymentStatistics, PaymentStatisticsParams>(
        (ref, params) async {
  // TODO: Реализовать получение статистики платежей
  return const PaymentStatistics(
    totalCount: 0,
    totalAmount: 0,
    completedCount: 0,
    completedAmount: 0,
    pendingCount: 0,
    pendingAmount: 0,
    failedCount: 0,
    completionRate: 0,
  );
});

/// Параметры для статистики платежей
class PaymentStatisticsParams {
  const PaymentStatisticsParams({
    required this.userId,
    required this.isSpecialist,
  });
  final String userId;
  final bool isSpecialist;
}

/// Статистика платежей
class PaymentStatistics {
  const PaymentStatistics({
    required this.totalCount,
    required this.totalAmount,
    required this.completedCount,
    required this.completedAmount,
    required this.pendingCount,
    required this.pendingAmount,
    required this.failedCount,
    required this.completionRate,
  });
  final int totalCount;
  final double totalAmount;
  final int completedCount;
  final double completedAmount;
  final int pendingCount;
  final double pendingAmount;
  final int failedCount;
  final double completionRate;
}
