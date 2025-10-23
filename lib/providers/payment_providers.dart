import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment.dart';
import '../models/transaction.dart';
import '../services/payment_service.dart';

/// Payment service provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

/// User payments provider
final userPaymentsProvider =
    FutureProvider.family<List<Payment>, String>((ref, userId) async {
  final paymentService = ref.read(paymentServiceProvider);
  return paymentService.getUserPayments(userId);
});

/// Specialist payments provider
final specialistPaymentsProvider =
    FutureProvider.family<List<Payment>, String>((
  ref,
  specialistId,
) async {
  final paymentService = ref.read(paymentServiceProvider);
  return paymentService.getSpecialistPayments(specialistId);
});

/// Payment by ID provider
final paymentByIdProvider =
    FutureProvider.family<Payment?, String>((ref, paymentId) async {
  final paymentService = ref.read(paymentServiceProvider);
  return paymentService.getPaymentById(paymentId);
});

/// User transactions provider
final userTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((
  ref,
  userId,
) async {
  final paymentService = ref.read(paymentServiceProvider);
  return paymentService.getUserTransactions(userId);
});

/// User balance provider
final userBalanceProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final paymentService = ref.read(paymentServiceProvider);
  return paymentService.getUserBalance(userId);
});

/// Booking payments provider
final bookingPaymentsProvider = FutureProvider.family<List<Payment>, String>((
  ref,
  bookingId,
) async {
  final paymentService = ref.read(paymentServiceProvider);
  return paymentService.getBookingPayments(bookingId);
});

/// Payment statistics provider
final paymentStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  userId,
) async {
  final paymentService = ref.read(paymentServiceProvider);
  return paymentService.getPaymentStats(userId);
});

/// User payments stream provider
final userPaymentsStreamProvider =
    StreamProvider.family<List<Payment>, String>((ref, userId) {
  final paymentService = ref.read(paymentServiceProvider);
  return paymentService.getUserPaymentsStream(userId);
});

/// User transactions stream provider
final userTransactionsStreamProvider =
    StreamProvider.family<List<Transaction>, String>((
  ref,
  userId,
) {
  final paymentService = ref.read(paymentServiceProvider);
  return paymentService.getUserTransactionsStream(userId);
});

/// Recent payments provider
final recentPaymentsProvider =
    FutureProvider.family<List<Payment>, String>((ref, userId) async {
  final paymentService = ref.read(paymentServiceProvider);
  final payments = await paymentService.getUserPayments(userId);
  return payments.take(10).toList();
});

/// Recent transactions provider
final recentTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((
  ref,
  userId,
) async {
  final paymentService = ref.read(paymentServiceProvider);
  final transactions = await paymentService.getUserTransactions(userId);
  return transactions.take(20).toList();
});

/// Successful payments provider
final successfulPaymentsProvider =
    FutureProvider.family<List<Payment>, String>((
  ref,
  userId,
) async {
  final paymentService = ref.read(paymentServiceProvider);
  final payments = await paymentService.getUserPayments(userId);
  return payments.where((payment) => payment.isSuccessful).toList();
});

/// Failed payments provider
final failedPaymentsProvider =
    FutureProvider.family<List<Payment>, String>((ref, userId) async {
  final paymentService = ref.read(paymentServiceProvider);
  final payments = await paymentService.getUserPayments(userId);
  return payments.where((payment) => payment.isFailed).toList();
});

/// Pending payments provider
final pendingPaymentsProvider =
    FutureProvider.family<List<Payment>, String>((ref, userId) async {
  final paymentService = ref.read(paymentServiceProvider);
  final payments = await paymentService.getUserPayments(userId);
  return payments.where((payment) => payment.isPending).toList();
});

/// Income transactions provider
final incomeTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((
  ref,
  userId,
) async {
  final paymentService = ref.read(paymentServiceProvider);
  final transactions = await paymentService.getUserTransactions(userId);
  return transactions.where((transaction) => transaction.isIncome).toList();
});

/// Expense transactions provider
final expenseTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((
  ref,
  userId,
) async {
  final paymentService = ref.read(paymentServiceProvider);
  final transactions = await paymentService.getUserTransactions(userId);
  return transactions.where((transaction) => transaction.isExpense).toList();
});

/// Monthly income provider
final monthlyIncomeProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final paymentService = ref.read(paymentServiceProvider);
  final transactions = await paymentService.getUserTransactions(userId);

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month);

  final monthlyTransactions = transactions.where((transaction) {
    return transaction.isIncome && transaction.createdAt.isAfter(startOfMonth);
  }).toList();

  return monthlyTransactions.fold(
      0, (sum, transaction) => sum + transaction.amount);
});

/// Monthly expense provider
final monthlyExpenseProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final paymentService = ref.read(paymentServiceProvider);
  final transactions = await paymentService.getUserTransactions(userId);

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month);

  final monthlyTransactions = transactions.where((transaction) {
    return transaction.isExpense && transaction.createdAt.isAfter(startOfMonth);
  }).toList();

  return monthlyTransactions.fold(
      0, (sum, transaction) => sum + transaction.amount);
});

/// Total income provider
final totalIncomeProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final paymentService = ref.read(paymentServiceProvider);
  final transactions = await paymentService.getUserTransactions(userId);

  final incomeTransactions =
      transactions.where((transaction) => transaction.isIncome).toList();
  return incomeTransactions.fold(
      0, (sum, transaction) => sum + transaction.amount);
});

/// Total expense provider
final totalExpenseProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final paymentService = ref.read(paymentServiceProvider);
  final transactions = await paymentService.getUserTransactions(userId);

  final expenseTransactions =
      transactions.where((transaction) => transaction.isExpense).toList();
  return expenseTransactions.fold(
      0, (sum, transaction) => sum + transaction.amount);
});

/// Payment methods provider
final paymentMethodsProvider = Provider<List<PaymentMethod>>((ref) {
  return PaymentMethod.values;
});

/// Payment types provider
final paymentTypesProvider = Provider<List<PaymentType>>((ref) {
  return PaymentType.values;
});

/// Transaction types provider
final transactionTypesProvider = Provider<List<TransactionType>>((ref) {
  return TransactionType.values;
});

/// Payment statuses provider
final paymentStatusesProvider = Provider<List<PaymentStatus>>((ref) {
  return PaymentStatus.values;
});

/// Today's transactions provider
final todaysTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((
  ref,
  userId,
) async {
  final paymentService = ref.read(paymentServiceProvider);
  final transactions = await paymentService.getUserTransactions(userId);

  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return transactions.where((transaction) {
    return transaction.createdAt.isAfter(startOfDay) &&
        transaction.createdAt.isBefore(endOfDay);
  }).toList();
});

/// This week's transactions provider
final thisWeekTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((
  ref,
  userId,
) async {
  final paymentService = ref.read(paymentServiceProvider);
  final transactions = await paymentService.getUserTransactions(userId);

  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeekDay =
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

  return transactions.where((transaction) {
    return transaction.createdAt.isAfter(startOfWeekDay);
  }).toList();
});

/// This month's transactions provider
final thisMonthTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((
  ref,
  userId,
) async {
  final paymentService = ref.read(paymentServiceProvider);
  final transactions = await paymentService.getUserTransactions(userId);

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month);

  return transactions.where((transaction) {
    return transaction.createdAt.isAfter(startOfMonth);
  }).toList();
});
