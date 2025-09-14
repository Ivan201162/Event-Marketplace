import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/payment_service.dart';
import '../models/payment.dart';
import '../models/booking.dart';

/// Провайдер сервиса платежей
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

/// Провайдер платежей по заявке
final paymentsByBookingProvider = StreamProvider.family<List<Payment>, String>((ref, bookingId) {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getPaymentsByBookingStream(bookingId);
});

/// Провайдер платежей по клиенту
final paymentsByCustomerProvider = StreamProvider.family<List<Payment>, String>((ref, customerId) {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getPaymentsByCustomerStream(customerId);
});

/// Провайдер платежей по специалисту
final paymentsBySpecialistProvider = StreamProvider.family<List<Payment>, String>((ref, specialistId) {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getPaymentsBySpecialistStream(specialistId);
});

/// Провайдер статистики платежей
final paymentStatisticsProvider = FutureProvider.family<PaymentStatistics, PaymentStatisticsParams>((ref, params) {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getPaymentStatistics(params.userId, isSpecialist: params.isSpecialist);
});

/// Провайдер для управления состоянием платежей
final paymentStateProvider = StateNotifierProvider<PaymentStateNotifier, PaymentState>((ref) {
  return PaymentStateNotifier(ref.read(paymentServiceProvider));
});

/// Состояние платежей
class PaymentState {
  final bool isLoading;
  final String? errorMessage;
  final List<Payment> recentPayments;
  final PaymentStatistics? statistics;

  const PaymentState({
    this.isLoading = false,
    this.errorMessage,
    this.recentPayments = const [],
    this.statistics,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Payment>? recentPayments,
    PaymentStatistics? statistics,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      recentPayments: recentPayments ?? this.recentPayments,
      statistics: statistics ?? this.statistics,
    );
  }
}

/// Нотификатор состояния платежей
class PaymentStateNotifier extends StateNotifier<PaymentState> {
  final PaymentService _paymentService;

  PaymentStateNotifier(this._paymentService) : super(const PaymentState());

  /// Создать платежи для заявки
  Future<void> createPaymentsForBooking({
    required Booking booking,
    required OrganizationType organizationType,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _paymentService.createPaymentsForBooking(
        booking: booking,
        organizationType: organizationType,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Обработать платеж
  Future<void> processPayment(String paymentId, String paymentMethod) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _paymentService.processPayment(paymentId, paymentMethod);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Отменить платеж
  Future<void> cancelPayment(String paymentId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _paymentService.cancelPayment(paymentId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Создать возврат
  Future<void> createRefund({
    required String originalPaymentId,
    required double amount,
    required String reason,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _paymentService.createRefund(
        originalPaymentId: originalPaymentId,
        amount: amount,
        reason: reason,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Параметры для статистики платежей
class PaymentStatisticsParams {
  final String userId;
  final bool isSpecialist;

  const PaymentStatisticsParams({
    required this.userId,
    required this.isSpecialist,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentStatisticsParams &&
        other.userId == userId &&
        other.isSpecialist == isSpecialist;
  }

  @override
  int get hashCode => userId.hashCode ^ isSpecialist.hashCode;
}

/// Провайдер для управления формой платежа
final paymentFormProvider = StateNotifierProvider<PaymentFormNotifier, PaymentFormState>((ref) {
  return PaymentFormNotifier();
});

/// Состояние формы платежа
class PaymentFormState {
  final String selectedPaymentMethod;
  final bool isProcessing;
  final String? errorMessage;
  final Map<String, dynamic> formData;

  const PaymentFormState({
    this.selectedPaymentMethod = 'card',
    this.isProcessing = false,
    this.errorMessage,
    this.formData = const {},
  });

  PaymentFormState copyWith({
    String? selectedPaymentMethod,
    bool? isProcessing,
    String? errorMessage,
    Map<String, dynamic>? formData,
  }) {
    return PaymentFormState(
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
      formData: formData ?? this.formData,
    );
  }
}

/// Нотификатор формы платежа
class PaymentFormNotifier extends StateNotifier<PaymentFormState> {
  PaymentFormNotifier() : super(const PaymentFormState());

  /// Выбрать метод оплаты
  void selectPaymentMethod(String method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  /// Обновить данные формы
  void updateFormData(String key, dynamic value) {
    final newFormData = Map<String, dynamic>.from(state.formData);
    newFormData[key] = value;
    state = state.copyWith(formData: newFormData);
  }

  /// Начать обработку
  void startProcessing() {
    state = state.copyWith(isProcessing: true, errorMessage: null);
  }

  /// Завершить обработку
  void finishProcessing() {
    state = state.copyWith(isProcessing: false);
  }

  /// Установить ошибку
  void setError(String error) {
    state = state.copyWith(
      isProcessing: false,
      errorMessage: error,
    );
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Сбросить форму
  void reset() {
    state = const PaymentFormState();
  }
}

/// Провайдер для конфигурации платежей
final paymentConfigurationProvider = Provider.family<PaymentConfiguration, OrganizationType>((ref, organizationType) {
  return PaymentConfiguration.getDefault(organizationType);
});

/// Провайдер для расчета платежей
final paymentCalculationProvider = Provider.family<PaymentCalculation, PaymentCalculationParams>((ref, params) {
  final config = ref.watch(paymentConfigurationProvider(params.organizationType));
  
  final advanceAmount = config.calculateAdvanceAmount(params.totalAmount);
  final finalAmount = config.calculateFinalAmount(params.totalAmount, advanceAmount);
  
  return PaymentCalculation(
    totalAmount: params.totalAmount,
    advanceAmount: advanceAmount,
    finalAmount: finalAmount,
    advancePercentage: config.advancePercentage,
    requiresAdvance: config.requiresAdvance,
    allowsPostPayment: config.allowsPostPayment,
  );
});

/// Параметры для расчета платежей
class PaymentCalculationParams {
  final double totalAmount;
  final OrganizationType organizationType;

  const PaymentCalculationParams({
    required this.totalAmount,
    required this.organizationType,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentCalculationParams &&
        other.totalAmount == totalAmount &&
        other.organizationType == organizationType;
  }

  @override
  int get hashCode => totalAmount.hashCode ^ organizationType.hashCode;
}

/// Результат расчета платежей
class PaymentCalculation {
  final double totalAmount;
  final double advanceAmount;
  final double finalAmount;
  final double advancePercentage;
  final bool requiresAdvance;
  final bool allowsPostPayment;

  const PaymentCalculation({
    required this.totalAmount,
    required this.advanceAmount,
    required this.finalAmount,
    required this.advancePercentage,
    required this.requiresAdvance,
    required this.allowsPostPayment,
  });

  /// Проверить, требуется ли аванс
  bool get hasAdvance => advanceAmount > 0;

  /// Проверить, есть ли финальный платеж
  bool get hasFinalPayment => finalAmount > 0;

  /// Получить описание платежной схемы
  String get paymentSchemeDescription {
    if (!requiresAdvance && allowsPostPayment) {
      return 'Постоплата (100% после выполнения)';
    } else if (requiresAdvance && !allowsPostPayment) {
      return 'Аванс ${advancePercentage.toInt()}% + доплата ${(100 - advancePercentage).toInt()}%';
    } else {
      return 'Гибкая схема оплаты';
    }
  }
}
