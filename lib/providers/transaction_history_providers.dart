import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment.dart';
import '../services/transaction_history_service.dart';

/// Провайдер сервиса истории транзакций
final transactionHistoryServiceProvider = Provider<TransactionHistoryService>((ref) {
  return TransactionHistoryService();
});

/// Провайдер истории транзакций пользователя
final transactionHistoryProvider = FutureProvider.family<List<TransactionHistoryItem>, TransactionHistoryParams>((ref, params) async {
  final service = ref.read(transactionHistoryServiceProvider);
  
  return service.getTransactionHistory(
    userId: params.userId,
    type: params.type,
    startDate: params.startDate,
    endDate: params.endDate,
    limit: params.limit,
    lastDocumentId: params.lastDocumentId,
  );
});

/// Провайдер статистики транзакций
final transactionStatisticsProvider = FutureProvider.family<TransactionStatistics, TransactionStatisticsParams>((ref, params) async {
  final service = ref.read(transactionHistoryServiceProvider);
  
  return service.getTransactionStatistics(
    userId: params.userId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

/// Провайдер месячных данных транзакций
final monthlyTransactionDataProvider = FutureProvider.family<List<MonthlyTransactionData>, MonthlyTransactionParams>((ref, params) async {
  final service = ref.read(transactionHistoryServiceProvider);
  
  return service.getMonthlyTransactionData(
    userId: params.userId,
    monthsBack: params.monthsBack,
  );
});

/// Провайдер деталей транзакции
final transactionDetailsProvider = FutureProvider.family<TransactionDetails?, String>((ref, transactionId) async {
  final service = ref.read(transactionHistoryServiceProvider);
  
  return service.getTransactionDetails(transactionId);
});

/// Провайдер экспорта транзакций
final transactionExportProvider = FutureProvider.family<TransactionExport, TransactionExportParams>((ref, params) async {
  final service = ref.read(transactionHistoryServiceProvider);
  
  return service.exportTransactionHistory(
    userId: params.userId,
    format: params.format,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

/// Параметры для истории транзакций
class TransactionHistoryParams {
  const TransactionHistoryParams({
    required this.userId,
    this.type,
    this.startDate,
    this.endDate,
    this.limit = 50,
    this.lastDocumentId,
  });

  final String userId;
  final TransactionType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final String? lastDocumentId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionHistoryParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          type == other.type &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          limit == other.limit &&
          lastDocumentId == other.lastDocumentId;

  @override
  int get hashCode =>
      userId.hashCode ^
      type.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      limit.hashCode ^
      lastDocumentId.hashCode;
}

/// Параметры для статистики транзакций
class TransactionStatisticsParams {
  const TransactionStatisticsParams({
    required this.userId,
    this.startDate,
    this.endDate,
  });

  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionStatisticsParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      userId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;
}

/// Параметры для месячных данных транзакций
class MonthlyTransactionParams {
  const MonthlyTransactionParams({
    required this.userId,
    this.monthsBack = 12,
  });

  final String userId;
  final int monthsBack;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyTransactionParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          monthsBack == other.monthsBack;

  @override
  int get hashCode =>
      userId.hashCode ^
      monthsBack.hashCode;
}

/// Параметры для экспорта транзакций
class TransactionExportParams {
  const TransactionExportParams({
    required this.userId,
    required this.format,
    this.startDate,
    this.endDate,
  });

  final String userId;
  final TransactionExportFormat format;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionExportParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          format == other.format &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      userId.hashCode ^
      format.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;
}
