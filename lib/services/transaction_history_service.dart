import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/payment.dart';
import '../models/booking.dart';

/// Сервис для работы с историей транзакций
class TransactionHistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Получить историю транзакций для пользователя
  Future<List<TransactionHistoryItem>> getTransactionHistory({
    required String userId,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    String? lastDocumentId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('payments')
          .where('userId', isEqualTo: userId);

      // Фильтр по типу транзакции
      if (type != null) {
        query = query.where('type', isEqualTo: type.paymentType.name);
      }

      // Фильтр по дате
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Пагинация
      if (lastDocumentId != null) {
        final lastDoc = await _db.collection('payments').doc(lastDocumentId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      final querySnapshot = await query.get();
      final transactions = <TransactionHistoryItem>[];

      for (final doc in querySnapshot.docs) {
        final payment = Payment.fromDocument(doc);
        final booking = await _getBooking(payment.bookingId);
        
        final transactionItem = TransactionHistoryItem(
          id: payment.id,
          type: _getTransactionType(payment.type),
          amount: payment.amount,
          currency: payment.currency,
          status: payment.status,
          description: payment.description ?? _getDefaultDescription(payment.type),
          createdAt: payment.createdAt,
          completedAt: payment.completedAt,
          booking: booking,
          payment: payment,
          metadata: payment.metadata ?? {},
        );

        transactions.add(transactionItem);
      }

      return transactions;
    } catch (e) {
      debugPrint('Ошибка получения истории транзакций: $e');
      return [];
    }
  }

  /// Получить статистику транзакций
  Future<TransactionStatistics> getTransactionStatistics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('payments')
          .where('userId', isEqualTo: userId);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();
      final payments = querySnapshot.docs.map((doc) => Payment.fromDocument(doc)).toList();

      double totalIncome = 0;
      double totalExpenses = 0;
      double totalRefunds = 0;
      int completedTransactions = 0;
      int failedTransactions = 0;
      int pendingTransactions = 0;

      for (final payment in payments) {
        switch (payment.status) {
          case PaymentStatus.completed:
            completedTransactions++;
            if (payment.type == PaymentType.refund) {
              totalRefunds += payment.amount;
            } else {
              totalIncome += payment.amount;
            }
            break;
          case PaymentStatus.failed:
            failedTransactions++;
            break;
          case PaymentStatus.pending:
          case PaymentStatus.processing:
            pendingTransactions++;
            break;
          default:
            break;
        }
      }

      return TransactionStatistics(
        userId: userId,
        period: TransactionPeriod(startDate: startDate, endDate: endDate),
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        totalRefunds: totalRefunds,
        netIncome: totalIncome - totalRefunds,
        completedTransactions: completedTransactions,
        failedTransactions: failedTransactions,
        pendingTransactions: pendingTransactions,
        totalTransactions: payments.length,
        averageTransactionAmount: payments.isNotEmpty 
            ? payments.fold<double>(0, (sum, p) => sum + p.amount) / payments.length 
            : 0,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Ошибка получения статистики транзакций: $e');
      return TransactionStatistics.empty(userId);
    }
  }

  /// Получить транзакции по месяцам для графика
  Future<List<MonthlyTransactionData>> getMonthlyTransactionData({
    required String userId,
    required int monthsBack,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year, endDate.month - monthsBack, 1);
      
      final query = await _db
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final payments = query.docs.map((doc) => Payment.fromDocument(doc)).toList();
      
      // Группируем по месяцам
      final monthlyData = <String, MonthlyTransactionData>{};
      
      for (int i = 0; i < monthsBack; i++) {
        final month = DateTime(endDate.year, endDate.month - i, 1);
        final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        
        monthlyData[monthKey] = MonthlyTransactionData(
          month: month,
          income: 0,
          expenses: 0,
          refunds: 0,
          transactionCount: 0,
        );
      }

      for (final payment in payments) {
        final month = DateTime(payment.createdAt.year, payment.createdAt.month, 1);
        final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        
        if (monthlyData.containsKey(monthKey)) {
          final data = monthlyData[monthKey]!;
          
          if (payment.status == PaymentStatus.completed) {
            if (payment.type == PaymentType.refund) {
              data.refunds += payment.amount;
            } else {
              data.income += payment.amount;
            }
            data.transactionCount++;
          }
        }
      }

      return monthlyData.values.toList()
        ..sort((a, b) => a.month.compareTo(b.month));
    } catch (e) {
      debugPrint('Ошибка получения месячных данных транзакций: $e');
      return [];
    }
  }

  /// Получить детали транзакции
  Future<TransactionDetails?> getTransactionDetails(String transactionId) async {
    try {
      final payment = await _getPayment(transactionId);
      if (payment == null) return null;

      final booking = await _getBooking(payment.bookingId);
      final relatedTransactions = await _getRelatedTransactions(payment.bookingId);
      
      return TransactionDetails(
        payment: payment,
        booking: booking,
        relatedTransactions: relatedTransactions,
        timeline: await _getTransactionTimeline(transactionId),
      );
    } catch (e) {
      debugPrint('Ошибка получения деталей транзакции: $e');
      return null;
    }
  }

  /// Экспортировать историю транзакций
  Future<TransactionExport> exportTransactionHistory({
    required String userId,
    required TransactionExportFormat format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await getTransactionHistory(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        limit: 1000, // Максимум для экспорта
      );

      String content;
      String filename;
      String mimeType;

      switch (format) {
        case TransactionExportFormat.csv:
          content = _generateCSV(transactions);
          filename = 'transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
          mimeType = 'text/csv';
          break;
        case TransactionExportFormat.json:
          content = _generateJSON(transactions);
          filename = 'transactions_${DateTime.now().millisecondsSinceEpoch}.json';
          mimeType = 'application/json';
          break;
        case TransactionExportFormat.pdf:
          content = _generatePDF(transactions);
          filename = 'transactions_${DateTime.now().millisecondsSinceEpoch}.pdf';
          mimeType = 'application/pdf';
          break;
      }

      return TransactionExport(
        content: content,
        filename: filename,
        mimeType: mimeType,
        format: format,
        transactionCount: transactions.length,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Ошибка экспорта истории транзакций: $e');
      throw Exception('Не удалось экспортировать историю транзакций: $e');
    }
  }

  /// Получить платеж
  Future<Payment?> _getPayment(String paymentId) async {
    try {
      final doc = await _db.collection('payments').doc(paymentId).get();
      if (doc.exists) {
        return Payment.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения платежа: $e');
      return null;
    }
  }

  /// Получить бронирование
  Future<Booking?> _getBooking(String bookingId) async {
    try {
      final doc = await _db.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения бронирования: $e');
      return null;
    }
  }

  /// Получить связанные транзакции
  Future<List<Payment>> _getRelatedTransactions(String bookingId) async {
    try {
      final query = await _db
          .collection('payments')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt')
          .get();

      return query.docs.map((doc) => Payment.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('Ошибка получения связанных транзакций: $e');
      return [];
    }
  }

  /// Получить временную линию транзакции
  Future<List<TransactionTimelineEvent>> _getTransactionTimeline(String transactionId) async {
    try {
      // В реальном приложении здесь была бы история изменений статуса
      // Для демонстрации создаем примерную временную линию
      final payment = await _getPayment(transactionId);
      if (payment == null) return [];

      final timeline = <TransactionTimelineEvent>[
        TransactionTimelineEvent(
          timestamp: payment.createdAt,
          status: 'Создана',
          description: 'Транзакция создана',
          type: TransactionTimelineEventType.created,
        ),
      ];

      if (payment.status == PaymentStatus.processing) {
        timeline.add(TransactionTimelineEvent(
          timestamp: payment.createdAt.add(const Duration(minutes: 1)),
          status: 'Обрабатывается',
          description: 'Платеж обрабатывается',
          type: TransactionTimelineEventType.processing,
        ));
      }

      if (payment.completedAt != null) {
        timeline.add(TransactionTimelineEvent(
          timestamp: payment.completedAt!,
          status: 'Завершена',
          description: 'Платеж успешно обработан',
          type: TransactionTimelineEventType.completed,
        ));
      }

      if (payment.failedAt != null) {
        timeline.add(TransactionTimelineEvent(
          timestamp: payment.failedAt!,
          status: 'Неудачная',
          description: 'Платеж не удался',
          type: TransactionTimelineEventType.failed,
        ));
      }

      return timeline;
    } catch (e) {
      debugPrint('Ошибка получения временной линии транзакции: $e');
      return [];
    }
  }

  /// Получить тип транзакции
  TransactionType _getTransactionType(PaymentType paymentType) {
    switch (paymentType) {
      case PaymentType.advance:
        return TransactionType.advancePayment;
      case PaymentType.finalPayment:
        return TransactionType.finalPayment;
      case PaymentType.fullPayment:
        return TransactionType.fullPayment;
      case PaymentType.refund:
        return TransactionType.refund;
    }
  }

  /// Получить описание по умолчанию
  String _getDefaultDescription(PaymentType paymentType) {
    switch (paymentType) {
      case PaymentType.advance:
        return 'Авансовый платеж';
      case PaymentType.finalPayment:
        return 'Финальный платеж';
      case PaymentType.fullPayment:
        return 'Полная оплата';
      case PaymentType.refund:
        return 'Возврат средств';
    }
  }

  /// Генерировать CSV
  String _generateCSV(List<TransactionHistoryItem> transactions) {
    final buffer = StringBuffer();
    buffer.writeln('Дата,Тип,Сумма,Валюта,Статус,Описание');
    
    for (final transaction in transactions) {
      buffer.writeln([
        transaction.createdAt.toIso8601String(),
        transaction.type.displayName,
        transaction.amount.toString(),
        transaction.currency,
        transaction.status.statusDisplayName,
        transaction.description,
      ].join(','));
    }
    
    return buffer.toString();
  }

  /// Генерировать JSON
  String _generateJSON(List<TransactionHistoryItem> transactions) {
    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'transactionCount': transactions.length,
      'transactions': transactions.map((t) => {
        'id': t.id,
        'type': t.type.name,
        'amount': t.amount,
        'currency': t.currency,
        'status': t.status.name,
        'description': t.description,
        'createdAt': t.createdAt.toIso8601String(),
        'completedAt': t.completedAt?.toIso8601String(),
      }).toList(),
    };
    
    return data.toString();
  }

  /// Генерировать PDF (заглушка)
  String _generatePDF(List<TransactionHistoryItem> transactions) {
    // В реальном приложении здесь была бы генерация PDF
    return 'PDF content placeholder';
  }
}

/// Типы транзакций
enum TransactionType {
  advancePayment,  // Авансовый платеж
  finalPayment,    // Финальный платеж
  fullPayment,     // Полная оплата
  refund,          // Возврат
}

/// Расширение для получения названий типов транзакций
extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.advancePayment:
        return 'Аванс';
      case TransactionType.finalPayment:
        return 'Финальный платеж';
      case TransactionType.fullPayment:
        return 'Полная оплата';
      case TransactionType.refund:
        return 'Возврат';
    }
  }

  PaymentType get paymentType {
    switch (this) {
      case TransactionType.advancePayment:
        return PaymentType.advance;
      case TransactionType.finalPayment:
        return PaymentType.finalPayment;
      case TransactionType.fullPayment:
        return PaymentType.fullPayment;
      case TransactionType.refund:
        return PaymentType.refund;
    }
  }
}

