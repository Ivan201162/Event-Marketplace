/// Статистика платежей
class PaymentStatistics {
  const PaymentStatistics({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalTransactions,
    required this.successfulTransactions,
    required this.failedTransactions,
    required this.averageTransactionAmount,
    required this.revenueByMonth,
    required this.transactionsByStatus,
    required this.lastTransactionDate,
  });

  factory PaymentStatistics.fromMap(Map<String, dynamic> data) => PaymentStatistics(
        totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
        totalExpenses: (data['totalExpenses'] as num?)?.toDouble() ?? 0.0,
        netProfit: (data['netProfit'] as num?)?.toDouble() ?? 0.0,
        totalTransactions: data['totalTransactions'] as int? ?? 0,
        successfulTransactions: data['successfulTransactions'] as int? ?? 0,
        failedTransactions: data['failedTransactions'] as int? ?? 0,
        averageTransactionAmount: (data['averageTransactionAmount'] as num?)?.toDouble() ?? 0.0,
        revenueByMonth: Map<String, double>.from(data['revenueByMonth'] ?? {}),
        transactionsByStatus: Map<String, int>.from(data['transactionsByStatus'] ?? {}),
        lastTransactionDate: DateTime.parse(data['lastTransactionDate'] as String),
      );
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final int totalTransactions;
  final int successfulTransactions;
  final int failedTransactions;
  final double averageTransactionAmount;
  final Map<String, double> revenueByMonth;
  final Map<String, int> transactionsByStatus;
  final DateTime lastTransactionDate;

  Map<String, dynamic> toMap() => {
        'totalRevenue': totalRevenue,
        'totalExpenses': totalExpenses,
        'netProfit': netProfit,
        'totalTransactions': totalTransactions,
        'successfulTransactions': successfulTransactions,
        'failedTransactions': failedTransactions,
        'averageTransactionAmount': averageTransactionAmount,
        'revenueByMonth': revenueByMonth,
        'transactionsByStatus': transactionsByStatus,
        'lastTransactionDate': lastTransactionDate.toIso8601String(),
      };
}
