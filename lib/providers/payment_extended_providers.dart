import 'package:event_marketplace_app/models/payment_extended.dart';
import 'package:event_marketplace_app/services/payment_extended_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для сервиса расширенных платежей
final paymentExtendedServiceProvider = Provider<PaymentExtendedService>(
  (ref) => PaymentExtendedService(),
);

/// Провайдер для платежей пользователя
final userPaymentsProvider =
    StreamProvider.family<List<PaymentExtended>, (String, bool)>((
  ref,
  params,
) {
  final (userId, isCustomer) = params;
  final service = ref.read(paymentExtendedServiceProvider);
  return service.getUserPayments(userId, isCustomer: isCustomer);
});

/// Провайдер для конкретного платежа
final paymentProvider =
    FutureProvider.family<PaymentExtended?, String>((ref, paymentId) {
  final service = ref.read(paymentExtendedServiceProvider);
  return service.getPayment(paymentId);
});

/// Провайдер для статистики платежей
final paymentStatsProvider =
    FutureProvider.family<PaymentStats, (String, bool)>((ref, params) {
  final (userId, isCustomer) = params;
  final service = ref.read(paymentExtendedServiceProvider);
  return service.getPaymentStats(userId, isCustomer: isCustomer);
});

/// Провайдер для настроек предоплаты
final advancePaymentSettingsProvider =
    FutureProvider<AdvancePaymentSettings>((ref) {
  final service = ref.read(paymentExtendedServiceProvider);
  return service.getAdvancePaymentSettings();
});

