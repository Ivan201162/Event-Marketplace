import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_models.dart';
import '../services/payment_service.dart';
import '../services/tax_calculation_service.dart';

// Services
final paymentServiceProvider = Provider((ref) => PaymentService());
final taxCalculationServiceProvider =
    Provider((ref) => TaxCalculationService());

// Payment state
final paymentStateProvider =
    StateNotifierProvider<PaymentStateNotifier, PaymentState>((ref) {
  return PaymentStateNotifier(
    ref.read(paymentServiceProvider),
    ref.read(taxCalculationServiceProvider),
  );
});

// Payment statistics
final paymentStatisticsProvider =
    FutureProvider.family<PaymentStatistics, PaymentStatisticsParams>(
        (ref, params) {
  return ref.read(paymentServiceProvider).getPaymentStatistics(
        customerId: params.customerId,
        specialistId: params.specialistId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
});

// Customer payments
final customerPaymentsProvider =
    StreamProvider.family<List<Payment>, String>((ref, customerId) {
  return ref.read(paymentServiceProvider).getCustomerPayments(customerId);
});

// Specialist payments
final specialistPaymentsProvider =
    StreamProvider.family<List<Payment>, String>((ref, specialistId) {
  return ref.read(paymentServiceProvider).getSpecialistPayments(specialistId);
});

// Payment by ID
final paymentProvider =
    StreamProvider.family<Payment?, String>((ref, paymentId) {
  return ref.read(paymentServiceProvider).getPayment(paymentId);
});

// Tax calculation
final taxCalculationProvider =
    FutureProvider.family<TaxCalculation, TaxCalculationParams>((ref, params) {
  return ref.read(taxCalculationServiceProvider).calculateTax(
        amount: params.amount,
        legalStatus: params.legalStatus,
        region: params.region,
      );
});

// Payment State Notifier
class PaymentStateNotifier extends StateNotifier<PaymentState> {
  final PaymentService _paymentService;
  final TaxCalculationService _taxCalculationService;

  PaymentStateNotifier(this._paymentService, this._taxCalculationService)
      : super(PaymentState.initial());

  Future<void> createPayment({
    required String bookingId,
    required double amount,
    required PaymentType type,
    required PaymentMethod method,
    required String customerId,
    required String specialistId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final payment = await _paymentService.createPayment(
        bookingId: bookingId,
        amount: amount,
        type: type,
        method: method,
        customerId: customerId,
        specialistId: specialistId,
      );

      state = state.copyWith(
        isLoading: false,
        currentPayment: payment,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> completePayment(String paymentId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _paymentService.completePayment(paymentId);

      // Update current payment if it's the same
      if (state.currentPayment?.id == paymentId) {
        final updatedPayment = state.currentPayment!.copyWith(
          status: PaymentStatus.completed,
          completedAt: DateTime.now(),
        );
        state = state.copyWith(
          isLoading: false,
          currentPayment: updatedPayment,
          error: null,
        );
      } else {
        state = state.copyWith(isLoading: false, error: null);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> cancelPayment(String paymentId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _paymentService.cancelPayment(paymentId);

      // Update current payment if it's the same
      if (state.currentPayment?.id == paymentId) {
        final updatedPayment = state.currentPayment!.copyWith(
          status: PaymentStatus.cancelled,
          cancelledAt: DateTime.now(),
        );
        state = state.copyWith(
          isLoading: false,
          currentPayment: updatedPayment,
          error: null,
        );
      } else {
        state = state.copyWith(isLoading: false, error: null);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refundPayment(String paymentId,
      {double? amount, String? reason}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _paymentService.refundPayment(paymentId,
          amount: amount, reason: reason);
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearCurrentPayment() {
    state = state.copyWith(currentPayment: null);
  }
}

// Payment State
class PaymentState {
  final bool isLoading;
  final Payment? currentPayment;
  final String? error;

  PaymentState({
    required this.isLoading,
    this.currentPayment,
    this.error,
  });

  factory PaymentState.initial() {
    return PaymentState(isLoading: false);
  }

  PaymentState copyWith({
    bool? isLoading,
    Payment? currentPayment,
    String? error,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      currentPayment: currentPayment ?? this.currentPayment,
      error: error ?? this.error,
    );
  }
}

// Payment Statistics Parameters
class PaymentStatisticsParams {
  final String? customerId;
  final String? specialistId;
  final DateTime? startDate;
  final DateTime? endDate;

  PaymentStatisticsParams({
    this.customerId,
    this.specialistId,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentStatisticsParams &&
        other.customerId == customerId &&
        other.specialistId == specialistId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return customerId.hashCode ^
        specialistId.hashCode ^
        startDate.hashCode ^
        endDate.hashCode;
  }
}

// Tax Calculation Parameters
class TaxCalculationParams {
  final double amount;
  final LegalStatus legalStatus;
  final String region;

  TaxCalculationParams({
    required this.amount,
    required this.legalStatus,
    required this.region,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaxCalculationParams &&
        other.amount == amount &&
        other.legalStatus == legalStatus &&
        other.region == region;
  }

  @override
  int get hashCode {
    return amount.hashCode ^ legalStatus.hashCode ^ region.hashCode;
  }
}
