import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../payments/payment_gateway.dart';
import '../payments/payment_gateway_mock.dart';
import '../core/feature_flags.dart';

/// Провайдер платежного шлюза
final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  // Всегда используем mock-реализацию, так как платежи отключены через FeatureFlags
  return PaymentGatewayMock();
});

/// Провайдер для проверки доступности платежей
final paymentsAvailableProvider = Provider<bool>((ref) {
  return FeatureFlags.paymentsEnabled;
});

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
final paymentInfoProvider = FutureProvider.family<PaymentInfo?, String>((ref, paymentId) async {
  final paymentGateway = ref.read(paymentGatewayProvider);
  if (!paymentGateway.isAvailable) return null;
  
  return await paymentGateway.getPaymentInfo(paymentId);
});

/// Провайдер истории платежей для бронирования
final paymentHistoryProvider = FutureProvider.family<List<PaymentInfo>, String>((ref, bookingId) async {
  final paymentGateway = ref.read(paymentGatewayProvider);
  if (!paymentGateway.isAvailable) return [];
  
  return await paymentGateway.getPaymentHistory(bookingId);
});