/// Провайдер для ожидающих платежей
final pendingPaymentsProvider =
    StreamProvider.family<List<PaymentExtended>, (String, bool)>((
  ref,
  params,
) {
  final (userId, isCustomer) = params;
  return ref.watch(userPaymentsProvider(params)).when(
        data: (payments) => Stream.value(
          payments
              .where(
                (p) =>
                    p.status == PaymentStatus.pending ||
                    p.status == PaymentStatus.processing,
              )
              .toList(),
        ),
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Провайдер для завершенных платежей
final completedPaymentsProvider =
    StreamProvider.family<List<PaymentExtended>, (String, bool)>((
  ref,
  params,
) {
  final (userId, isCustomer) = params;
  return ref.watch(userPaymentsProvider(params)).when(
        data: (payments) => Stream.value(payments
            .where((p) => p.status == PaymentStatus.completed)
            .toList(),),
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Провайдер для платежей с просрочкой
final overduePaymentsProvider =
    StreamProvider.family<List<PaymentExtended>, (String, bool)>((
  ref,
  params,
) {
  final (userId, isCustomer) = params;
  return ref.watch(userPaymentsProvider(params)).when(
        data: (payments) =>
            Stream.value(payments.where((p) => p.hasOverduePayments).toList()),
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Провайдер для платежей по типу
final paymentsByTypeProvider =
    StreamProvider.family<List<PaymentExtended>, (String, bool, PaymentType)>(
        (ref, params) {
  final (userId, isCustomer, type) = params;
  return ref.watch(userPaymentsProvider((userId, isCustomer))).when(
        data: (payments) =>
            Stream.value(payments.where((p) => p.type == type).toList()),
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Провайдер для платежей по статусу
final paymentsByStatusProvider =
    StreamProvider.family<List<PaymentExtended>, (String, bool, PaymentStatus)>(
        (ref, params) {
  final (userId, isCustomer, status) = params;
  return ref.watch(userPaymentsProvider((userId, isCustomer))).when(
        data: (payments) =>
            Stream.value(payments.where((p) => p.status == status).toList()),
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Провайдер для общей суммы платежей
final totalPaymentsAmountProvider =
    StreamProvider.family<double, (String, bool)>((ref, params) {
  final (userId, isCustomer) = params;
  return ref.watch(userPaymentsProvider(params)).when(
        data: (payments) =>
            Stream.value(payments.fold(0, (sum, p) => sum + p.totalAmount)),
        loading: () => Stream.value(0),
        error: (_, __) => Stream.value(0),
      );
});

/// Провайдер для оплаченной суммы
final paidAmountProvider =
    StreamProvider.family<double, (String, bool)>((ref, params) {
  final (userId, isCustomer) = params;
  return ref.watch(userPaymentsProvider(params)).when(
        data: (payments) =>
            Stream.value(payments.fold(0, (sum, p) => sum + p.paidAmount)),
        loading: () => Stream.value(0),
        error: (_, __) => Stream.value(0),
      );
});

/// Провайдер для оставшейся суммы
final remainingAmountProvider =
    StreamProvider.family<double, (String, bool)>((ref, params) {
  final (userId, isCustomer) = params;
  return ref.watch(userPaymentsProvider(params)).when(
        data: (payments) =>
            Stream.value(payments.fold(0, (sum, p) => sum + p.remainingAmount)),
        loading: () => Stream.value(0),
        error: (_, __) => Stream.value(0),
      );
});

/// Провайдер для процента оплаты
final paymentProgressProvider =
    StreamProvider.family<double, (String, bool)>((ref, params) {
  final (userId, isCustomer) = params;
  return ref.watch(userPaymentsProvider(params)).when(
        data: (payments) {
          final totalAmount = payments.fold(0, (sum, p) => sum + p.totalAmount);
          final paidAmount = payments.fold(0, (sum, p) => sum + p.paidAmount);
          final progress =
              totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0.0;
          return Stream.value(progress);
        },
        loading: () => Stream.value(0),
        error: (_, __) => Stream.value(0),
      );
});

/// Провайдер для количества платежей
final paymentsCountProvider =
    StreamProvider.family<int, (String, bool)>((ref, params) {
  final (userId, isCustomer) = params;
  return ref.watch(userPaymentsProvider(params)).when(
        data: (payments) => Stream.value(payments.length),
        loading: () => Stream.value(0),
        error: (_, __) => Stream.value(0),
      );
});

/// Провайдер для следующего платежа
final nextPaymentProvider =
    StreamProvider.family<PaymentExtended?, (String, bool)>((ref, params) {
  final (userId, isCustomer) = params;
  return ref.watch(userPaymentsProvider(params)).when(
        data: (payments) {
          final pendingPayments = payments
              .where(
                (p) =>
                    p.status == PaymentStatus.pending ||
                    p.status == PaymentStatus.processing,
              )
              .toList();

          if (pendingPayments.isEmpty) return Stream.value(null);

          // Находим платеж с ближайшей датой
          pendingPayments.sort((a, b) {
            final aNext = a.nextPayment;
            final bNext = b.nextPayment;

            if (aNext == null && bNext == null) return 0;
            if (aNext == null) return 1;
            if (bNext == null) return -1;

            return aNext.dueDate.compareTo(bNext.dueDate);
          });

          return Stream.value(pendingPayments.first);
        },
        loading: () => Stream.value(null),
        error: (_, __) => Stream.value(null),
      );
});

/// Провайдер для уведомлений о платежах
final paymentNotificationsProvider =
    StreamProvider.family<List<PaymentExtended>, (String, bool)>((
  ref,
  params,
) {
  final (userId, isCustomer) = params;
  return ref.watch(userPaymentsProvider(params)).when(
        data: (payments) {
          final now = DateTime.now();
          final notifications = payments.where((p) {
            // Платежи с просрочкой
            if (p.hasOverduePayments) return true;

            // Платежи, срок которых истекает в ближайшие 3 дня
            final nextPayment = p.nextPayment;
            if (nextPayment != null) {
              final daysUntilDue = nextPayment.dueDate.difference(now).inDays;
              return daysUntilDue <= 3 && daysUntilDue >= 0;
            }

            return false;
          }).toList();

          return Stream.value(notifications);
        },
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Провайдер для фильтрации платежей
final filteredPaymentsProvider =
    StreamProvider.family<List<PaymentExtended>, (String, bool, PaymentFilter)>(
        (ref, params) {
  final (userId, isCustomer, filter) = params;
  return ref.watch(userPaymentsProvider((userId, isCustomer))).when(
        data: (payments) {
          var filtered = payments;

          // Фильтр по типу
          if (filter.type != null) {
            filtered = filtered.where((p) => p.type == filter.type).toList();
          }

          // Фильтр по статусу
          if (filter.status != null) {
            filtered =
                filtered.where((p) => p.status == filter.status).toList();
          }

          // Фильтр по дате
          if (filter.startDate != null) {
            filtered = filtered
                .where((p) => p.createdAt.isAfter(filter.startDate!))
                .toList();
          }

          if (filter.endDate != null) {
            filtered = filtered
                .where((p) => p.createdAt.isBefore(filter.endDate!))
                .toList();
          }

          // Фильтр по сумме
          if (filter.minAmount != null) {
            filtered = filtered
                .where((p) => p.totalAmount >= filter.minAmount!)
                .toList();
          }

          if (filter.maxAmount != null) {
            filtered = filtered
                .where((p) => p.totalAmount <= filter.maxAmount!)
                .toList();
          }

          // Сортировка
          switch (filter.sortBy) {
            case PaymentSortBy.date:
              filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            case PaymentSortBy.amount:
              filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
            case PaymentSortBy.status:
              filtered.sort((a, b) => a.status.name.compareTo(b.status.name));
            case PaymentSortBy.type:
              filtered.sort((a, b) => a.type.name.compareTo(b.type.name));
          }

          return Stream.value(filtered);
        },
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Фильтр для платежей
class PaymentFilter {
  const PaymentFilter({
    this.type,
    this.status,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.sortBy = PaymentSortBy.date,
  });
  final PaymentType? type;
  final PaymentStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final PaymentSortBy sortBy;

  PaymentFilter copyWith({
    PaymentType? type,
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    PaymentSortBy? sortBy,
  }) =>
      PaymentFilter(
        type: type ?? this.type,
        status: status ?? this.status,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        minAmount: minAmount ?? this.minAmount,
        maxAmount: maxAmount ?? this.maxAmount,
        sortBy: sortBy ?? this.sortBy,
      );
}

/// Сортировка платежей
enum PaymentSortBy { date, amount, status, type }

/// Нотификатор для фильтра платежей
class PaymentFilterNotifier extends Notifier<PaymentFilter> {
  @override
  PaymentFilter build() => const PaymentFilter();

  void updateFilter(PaymentFilter filter) {
    state = filter;
  }

  void resetFilter() {
    state = const PaymentFilter();
  }
}

/// Провайдер для фильтра платежей
final paymentFilterProvider =
    NotifierProvider<PaymentFilterNotifier, PaymentFilter>(
  PaymentFilterNotifier.new,
);

/// Провайдер для поиска платежей
final paymentSearchProvider =
    StreamProvider.family<List<PaymentExtended>, (String, bool, String)>((
  ref,
  params,
) {
  final (userId, isCustomer, query) = params;
  return ref.watch(userPaymentsProvider((userId, isCustomer))).when(
        data: (payments) {
          if (query.isEmpty) return Stream.value(payments);

          final filtered = payments
              .where(
                (p) =>
                    p.id.toLowerCase().contains(query.toLowerCase()) ||
                    p.bookingId.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

          return Stream.value(filtered);
        },
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});
