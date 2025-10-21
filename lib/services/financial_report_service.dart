import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';

/// Сервис для генерации финансовых отчетов
class FinancialReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать отчет по платежам для заказчика
  Future<CustomerPaymentReport> generateCustomerPaymentReport({
    required String customerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final payments = await _getPaymentsForPeriod(
        userId: customerId,
        startDate: startDate,
        endDate: endDate,
      );

      final totalSpent = payments
          .where((p) => p.status == PaymentStatus.completed)
          .fold<double>(0, (sum, payment) => sum + payment.amount);

      final totalRefunded = payments
          .where((p) => p.status == PaymentStatus.refunded)
          .fold<double>(0, (sum, payment) => sum + payment.amount);

      final completedPayments = payments.where((p) => p.status == PaymentStatus.completed).length;

      final pendingPayments = payments.where((p) => p.status == PaymentStatus.pending).length;

      final failedPayments = payments.where((p) => p.status == PaymentStatus.failed).length;

      final refundedPayments = payments.where((p) => p.status == PaymentStatus.refunded).length;

      // Группировка по месяцам
      final monthlyBreakdown = _groupPaymentsByMonth(payments);

      // Группировка по типам платежей
      final typeBreakdown = _groupPaymentsByType(payments);

      return CustomerPaymentReport(
        customerId: customerId,
        period:
            '${startDate.toIso8601String().split('T')[0]} - ${endDate.toIso8601String().split('T')[0]}',
        totalSpent: totalSpent,
        totalRefunded: totalRefunded,
        netSpent: totalSpent - totalRefunded,
        totalPayments: payments.length,
        completedPayments: completedPayments,
        pendingPayments: pendingPayments,
        failedPayments: failedPayments,
        refundedPayments: refundedPayments,
        monthlyBreakdown: monthlyBreakdown,
        typeBreakdown: typeBreakdown,
        generatedAt: DateTime.now(),
      );
    } on Exception catch (e) {
      debugPrint('Error generating customer payment report: $e');
      throw Exception('Ошибка генерации отчета по платежам: $e');
    }
  }

  /// Создать отчет по доходам для специалиста
  Future<SpecialistIncomeReport> generateSpecialistIncomeReport({
    required String specialistId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final payments = await _getPaymentsForPeriod(
        specialistId: specialistId,
        startDate: startDate,
        endDate: endDate,
      );

      // Фильтруем только входящие платежи (доходы)
      final incomePayments = payments
          .where(
            (p) =>
                p.status == PaymentStatus.completed &&
                (p.type == PaymentType.deposit || p.type == PaymentType.finalPayment),
          )
          .toList();

      final totalIncome = incomePayments.fold<double>(0, (sum, payment) => sum + payment.amount);

      final totalFees = incomePayments.fold<double>(
        0,
        (sum, payment) => sum + (payment.fee ?? 0.0),
      );

      final totalTaxes = incomePayments.fold<double>(
        0,
        (sum, payment) => sum + (payment.tax ?? 0.0),
      );

      final netIncome = totalIncome - totalFees - totalTaxes;

      final totalBookings = incomePayments.length;
      final averageBookingValue = totalBookings > 0 ? totalIncome / totalBookings : 0.0;

      // Группировка по месяцам
      final monthlyBreakdown = _groupPaymentsByMonth(incomePayments);

      // Группировка по типам платежей
      final typeBreakdown = _groupPaymentsByType(incomePayments);

      // Статистика по методам оплаты
      final paymentMethodStats = _groupPaymentsByMethod(incomePayments);

      return SpecialistIncomeReport(
        specialistId: specialistId,
        period:
            '${startDate.toIso8601String().split('T')[0]} - ${endDate.toIso8601String().split('T')[0]}',
        totalIncome: totalIncome,
        totalFees: totalFees,
        totalTaxes: totalTaxes,
        netIncome: netIncome,
        totalBookings: totalBookings,
        averageBookingValue: averageBookingValue,
        monthlyBreakdown: monthlyBreakdown,
        typeBreakdown: typeBreakdown,
        paymentMethodStats: paymentMethodStats,
        generatedAt: DateTime.now(),
      );
    } on Exception catch (e) {
      debugPrint('Error generating specialist income report: $e');
      throw Exception('Ошибка генерации отчета по доходам: $e');
    }
  }

  /// Получить платежи за период
  Future<List<Payment>> _getPaymentsForPeriod({
    String? userId,
    String? specialistId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection('payments');

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    if (specialistId != null) {
      query = query.where('specialistId', isEqualTo: specialistId);
    }

    query = query
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('createdAt', descending: true);

    final querySnapshot = await query.get();
    return querySnapshot.docs.map(Payment.fromDocument).toList();
  }

  /// Группировать платежи по месяцам
  Map<String, double> _groupPaymentsByMonth(List<Payment> payments) {
    final monthlyBreakdown = <String, double>{};

    for (final payment in payments) {
      final monthKey =
          '${payment.createdAt.year}-${payment.createdAt.month.toString().padLeft(2, '0')}';
      monthlyBreakdown[monthKey] = (monthlyBreakdown[monthKey] ?? 0.0) + payment.amount;
    }

    return monthlyBreakdown;
  }

  /// Группировать платежи по типам
  Map<String, double> _groupPaymentsByType(List<Payment> payments) {
    final typeBreakdown = <String, double>{};

    for (final payment in payments) {
      final typeKey = payment.typeName;
      typeBreakdown[typeKey] = (typeBreakdown[typeKey] ?? 0.0) + payment.amount;
    }

    return typeBreakdown;
  }

  /// Группировать платежи по методам оплаты
  Map<String, double> _groupPaymentsByMethod(List<Payment> payments) {
    final methodStats = <String, double>{};

    for (final payment in payments) {
      final methodKey = payment.methodName;
      methodStats[methodKey] = (methodStats[methodKey] ?? 0.0) + payment.amount;
    }

    return methodStats;
  }

  /// Получить историю транзакций
  Future<List<Payment>> getTransactionHistory({
    required String userId,
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      var query = _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map(Payment.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Error getting transaction history: $e');
      throw Exception('Ошибка получения истории транзакций: $e');
    }
  }

  /// Получить статистику платежей за последние 12 месяцев
  Future<Map<String, double>> getMonthlyStats({
    required String userId,
    bool isSpecialist = false,
  }) async {
    try {
      final now = DateTime.now();
      final twelveMonthsAgo = DateTime(now.year - 1, now.month, now.day);

      final payments = await _getPaymentsForPeriod(
        userId: isSpecialist ? null : userId,
        specialistId: isSpecialist ? userId : null,
        startDate: twelveMonthsAgo,
        endDate: now,
      );

      return _groupPaymentsByMonth(payments);
    } on Exception catch (e) {
      debugPrint('Error getting monthly stats: $e');
      return {};
    }
  }
}

/// Отчет по платежам для заказчика
class CustomerPaymentReport {
  const CustomerPaymentReport({
    required this.customerId,
    required this.period,
    required this.totalSpent,
    required this.totalRefunded,
    required this.netSpent,
    required this.totalPayments,
    required this.completedPayments,
    required this.pendingPayments,
    required this.failedPayments,
    required this.refundedPayments,
    required this.monthlyBreakdown,
    required this.typeBreakdown,
    required this.generatedAt,
  });

  final String customerId;
  final String period;
  final double totalSpent;
  final double totalRefunded;
  final double netSpent;
  final int totalPayments;
  final int completedPayments;
  final int pendingPayments;
  final int failedPayments;
  final int refundedPayments;
  final Map<String, double> monthlyBreakdown;
  final Map<String, double> typeBreakdown;
  final DateTime generatedAt;

  /// Форматировать общую потраченную сумму
  String get formattedTotalSpent => '${totalSpent.toStringAsFixed(2)} ₽';

  /// Форматировать общую возвращенную сумму
  String get formattedTotalRefunded => '${totalRefunded.toStringAsFixed(2)} ₽';

  /// Форматировать чистую потраченную сумму
  String get formattedNetSpent => '${netSpent.toStringAsFixed(2)} ₽';
}

/// Отчет по доходам для специалиста
class SpecialistIncomeReport {
  const SpecialistIncomeReport({
    required this.specialistId,
    required this.period,
    required this.totalIncome,
    required this.totalFees,
    required this.totalTaxes,
    required this.netIncome,
    required this.totalBookings,
    required this.averageBookingValue,
    required this.monthlyBreakdown,
    required this.typeBreakdown,
    required this.paymentMethodStats,
    required this.generatedAt,
  });

  final String specialistId;
  final String period;
  final double totalIncome;
  final double totalFees;
  final double totalTaxes;
  final double netIncome;
  final int totalBookings;
  final double averageBookingValue;
  final Map<String, double> monthlyBreakdown;
  final Map<String, double> typeBreakdown;
  final Map<String, double> paymentMethodStats;
  final DateTime generatedAt;

  /// Форматировать общий доход
  String get formattedTotalIncome => '${totalIncome.toStringAsFixed(2)} ₽';

  /// Форматировать общие комиссии
  String get formattedTotalFees => '${totalFees.toStringAsFixed(2)} ₽';

  /// Форматировать общие налоги
  String get formattedTotalTaxes => '${totalTaxes.toStringAsFixed(2)} ₽';

  /// Форматировать чистый доход
  String get formattedNetIncome => '${netIncome.toStringAsFixed(2)} ₽';

  /// Форматировать среднюю стоимость заказа
  String get formattedAverageBookingValue => '${averageBookingValue.toStringAsFixed(2)} ₽';
}
