import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Модель для аналитики доходов и расходов
class Analytics {
  const Analytics({
    required this.id,
    required this.userId,
    required this.type,
    required this.date,
    required this.amount,
    required this.category,
    this.description,
    this.metadata = const {},
  });

  factory Analytics.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Analytics(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: AnalyticsType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => AnalyticsType.income,
      ),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amount: (data['amount'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      description: data['description'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
  final String id;
  final String userId;
  final AnalyticsType type;
  final DateTime date;
  final double amount;
  final String category;
  final String? description;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'date': Timestamp.fromDate(date),
        'amount': amount,
        'category': category,
        'description': description,
        'metadata': metadata,
      };

  Analytics copyWith({
    String? id,
    String? userId,
    AnalyticsType? type,
    DateTime? date,
    double? amount,
    String? category,
    String? description,
    Map<String, dynamic>? metadata,
  }) =>
      Analytics(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        date: date ?? this.date,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        description: description ?? this.description,
        metadata: metadata ?? this.metadata,
      );
}

/// Тип аналитики
enum AnalyticsType {
  income, // Доход
  expense, // Расход
}

/// Статистика доходов и расходов
class IncomeExpenseStats {
  const IncomeExpenseStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.netIncome,
    required this.transactionCount,
    required this.periodStart,
    required this.periodEnd,
    required this.incomeByCategory,
    required this.expenseByCategory,
    required this.monthlyData,
  });

  factory IncomeExpenseStats.empty() => IncomeExpenseStats(
        totalIncome: 0,
        totalExpense: 0,
        netIncome: 0,
        transactionCount: 0,
        periodStart: DateTime.now(),
        periodEnd: DateTime.now(),
        incomeByCategory: {},
        expenseByCategory: {},
        monthlyData: [],
      );
  final double totalIncome;
  final double totalExpense;
  final double netIncome;
  final int transactionCount;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, double> incomeByCategory;
  final Map<String, double> expenseByCategory;
  final List<MonthlyData> monthlyData;

  /// Получить процент роста доходов
  double get incomeGrowthPercentage {
    if (monthlyData.length < 2) return 0;

    final currentMonth = monthlyData.last;
    final previousMonth = monthlyData[monthlyData.length - 2];

    if (previousMonth.income == 0) return 0;

    return ((currentMonth.income - previousMonth.income) /
            previousMonth.income) *
        100;
  }

  /// Получить процент роста расходов
  double get expenseGrowthPercentage {
    if (monthlyData.length < 2) return 0;

    final currentMonth = monthlyData.last;
    final previousMonth = monthlyData[monthlyData.length - 2];

    if (previousMonth.expense == 0) return 0;

    return ((currentMonth.expense - previousMonth.expense) /
            previousMonth.expense) *
        100;
  }
}

/// Данные за месяц
class MonthlyData {
  const MonthlyData({
    required this.month,
    required this.income,
    required this.expense,
    required this.netIncome,
    required this.transactionCount,
  });

  factory MonthlyData.fromMap(Map<String, dynamic> map) => MonthlyData(
        month: (map['month'] as Timestamp?)?.toDate() ?? DateTime.now(),
        income: (map['income'] ?? 0.0).toDouble(),
        expense: (map['expense'] ?? 0.0).toDouble(),
        netIncome: (map['netIncome'] ?? 0.0).toDouble(),
        transactionCount: map['transactionCount'] ?? 0,
      );
  final DateTime month;
  final double income;
  final double expense;
  final double netIncome;
  final int transactionCount;

  Map<String, dynamic> toMap() => {
        'month': Timestamp.fromDate(month),
        'income': income,
        'expense': expense,
        'netIncome': netIncome,
        'transactionCount': transactionCount,
      };
}

/// Данные для графика
class ChartData {
  const ChartData({
    required this.label,
    required this.value,
    this.color,
    this.description,
  });
  final String label;
  final double value;
  final Color? color;
  final String? description;
}

/// Период для аналитики
enum AnalyticsPeriod {
  week, // Неделя
  month, // Месяц
  quarter, // Квартал
  year, // Год
  custom, // Пользовательский
}

/// Фильтр для аналитики
class AnalyticsFilter {
  const AnalyticsFilter({
    this.period = AnalyticsPeriod.month,
    this.startDate,
    this.endDate,
    this.type,
    this.category,
    this.categories,
  });
  final AnalyticsPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final AnalyticsType? type;
  final String? category;
  final List<String>? categories;

  AnalyticsFilter copyWith({
    AnalyticsPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    AnalyticsType? type,
    String? category,
    List<String>? categories,
  }) =>
      AnalyticsFilter(
        period: period ?? this.period,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        type: type ?? this.type,
        category: category ?? this.category,
        categories: categories ?? this.categories,
      );

  /// Получить даты для периода
  (DateTime, DateTime) getDateRange() {
    final now = DateTime.now();

    switch (period) {
      case AnalyticsPeriod.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return (weekStart, now);

      case AnalyticsPeriod.month:
        final monthStart = DateTime(now.year, now.month);
        return (monthStart, now);

      case AnalyticsPeriod.quarter:
        final quarter = ((now.month - 1) / 3).floor();
        final quarterStart = DateTime(now.year, quarter * 3 + 1);
        return (quarterStart, now);

      case AnalyticsPeriod.year:
        final yearStart = DateTime(now.year);
        return (yearStart, now);

      case AnalyticsPeriod.custom:
        return (startDate ?? now, endDate ?? now);
    }
  }
}

/// Категории доходов
class IncomeCategories {
  static const List<String> categories = [
    'Услуги',
    'Консультации',
    'Обучение',
    'Продажи',
    'Партнерство',
    'Другое',
  ];

