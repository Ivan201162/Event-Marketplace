import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics.dart';
import '../models/payment_extended.dart';
import '../models/booking.dart';

/// Сервис для аналитики доходов и расходов
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Добавить запись о доходе
  Future<String?> addIncome({
    required String userId,
    required double amount,
    required String category,
    String? description,
    DateTime? date,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final analyticsRef = _firestore.collection('analytics').doc();
      
      final analytics = Analytics(
        id: analyticsRef.id,
        userId: userId,
        type: AnalyticsType.income,
        date: date ?? DateTime.now(),
        amount: amount,
        category: category,
        description: description,
        metadata: metadata ?? {},
      );

      await analyticsRef.set(analytics.toMap());
      return analyticsRef.id;
    } catch (e) {
      print('Ошибка добавления дохода: $e');
      return null;
    }
  }

  /// Добавить запись о расходе
  Future<String?> addExpense({
    required String userId,
    required double amount,
    required String category,
    String? description,
    DateTime? date,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final analyticsRef = _firestore.collection('analytics').doc();
      
      final analytics = Analytics(
        id: analyticsRef.id,
        userId: userId,
        type: AnalyticsType.expense,
        date: date ?? DateTime.now(),
        amount: amount,
        category: category,
        description: description,
        metadata: metadata ?? {},
      );

      await analyticsRef.set(analytics.toMap());
      return analyticsRef.id;
    } catch (e) {
      print('Ошибка добавления расхода: $e');
      return null;
    }
  }

  /// Получить аналитику пользователя
  Stream<List<Analytics>> getUserAnalytics(String userId, AnalyticsFilter filter) {
    final (startDate, endDate) = filter.getDateRange();
    
    Query query = _firestore
        .collection('analytics')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

    if (filter.type != null) {
      query = query.where('type', isEqualTo: filter.type!.name);
    }

    if (filter.category != null) {
      query = query.where('category', isEqualTo: filter.category);
    }

    return query
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Analytics.fromDocument(doc))
          .toList();
    });
  }

  /// Получить статистику доходов и расходов
  Future<IncomeExpenseStats> getIncomeExpenseStats(String userId, AnalyticsFilter filter) async {
    try {
      final (startDate, endDate) = filter.getDateRange();
      
      final snapshot = await _firestore
          .collection('analytics')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final analytics = snapshot.docs
          .map((doc) => Analytics.fromDocument(doc))
          .toList();

      // Подсчитываем статистику
      double totalIncome = 0.0;
      double totalExpense = 0.0;
      int transactionCount = analytics.length;
      
      final incomeByCategory = <String, double>{};
      final expenseByCategory = <String, double>{};

      for (final item in analytics) {
        if (item.type == AnalyticsType.income) {
          totalIncome += item.amount;
          incomeByCategory[item.category] = (incomeByCategory[item.category] ?? 0.0) + item.amount;
        } else {
          totalExpense += item.amount;
          expenseByCategory[item.category] = (expenseByCategory[item.category] ?? 0.0) + item.amount;
        }
      }

      final netIncome = totalIncome - totalExpense;

      // Получаем месячные данные
      final monthlyData = await _getMonthlyData(userId, startDate, endDate);

      return IncomeExpenseStats(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netIncome: netIncome,
        transactionCount: transactionCount,
        periodStart: startDate,
        periodEnd: endDate,
        incomeByCategory: incomeByCategory,
        expenseByCategory: expenseByCategory,
        monthlyData: monthlyData,
      );
    } catch (e) {
      print('Ошибка получения статистики: $e');
      return IncomeExpenseStats.empty();
    }
  }

  /// Получить месячные данные
  Future<List<MonthlyData>> _getMonthlyData(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final monthlyData = <MonthlyData>[];
      final currentDate = DateTime(startDate.year, startDate.month, 1);
      final endMonth = DateTime(endDate.year, endDate.month, 1);

      while (currentDate.isBefore(endMonth) || currentDate.isAtSameMomentAs(endMonth)) {
        final monthStart = currentDate;
        final monthEnd = DateTime(currentDate.year, currentDate.month + 1, 1).subtract(const Duration(days: 1));

        final snapshot = await _firestore
            .collection('analytics')
            .where('userId', isEqualTo: userId)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
            .get();

        final monthAnalytics = snapshot.docs
            .map((doc) => Analytics.fromDocument(doc))
            .toList();

        double monthIncome = 0.0;
        double monthExpense = 0.0;
        int monthTransactionCount = monthAnalytics.length;

        for (final item in monthAnalytics) {
          if (item.type == AnalyticsType.income) {
            monthIncome += item.amount;
          } else {
            monthExpense += item.amount;
          }
        }

        monthlyData.add(MonthlyData(
          month: currentDate,
          income: monthIncome,
          expense: monthExpense,
          netIncome: monthIncome - monthExpense,
          transactionCount: monthTransactionCount,
        ));

        currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
      }

      return monthlyData;
    } catch (e) {
      print('Ошибка получения месячных данных: $e');
      return [];
    }
  }

  /// Синхронизировать данные из платежей
  Future<void> syncFromPayments(String userId) async {
    try {
      // Получаем все завершенные платежи пользователя
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('specialistId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      for (final doc in paymentsSnapshot.docs) {
        final payment = PaymentExtended.fromDocument(doc);
        
        // Проверяем, есть ли уже запись об этом доходе
        final existingSnapshot = await _firestore
            .collection('analytics')
            .where('userId', isEqualTo: userId)
            .where('metadata.paymentId', isEqualTo: payment.id)
            .get();

        if (existingSnapshot.docs.isEmpty) {
          // Добавляем доход
          await addIncome(
            userId: userId,
            amount: payment.paidAmount,
            category: 'Услуги',
            description: 'Доход от бронирования ${payment.bookingId}',
            date: payment.updatedAt,
            metadata: {
              'paymentId': payment.id,
              'bookingId': payment.bookingId,
              'source': 'payment',
            },
          );
        }
      }
    } catch (e) {
      print('Ошибка синхронизации с платежами: $e');
    }
  }

  /// Создать цель/бюджет
  Future<String?> createBudgetGoal({
    required String userId,
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    required BudgetType type,
    String? description,
  }) async {
    try {
      final goalRef = _firestore.collection('budget_goals').doc();
      
      final goal = BudgetGoal(
        id: goalRef.id,
        userId: userId,
        name: name,
        targetAmount: targetAmount,
        currentAmount: 0.0,
        targetDate: targetDate,
        type: type,
        description: description,
        createdAt: DateTime.now(),
      );

      await goalRef.set(goal.toMap());
      return goalRef.id;
    } catch (e) {
      print('Ошибка создания цели: $e');
      return null;
    }
  }

  /// Получить цели пользователя
  Stream<List<BudgetGoal>> getUserBudgetGoals(String userId) {
    return _firestore
        .collection('budget_goals')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BudgetGoal.fromDocument(doc))
          .toList();
    });
  }

  /// Обновить прогресс цели
  Future<bool> updateGoalProgress(String goalId, double newAmount) async {
    try {
      await _firestore.collection('budget_goals').doc(goalId).update({
        'currentAmount': newAmount,
        'isCompleted': newAmount >= (await _firestore.collection('budget_goals').doc(goalId).get()).data()?['targetAmount'],
      });
      return true;
    } catch (e) {
      print('Ошибка обновления прогресса цели: $e');
      return false;
    }
  }

  /// Удалить цель
  Future<bool> deleteBudgetGoal(String goalId) async {
    try {
      await _firestore.collection('budget_goals').doc(goalId).delete();
      return true;
    } catch (e) {
      print('Ошибка удаления цели: $e');
      return false;
    }
  }

  /// Создать отчет
  Future<String?> createReport({
    required String userId,
    required String title,
    required AnalyticsPeriod period,
    required IncomeExpenseStats stats,
    required List<ChartData> chartData,
    String? notes,
  }) async {
    try {
      final reportRef = _firestore.collection('analytics_reports').doc();
      
      final report = AnalyticsReport(
        id: reportRef.id,
        userId: userId,
        title: title,
        period: period,
        generatedAt: DateTime.now(),
        stats: stats,
        chartData: chartData,
        notes: notes,
      );

      await reportRef.set(report.toMap());
      return reportRef.id;
    } catch (e) {
      print('Ошибка создания отчета: $e');
      return null;
    }
  }

  /// Получить отчеты пользователя
  Stream<List<AnalyticsReport>> getUserReports(String userId) {
    return _firestore
        .collection('analytics_reports')
        .where('userId', isEqualTo: userId)
        .orderBy('generatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AnalyticsReport.fromMap(doc.data()))
          .toList();
    });
  }

  /// Получить данные для графика доходов по месяцам
  Future<List<ChartData>> getIncomeChartData(String userId, int months) async {
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year, endDate.month - months + 1, 1);
      
      final monthlyData = await _getMonthlyData(userId, startDate, endDate);
      
      return monthlyData.map((data) => ChartData(
        label: '${data.month.month}/${data.month.year}',
        value: data.income,
        description: 'Доход за ${data.month.month}/${data.month.year}',
      )).toList();
    } catch (e) {
      print('Ошибка получения данных графика доходов: $e');
      return [];
    }
  }

  /// Получить данные для графика расходов по месяцам
  Future<List<ChartData>> getExpenseChartData(String userId, int months) async {
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year, endDate.month - months + 1, 1);
      
      final monthlyData = await _getMonthlyData(userId, startDate, endDate);
      
      return monthlyData.map((data) => ChartData(
        label: '${data.month.month}/${data.month.year}',
        value: data.expense,
        description: 'Расход за ${data.month.month}/${data.month.year}',
      )).toList();
    } catch (e) {
      print('Ошибка получения данных графика расходов: $e');
      return [];
    }
  }

  /// Получить данные для круговой диаграммы по категориям доходов
  Future<List<ChartData>> getIncomeCategoryChartData(String userId, AnalyticsFilter filter) async {
    try {
      final stats = await getIncomeExpenseStats(userId, filter);
      
      return stats.incomeByCategory.entries.map((entry) {
        final category = entry.key;
        final amount = entry.value;
        
        return ChartData(
          label: category,
          value: amount,
          color: IncomeCategories.categoryColors[category],
          description: '$category: ${amount.toStringAsFixed(2)} ₽',
        );
      }).toList();
    } catch (e) {
      print('Ошибка получения данных по категориям доходов: $e');
      return [];
    }
  }

  /// Получить данные для круговой диаграммы по категориям расходов
  Future<List<ChartData>> getExpenseCategoryChartData(String userId, AnalyticsFilter filter) async {
    try {
      final stats = await getIncomeExpenseStats(userId, filter);
      
      return stats.expenseByCategory.entries.map((entry) {
        final category = entry.key;
        final amount = entry.value;
        
        return ChartData(
          label: category,
          value: amount,
          color: ExpenseCategories.categoryColors[category],
          description: '$category: ${amount.toStringAsFixed(2)} ₽',
        );
      }).toList();
    } catch (e) {
      print('Ошибка получения данных по категориям расходов: $e');
      return [];
    }
  }

  /// Экспортировать данные в CSV
  Future<String> exportToCSV(String userId, AnalyticsFilter filter) async {
    try {
      final analytics = await getUserAnalytics(userId, filter).first;
      
      final csv = StringBuffer();
      csv.writeln('Дата,Тип,Категория,Сумма,Описание');
      
      for (final item in analytics) {
        csv.writeln('${item.date.toIso8601String()},${item.type.name},${item.category},${item.amount},${item.description ?? ''}');
      }
      
      return csv.toString();
    } catch (e) {
      print('Ошибка экспорта в CSV: $e');
      return '';
    }
  }
}