/// Элемент истории транзакций
class TransactionHistoryItem {
  const TransactionHistoryItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    required this.description,
    required this.createdAt,
    this.completedAt,
    this.booking,
    required this.payment,
    required this.metadata,
  });

  final String id;
  final TransactionType type;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Booking? booking;
  final Payment payment;
  final Map<String, dynamic> metadata;

  /// Получить цвет для отображения
  String get statusColor {
    switch (status) {
      case PaymentStatus.completed:
        return 'green';
      case PaymentStatus.pending:
        return 'orange';
      case PaymentStatus.processing:
        return 'blue';
      case PaymentStatus.failed:
        return 'red';
      case PaymentStatus.cancelled:
        return 'grey';
      case PaymentStatus.refunded:
        return 'purple';
    }
  }

  /// Проверить, является ли транзакция доходом
  bool get isIncome => type != TransactionType.refund && status == PaymentStatus.completed;

  /// Проверить, является ли транзакция расходом
  bool get isExpense => type == TransactionType.refund && status == PaymentStatus.completed;
}

/// Статистика транзакций
class TransactionStatistics {
  const TransactionStatistics({
    required this.userId,
    required this.period,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalRefunds,
    required this.netIncome,
    required this.completedTransactions,
    required this.failedTransactions,
    required this.pendingTransactions,
    required this.totalTransactions,
    required this.averageTransactionAmount,
    required this.generatedAt,
  });

