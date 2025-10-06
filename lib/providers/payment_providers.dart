import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment.dart';
import '../services/firestore_service.dart';
import '../services/payment_service.dart';

/// Провайдер для сервиса платежей
final paymentServiceProvider =
    Provider<PaymentService>((ref) => PaymentService());

/// Провайдер для FirestoreService
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

/// Провайдер для получения платежей пользователя
final userPaymentsProvider =
    StreamProvider.family<List<Payment>, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.paymentsByUserStream(userId);
});

/// Провайдер для получения платежей специалиста
final specialistPaymentsProvider =
    StreamProvider.family<List<Payment>, String>((ref, specialistId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.paymentsBySpecialistStream(specialistId);
});

/// Провайдер для получения платежей по бронированию
final bookingPaymentsProvider =
    StreamProvider.family<List<Payment>, String>((ref, bookingId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.paymentsByBookingStream(bookingId);
});

/// Провайдер для получения платежа по ID
final paymentByIdProvider =
    FutureProvider.family<Payment?, String>((ref, paymentId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getPaymentById(paymentId);
});

/// Провайдер для проверки оплаты предоплаты
final prepaymentStatusProvider =
    FutureProvider.family<bool, String>((ref, bookingId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.isPrepaymentPaid(bookingId);
});

/// Провайдер для статистики платежей пользователя
final userPaymentStatsProvider =
    FutureProvider.family<PaymentStats, String>((ref, userId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserPaymentStats(userId);
});

/// Провайдер для статистики платежей специалиста
final specialistPaymentStatsProvider =
    FutureProvider.family<PaymentStats, String>((ref, specialistId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getSpecialistPaymentStats(specialistId);
});

/// Провайдер для управления платежами
final paymentManagerProvider =
    StateNotifierProvider<PaymentManager, AsyncValue<void>>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PaymentManager(paymentService, firestoreService);
});

/// Менеджер для управления платежами
class PaymentManager extends StateNotifier<AsyncValue<void>> {
  PaymentManager(this._paymentService, this._firestoreService)
      : super(const AsyncValue.data(null));

  final PaymentService _paymentService;
  final FirestoreService _firestoreService;