  static const Map<String, String> categoryIcons = {
    'Услуги': '🛠️',
    'Консультации': '💬',
    'Обучение': '📚',
    'Продажи': '💰',
    'Партнерство': '🤝',
    'Другое': '📊',
  };

  static final Map<String, Color> categoryColors = {
    'Услуги': const Color(0xFF4CAF50),
    'Консультации': const Color(0xFF2196F3),
    'Обучение': const Color(0xFF9C27B0),
    'Продажи': const Color(0xFFFF9800),
    'Партнерство': const Color(0xFFE91E63),
    'Другое': const Color(0xFF607D8B),
  };
}

/// Категории расходов
class ExpenseCategories {
  static const List<String> categories = [
    'Реклама',
    'Инструменты',
    'Обучение',
    'Транспорт',
    'Канцелярия',
    'Другое',
  ];

  static const Map<String, String> categoryIcons = {
    'Реклама': '📢',
    'Инструменты': '🔧',
    'Обучение': '📖',
    'Транспорт': '🚗',
    'Канцелярия': '📝',
    'Другое': '📊',
  };

  static final Map<String, Color> categoryColors = {
    'Реклама': const Color(0xFFF44336),
    'Инструменты': const Color(0xFF795548),
    'Обучение': const Color(0xFF3F51B5),
    'Транспорт': const Color(0xFF009688),
    'Канцелярия': const Color(0xFFFF5722),
    'Другое': const Color(0xFF607D8B),
  };
}

/// Цели и бюджеты
class BudgetGoal {
  const BudgetGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.type,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory BudgetGoal.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BudgetGoal(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      targetAmount: (data['targetAmount'] ?? 0.0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0.0).toDouble(),
      targetDate:
          (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: BudgetType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => BudgetType.income,
      ),
      description: data['description'],
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final BudgetType type;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': Timestamp.fromDate(targetDate),
        'type': type.name,
        'description': description,
        'isCompleted': isCompleted,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Получить процент выполнения цели
  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount) * 100;
  }

  /// Проверить, достигнута ли цель
  bool get isAchieved => currentAmount >= targetAmount;

  /// Получить оставшуюся сумму
  double get remainingAmount => targetAmount - currentAmount;
}

/// Тип бюджета
enum BudgetType {
  income, // Цель по доходам
  expense, // Лимит расходов
  savings, // Накопления
}

/// Отчет по аналитике
class AnalyticsReport {
  const AnalyticsReport({
    required this.id,
    required this.userId,
    required this.title,
    required this.period,
    required this.generatedAt,
    required this.stats,
    required this.chartData,
    this.notes,
  });

  factory AnalyticsReport.fromMap(Map<String, dynamic> map) => AnalyticsReport(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        title: map['title'] ?? '',
        period: AnalyticsPeriod.values.firstWhere(
          (p) => p.name == map['period'],
          orElse: () => AnalyticsPeriod.month,
        ),
        generatedAt:
            (map['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        stats: IncomeExpenseStatsSerializer.fromMap(map['stats'] ?? {}),
        chartData: (map['chartData'] as List<dynamic>?)
                ?.map(ChartDataSerializer.fromMap)
                .toList() ??
            [],
        notes: map['notes'],
      );
  final String id;
  final String userId;
  final String title;
  final AnalyticsPeriod period;
  final DateTime generatedAt;
  final IncomeExpenseStats stats;
  final List<ChartData> chartData;
  final String? notes;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'period': period.name,
        'generatedAt': Timestamp.fromDate(generatedAt),
        'stats': stats.toMap(),
        'chartData': chartData.map((e) => e.toMap()).toList(),
        'notes': notes,
      };
}

// Расширения для сериализации
extension IncomeExpenseStatsExtension on IncomeExpenseStats {
  Map<String, dynamic> toMap() => {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netIncome': netIncome,
        'transactionCount': transactionCount,
        'periodStart': Timestamp.fromDate(periodStart),
        'periodEnd': Timestamp.fromDate(periodEnd),
        'incomeByCategory': incomeByCategory,
        'expenseByCategory': expenseByCategory,
        'monthlyData': monthlyData.map((e) => e.toMap()).toList(),
      };
}

// Статические методы для десериализации
class IncomeExpenseStatsSerializer {
  static IncomeExpenseStats fromMap(Map<String, dynamic> map) =>
      IncomeExpenseStats(
        totalIncome: (map['totalIncome'] ?? 0.0).toDouble(),
        totalExpense: (map['totalExpense'] ?? 0.0).toDouble(),
        netIncome: (map['netIncome'] ?? 0.0).toDouble(),
        transactionCount: map['transactionCount'] ?? 0,
        periodStart:
            (map['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
        periodEnd: (map['periodEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
        incomeByCategory:
            Map<String, double>.from(map['incomeByCategory'] ?? {}),
        expenseByCategory:
            Map<String, double>.from(map['expenseByCategory'] ?? {}),
        monthlyData: (map['monthlyData'] as List<dynamic>?)
                ?.map((e) => MonthlyData.fromMap(e))
                .toList() ??
            [],
      );
}

extension ChartDataExtension on ChartData {
  Map<String, dynamic> toMap() => {
        'label': label,
        'value': value,
        'color': color?.toARGB32(),
        'description': description,
      };
}

// Статические методы для десериализации
class ChartDataSerializer {
  static ChartData fromMap(Map<String, dynamic> map) => ChartData(
        label: map['label'] ?? '',
        value: (map['value'] ?? 0.0).toDouble(),
        color: map['color'] != null ? Color(map['color'] as int) : null,
        description: map['description'],
      );
}