  final String userId;
  final TransactionPeriod period;
  final double totalIncome;
  final double totalExpenses;
  final double totalRefunds;
  final double netIncome;
  final int completedTransactions;
  final int failedTransactions;
  final int pendingTransactions;
  final int totalTransactions;
  final double averageTransactionAmount;
  final DateTime generatedAt;

  factory TransactionStatistics.empty(String userId) => TransactionStatistics(
    userId: userId,
    period: const TransactionPeriod(),
    totalIncome: 0,
    totalExpenses: 0,
    totalRefunds: 0,
    netIncome: 0,
    completedTransactions: 0,
    failedTransactions: 0,
    pendingTransactions: 0,
    totalTransactions: 0,
    averageTransactionAmount: 0,
    generatedAt: DateTime.now(),
  );

  /// Процент успешных транзакций
  double get successRate => totalTransactions > 0 
      ? (completedTransactions / totalTransactions) * 100 
      : 0;
}

/// Период для статистики
class TransactionPeriod {
  const TransactionPeriod({
    this.startDate,
    this.endDate,
  });

  final DateTime? startDate;
  final DateTime? endDate;
}

/// Месячные данные транзакций
class MonthlyTransactionData {
  const MonthlyTransactionData({
    required this.month,
    required this.income,
    required this.expenses,
    required this.refunds,
    required this.transactionCount,
  });

