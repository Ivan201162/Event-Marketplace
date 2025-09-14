import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics.dart';

/// Сервис для аналитики и отчетов
class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Создать метрику
  Future<Metric> createMetric({
    required String name,
    required MetricType type,
    required double value,
    required String unit,
    String? userId,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final metric = Metric(
        id: _generateMetricId(),
        name: name,
        type: type,
        value: value,
        unit: unit,
        timestamp: DateTime.now(),
        userId: userId,
        category: category,
        metadata: metadata,
      );

      await _db.collection('metrics').doc(metric.id).set(metric.toMap());
      return metric;
    } catch (e) {
      print('Ошибка создания метрики: $e');
      throw Exception('Не удалось создать метрику: $e');
    }
  }

  /// Получить метрики за период
  Future<List<Metric>> getMetricsForPeriod({
    required DateTime startDate,
    required DateTime endDate,
    MetricType? type,
    String? userId,
    String? category,
  }) async {
    try {
      Query query = _db
          .collection('metrics')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => Metric.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Ошибка получения метрик: $e');
      return [];
    }
  }

  /// Получить статистику за период
  Future<PeriodStatistics> getPeriodStatistics({
    required AnalyticsPeriod period,
    required DateTime date,
    String? userId,
  }) async {
    try {
      final (startDate, endDate) = _getPeriodDates(period, date);
      final metrics = await getMetricsForPeriod(
        startDate: startDate,
        endDate: endDate,
        userId: userId,
      );

      final metricsMap = <String, double>{};
      for (final metric in metrics) {
        metricsMap[metric.name] = (metricsMap[metric.name] ?? 0) + metric.value;
      }

      return PeriodStatistics(
        period: period,
        startDate: startDate,
        endDate: endDate,
        metrics: metricsMap,
        detailedMetrics: metrics,
      );
    } catch (e) {
      print('Ошибка получения статистики за период: $e');
      return PeriodStatistics(
        period: period,
        startDate: date,
        endDate: date,
        metrics: {},
        detailedMetrics: [],
      );
    }
  }

  /// Получить KPI
  Future<List<KPI>> getKPIs({String? userId}) async {
    try {
      final now = DateTime.now();
      final currentPeriod = await getPeriodStatistics(
        period: AnalyticsPeriod.month,
        date: now,
        userId: userId,
      );
      
      final previousPeriod = await getPeriodStatistics(
        period: AnalyticsPeriod.month,
        date: DateTime(now.year, now.month - 1, now.day),
        userId: userId,
      );

      return [
        KPI(
          name: 'Общее количество заявок',
          value: currentPeriod.getMetric('total_bookings'),
          unit: 'шт',
          target: 100,
          previousValue: previousPeriod.getMetric('total_bookings'),
          description: 'Общее количество созданных заявок за месяц',
        ),
        KPI(
          name: 'Подтвержденные заявки',
          value: currentPeriod.getMetric('confirmed_bookings'),
          unit: 'шт',
          target: 80,
          previousValue: previousPeriod.getMetric('confirmed_bookings'),
          description: 'Количество подтвержденных заявок',
        ),
        KPI(
          name: 'Общий доход',
          value: currentPeriod.getMetric('total_revenue'),
          unit: '₽',
          target: 500000,
          previousValue: previousPeriod.getMetric('total_revenue'),
          description: 'Общий доход от всех заявок',
        ),
        KPI(
          name: 'Средний рейтинг',
          value: currentPeriod.getMetric('average_rating'),
          unit: 'звезд',
          target: 4.5,
          previousValue: previousPeriod.getMetric('average_rating'),
          description: 'Средний рейтинг специалиста',
        ),
        KPI(
          name: 'Конверсия',
          value: currentPeriod.getMetric('conversion_rate'),
          unit: '%',
          target: 80,
          previousValue: previousPeriod.getMetric('conversion_rate'),
          description: 'Процент подтвержденных заявок',
        ),
      ];
    } catch (e) {
      print('Ошибка получения KPI: $e');
      return [];
    }
  }

  /// Создать отчет
  Future<Report> createReport({
    required String title,
    required String description,
    required ReportType type,
    required AnalyticsPeriod period,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> data,
    String? userId,
  }) async {
    try {
      final report = Report(
        id: _generateReportId(),
        title: title,
        description: description,
        type: type,
        period: period,
        startDate: startDate,
        endDate: endDate,
        data: data,
        createdAt: DateTime.now(),
        userId: userId,
      );

      await _db.collection('reports').doc(report.id).set(report.toMap());
      return report;
    } catch (e) {
      print('Ошибка создания отчета: $e');
      throw Exception('Не удалось создать отчет: $e');
    }
  }

  /// Получить отчеты пользователя
  Future<List<Report>> getUserReports(String userId) async {
    try {
      final querySnapshot = await _db
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Report.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Ошибка получения отчетов: $e');
      return [];
    }
  }

  /// Создать дашборд
  Future<Dashboard> createDashboard({
    required String title,
    required String description,
    required List<DashboardWidget> widgets,
    String? userId,
  }) async {
    try {
      final dashboard = Dashboard(
        id: _generateDashboardId(),
        title: title,
        description: description,
        widgets: widgets,
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _db.collection('dashboards').doc(dashboard.id).set(dashboard.toMap());
      return dashboard;
    } catch (e) {
      print('Ошибка создания дашборда: $e');
      throw Exception('Не удалось создать дашборд: $e');
    }
  }

  /// Получить дашборды пользователя
  Future<List<Dashboard>> getUserDashboards(String userId) async {
    try {
      final querySnapshot = await _db
          .collection('dashboards')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Dashboard.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Ошибка получения дашбордов: $e');
      return [];
    }
  }

  /// Создать сводный отчет
  Future<Report> createSummaryReport({
    required AnalyticsPeriod period,
    required DateTime date,
    String? userId,
  }) async {
    try {
      final statistics = await getPeriodStatistics(
        period: period,
        date: date,
        userId: userId,
      );

      final data = {
        'period': period.name,
        'startDate': statistics.startDate.toIso8601String(),
        'endDate': statistics.endDate.toIso8601String(),
        'metrics': statistics.metrics,
        'summary': {
          'totalBookings': statistics.getMetric('total_bookings'),
          'confirmedBookings': statistics.getMetric('confirmed_bookings'),
          'totalRevenue': statistics.getMetric('total_revenue'),
          'averageRating': statistics.getMetric('average_rating'),
          'conversionRate': statistics.getMetric('conversion_rate'),
        },
      };

      return await createReport(
        title: 'Сводный отчет за ${_getPeriodName(period)}',
        description: 'Общая статистика за выбранный период',
        type: ReportType.summary,
        period: period,
        startDate: statistics.startDate,
        endDate: statistics.endDate,
        data: data,
        userId: userId,
      );
    } catch (e) {
      print('Ошибка создания сводного отчета: $e');
      throw Exception('Не удалось создать сводный отчет: $e');
    }
  }

  /// Создать финансовый отчет
  Future<Report> createFinancialReport({
    required AnalyticsPeriod period,
    required DateTime date,
    String? userId,
  }) async {
    try {
      final statistics = await getPeriodStatistics(
        period: period,
        date: date,
        userId: userId,
      );

      final data = {
        'period': period.name,
        'startDate': statistics.startDate.toIso8601String(),
        'endDate': statistics.endDate.toIso8601String(),
        'financial': {
          'totalRevenue': statistics.getMetric('total_revenue'),
          'advancePayments': statistics.getMetric('advance_payments'),
          'finalPayments': statistics.getMetric('final_payments'),
          'averagePayment': statistics.getMetric('average_payment'),
          'paymentSuccessRate': statistics.getMetric('payment_success_rate'),
        },
      };

      return await createReport(
        title: 'Финансовый отчет за ${_getPeriodName(period)}',
        description: 'Детальная финансовая статистика',
        type: ReportType.financial,
        period: period,
        startDate: statistics.startDate,
        endDate: statistics.endDate,
        data: data,
        userId: userId,
      );
    } catch (e) {
      print('Ошибка создания финансового отчета: $e');
      throw Exception('Не удалось создать финансовый отчет: $e');
    }
  }

  /// Создать отчет по производительности
  Future<Report> createPerformanceReport({
    required AnalyticsPeriod period,
    required DateTime date,
    String? userId,
  }) async {
    try {
      final statistics = await getPeriodStatistics(
        period: period,
        date: date,
        userId: userId,
      );

      final data = {
        'period': period.name,
        'startDate': statistics.startDate.toIso8601String(),
        'endDate': statistics.endDate.toIso8601String(),
        'performance': {
          'totalBookings': statistics.getMetric('total_bookings'),
          'confirmedBookings': statistics.getMetric('confirmed_bookings'),
          'rejectedBookings': statistics.getMetric('rejected_bookings'),
          'cancelledBookings': statistics.getMetric('cancelled_bookings'),
          'averageResponseTime': statistics.getMetric('average_response_time'),
          'customerSatisfaction': statistics.getMetric('customer_satisfaction'),
        },
      };

      return await createReport(
        title: 'Отчет по производительности за ${_getPeriodName(period)}',
        description: 'Анализ эффективности работы',
        type: ReportType.performance,
        period: period,
        startDate: statistics.startDate,
        endDate: statistics.endDate,
        data: data,
        userId: userId,
      );
    } catch (e) {
      print('Ошибка создания отчета по производительности: $e');
      throw Exception('Не удалось создать отчет по производительности: $e');
    }
  }

  /// Получить даты периода
  (DateTime, DateTime) _getPeriodDates(AnalyticsPeriod period, DateTime date) {
    switch (period) {
      case AnalyticsPeriod.day:
        final start = DateTime(date.year, date.month, date.day);
        final end = start.add(const Duration(days: 1));
        return (start, end);
      
      case AnalyticsPeriod.week:
        final start = date.subtract(Duration(days: date.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return (start, end);
      
      case AnalyticsPeriod.month:
        final start = DateTime(date.year, date.month, 1);
        final end = DateTime(date.year, date.month + 1, 1);
        return (start, end);
      
      case AnalyticsPeriod.quarter:
        final quarter = ((date.month - 1) / 3).floor();
        final start = DateTime(date.year, quarter * 3 + 1, 1);
        final end = DateTime(date.year, quarter * 3 + 4, 1);
        return (start, end);
      
      case AnalyticsPeriod.year:
        final start = DateTime(date.year, 1, 1);
        final end = DateTime(date.year + 1, 1, 1);
        return (start, end);
    }
  }

  /// Получить название периода
  String _getPeriodName(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.day:
        return 'день';
      case AnalyticsPeriod.week:
        return 'неделю';
      case AnalyticsPeriod.month:
        return 'месяц';
      case AnalyticsPeriod.quarter:
        return 'квартал';
      case AnalyticsPeriod.year:
        return 'год';
    }
  }

  /// Генерировать ID метрики
  String _generateMetricId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'METRIC_${timestamp}_$random';
  }

  /// Генерировать ID отчета
  String _generateReportId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'REPORT_${timestamp}_$random';
  }

  /// Генерировать ID дашборда
  String _generateDashboardId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'DASH_${timestamp}_$random';
  }
}