  /// Создать платеж
  Future<String?> createPayment({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required double amount,
    required PaymentType type,
    PaymentMethod method = PaymentMethod.card,
    String? description,
    String? customerName,
    String? specialistName,
    String? bookingTitle,
  }) async {
    state = const AsyncValue.loading();

    try {
      final paymentId = await _paymentService.createPayment(
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        amount: amount,
        type: type,
        method: method,
        description: description,
        customerName: customerName,
        specialistName: specialistName,
        bookingTitle: bookingTitle,
      );

      state = const AsyncValue.data(null);
      return paymentId;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Пометить платеж как оплаченный
  Future<bool> markAsPaid({
    required String paymentId,
    String? transactionId,
    String? receiptUrl,
  }) async {
    state = const AsyncValue.loading();

    try {
      final success = await _paymentService.markAsPaid(
        paymentId: paymentId,
        transactionId: transactionId,
        receiptUrl: receiptUrl,
      );

      if (success) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = const AsyncValue.error(
          'Не удалось обновить статус платежа',
          StackTrace.current,
        );
        return false;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Пометить платеж как неудачный
  Future<bool> markAsFailed({
    required String paymentId,
    String? reason,
  }) async {
    state = const AsyncValue.loading();

    try {
      final success = await _paymentService.markAsFailed(
        paymentId: paymentId,
        reason: reason,
      );

      if (success) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = const AsyncValue.error(
          'Не удалось обновить статус платежа',
          StackTrace.current,
        );
        return false;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Отменить платеж
  Future<bool> cancelPayment({
    required String paymentId,
    String? reason,
  }) async {
    state = const AsyncValue.loading();

    try {
      final success = await _paymentService.cancelPayment(
        paymentId: paymentId,
        reason: reason,
      );

      if (success) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = const AsyncValue.error(
          'Не удалось отменить платеж',
          StackTrace.current,
        );
        return false;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Возврат платежа
  Future<bool> refundPayment({
    required String paymentId,
    double? refundAmount,
    String? reason,
  }) async {
    state = const AsyncValue.loading();

    try {
      final success = await _paymentService.refundPayment(
        paymentId: paymentId,
        refundAmount: refundAmount,
        reason: reason,
      );

      if (success) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = const AsyncValue.error(
          'Не удалось вернуть платеж',
          StackTrace.current,
        );
        return false;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Создать предоплату для бронирования
  Future<String?> createPrepaymentForBooking({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required double totalAmount,
    double prepaymentPercentage = 0.3,
    String? customerName,
    String? specialistName,
    String? bookingTitle,
  }) async {
    state = const AsyncValue.loading();

    try {
      final paymentId = await _paymentService.createPrepaymentForBooking(
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        totalAmount: totalAmount,
        prepaymentPercentage: prepaymentPercentage,
        customerName: customerName,
        specialistName: specialistName,
        bookingTitle: bookingTitle,
      );

      if (paymentId != null) {
        state = const AsyncValue.data(null);
        return paymentId;
      } else {
        state = const AsyncValue.error(
          'Не удалось создать предоплату',
          StackTrace.current,
        );
        return null;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }
}

/// Провайдер для получения платежей с фильтрацией
final filteredPaymentsProvider =
    StreamProvider.family<List<Payment>, PaymentFilter>((ref, filter) {
  final firestoreService = ref.watch(firestoreServiceProvider);

  if (filter.userId != null) {
    return firestoreService.paymentsByUserStream(filter.userId!);
  } else if (filter.specialistId != null) {
    return firestoreService.paymentsBySpecialistStream(filter.specialistId!);
  } else if (filter.bookingId != null) {
    return firestoreService.paymentsByBookingStream(filter.bookingId!);
  }

  return Stream.value([]);
});

/// Фильтр для платежей
class PaymentFilter {
  const PaymentFilter({
    this.userId,
    this.specialistId,
    this.bookingId,
    this.status,
    this.type,
    this.method,
    this.startDate,
    this.endDate,
  });

  final String? userId;
  final String? specialistId;
  final String? bookingId;
  final PaymentStatus? status;
  final PaymentType? type;
  final PaymentMethod? method;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Копировать с изменениями
  PaymentFilter copyWith({
    String? userId,
    String? specialistId,
    String? bookingId,
    PaymentStatus? status,
    PaymentType? type,
    PaymentMethod? method,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      PaymentFilter(
        userId: userId ?? this.userId,
        specialistId: specialistId ?? this.specialistId,
        bookingId: bookingId ?? this.bookingId,
        status: status ?? this.status,
        type: type ?? this.type,
        method: method ?? this.method,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
      );

  /// Проверить, применены ли фильтры
  bool get hasFilters =>
      userId != null ||
      specialistId != null ||
      bookingId != null ||
      status != null ||
      type != null ||
      method != null ||
      startDate != null ||
      endDate != null;

  /// Сбросить все фильтры
  PaymentFilter clear() => const PaymentFilter();
}

/// Провайдер для получения платежей по статусу
final paymentsByStatusProvider =
    StreamProvider.family<List<Payment>, Map<String, dynamic>>((ref, params) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = params['userId'] as String?;
  final specialistId = params['specialistId'] as String?;
  final status = params['status'] as PaymentStatus?;

  if (userId != null) {
    return firestoreService.paymentsByUserStream(userId).map((payments) {
      if (status != null) {
        return payments.where((payment) => payment.status == status).toList();
      }
      return payments;
    });
  } else if (specialistId != null) {
    return firestoreService
        .paymentsBySpecialistStream(specialistId)
        .map((payments) {
      if (status != null) {
        return payments.where((payment) => payment.status == status).toList();
      }
      return payments;
    });
  }

  return Stream.value([]);
});

/// Провайдер для получения платежей по типу
final paymentsByTypeProvider =
    StreamProvider.family<List<Payment>, Map<String, dynamic>>((ref, params) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = params['userId'] as String?;
  final specialistId = params['specialistId'] as String?;
  final type = params['type'] as PaymentType?;

  if (userId != null) {
    return firestoreService.paymentsByUserStream(userId).map((payments) {
      if (type != null) {
        return payments.where((payment) => payment.type == type).toList();
      }
      return payments;
    });
  } else if (specialistId != null) {
    return firestoreService
        .paymentsBySpecialistStream(specialistId)
        .map((payments) {
      if (type != null) {
        return payments.where((payment) => payment.type == type).toList();
      }
      return payments;
    });
  }

  return Stream.value([]);
});

/// Провайдер для получения ожидающих платежей
final pendingPaymentsProvider = StreamProvider.family<List<Payment>, String>(
  (ref, userId) => ref.watch(
    paymentsByStatusProvider({
      'userId': userId,
      'status': PaymentStatus.pending,
    }),
  ),
);

/// Провайдер для получения завершенных платежей
final completedPaymentsProvider = StreamProvider.family<List<Payment>, String>(
  (ref, userId) => ref.watch(
    paymentsByStatusProvider({
      'userId': userId,
      'status': PaymentStatus.completed,
    }),
  ),
);

/// Провайдер для получения предоплат
final prepaymentsProvider = StreamProvider.family<List<Payment>, String>(
  (ref, userId) => ref.watch(
    paymentsByTypeProvider({
      'userId': userId,
      'type': PaymentType.prepayment,
    }),
  ),
);