  final DateTime month;
  final double income;
  final double expenses;
  final double refunds;
  final int transactionCount;

  /// Чистый доход за месяц
  double get netIncome => income - refunds;
}

/// Детали транзакции
class TransactionDetails {
  const TransactionDetails({
    required this.payment,
    this.booking,
    required this.relatedTransactions,
    required this.timeline,
  });

  final Payment payment;
  final Booking? booking;
  final List<Payment> relatedTransactions;
  final List<TransactionTimelineEvent> timeline;
}

/// Событие временной линии транзакции
class TransactionTimelineEvent {
  const TransactionTimelineEvent({
    required this.timestamp,
    required this.status,
    required this.description,
    required this.type,
  });

  final DateTime timestamp;
  final String status;
  final String description;
  final TransactionTimelineEventType type;
}

/// Типы событий временной линии
enum TransactionTimelineEventType {
  created,     // Создана
  processing,  // Обрабатывается
  completed,   // Завершена
  failed,      // Неудачная
  cancelled,   // Отменена
}

/// Экспорт транзакций
class TransactionExport {
  const TransactionExport({
    required this.content,
    required this.filename,
    required this.mimeType,
    required this.format,
    required this.transactionCount,
    required this.generatedAt,
  });

  final String content;
  final String filename;
  final String mimeType;
  final TransactionExportFormat format;
  final int transactionCount;
  final DateTime generatedAt;
}

/// Форматы экспорта
enum TransactionExportFormat {
  csv,   // CSV файл
  json,  // JSON файл
  pdf,   // PDF файл
}
