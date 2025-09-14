import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';
import '../models/analytics.dart';

/// Провайдер сервиса аналитики
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Провайдер метрик за период
final metricsForPeriodProvider = FutureProvider.family<List<Metric>, MetricsForPeriodParams>((ref, params) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.getMetricsForPeriod(
    startDate: params.startDate,
    endDate: params.endDate,
    type: params.type,
    userId: params.userId,
    category: params.category,
  );
});

/// Провайдер статистики за период
final periodStatisticsProvider = FutureProvider.family<PeriodStatistics, PeriodStatisticsParams>((ref, params) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.getPeriodStatistics(
    period: params.period,
    date: params.date,
    userId: params.userId,
  );
});

/// Провайдер KPI
final kpiProvider = FutureProvider.family<List<KPI>, String?>((ref, userId) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.getKPIs(userId: userId);
});

/// Провайдер отчетов пользователя
final userReportsProvider = FutureProvider.family<List<Report>, String>((ref, userId) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.getUserReports(userId);
});

/// Провайдер дашбордов пользователя
final userDashboardsProvider = FutureProvider.family<List<Dashboard>, String>((ref, userId) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.getUserDashboards(userId);
});

/// Провайдер для управления состоянием аналитики
final analyticsStateProvider = StateNotifierProvider<AnalyticsStateNotifier, AnalyticsState>((ref) {
  return AnalyticsStateNotifier(ref.read(analyticsServiceProvider));
});

/// Состояние аналитики
class AnalyticsState {
  final bool isLoading;
  final String? errorMessage;
  final List<Report> recentReports;
  final Dashboard? currentDashboard;
  final List<KPI> currentKPIs;

  const AnalyticsState({
    this.isLoading = false,
    this.errorMessage,
    this.recentReports = const [],
    this.currentDashboard,
    this.currentKPIs = const [],
  });

  AnalyticsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Report>? recentReports,
    Dashboard? currentDashboard,
    List<KPI>? currentKPIs,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      recentReports: recentReports ?? this.recentReports,
      currentDashboard: currentDashboard ?? this.currentDashboard,
      currentKPIs: currentKPIs ?? this.currentKPIs,
    );
  }
}

/// Нотификатор состояния аналитики
class AnalyticsStateNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsService _analyticsService;

  AnalyticsStateNotifier(this._analyticsService) : super(const AnalyticsState());

  /// Создать метрику
  Future<void> createMetric({
    required String name,
    required MetricType type,
    required double value,
    required String unit,
    String? userId,
    String? category,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _analyticsService.createMetric(
        name: name,
        type: type,
        value: value,
        unit: unit,
        userId: userId,
        category: category,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Создать отчет
  Future<Report?> createReport({
    required String title,
    required String description,
    required ReportType type,
    required AnalyticsPeriod period,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> data,
    String? userId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final report = await _analyticsService.createReport(
        title: title,
        description: description,
        type: type,
        period: period,
        startDate: startDate,
        endDate: endDate,
        data: data,
        userId: userId,
      );
      
      state = state.copyWith(isLoading: false);
      return report;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Создать сводный отчет
  Future<Report?> createSummaryReport({
    required AnalyticsPeriod period,
    required DateTime date,
    String? userId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final report = await _analyticsService.createSummaryReport(
        period: period,
        date: date,
        userId: userId,
      );
      
      state = state.copyWith(isLoading: false);
      return report;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Создать финансовый отчет
  Future<Report?> createFinancialReport({
    required AnalyticsPeriod period,
    required DateTime date,
    String? userId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final report = await _analyticsService.createFinancialReport(
        period: period,
        date: date,
        userId: userId,
      );
      
      state = state.copyWith(isLoading: false);
      return report;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Создать отчет по производительности
  Future<Report?> createPerformanceReport({
    required AnalyticsPeriod period,
    required DateTime date,
    String? userId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final report = await _analyticsService.createPerformanceReport(
        period: period,
        date: date,
        userId: userId,
      );
      
      state = state.copyWith(isLoading: false);
      return report;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Создать дашборд
  Future<Dashboard?> createDashboard({
    required String title,
    required String description,
    required List<DashboardWidget> widgets,
    String? userId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final dashboard = await _analyticsService.createDashboard(
        title: title,
        description: description,
        widgets: widgets,
        userId: userId,
      );
      
      state = state.copyWith(
        isLoading: false,
        currentDashboard: dashboard,
      );
      return dashboard;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Параметры для метрик за период
class MetricsForPeriodParams {
  final DateTime startDate;
  final DateTime endDate;
  final MetricType? type;
  final String? userId;
  final String? category;

  const MetricsForPeriodParams({
    required this.startDate,
    required this.endDate,
    this.type,
    this.userId,
    this.category,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetricsForPeriodParams &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.type == type &&
        other.userId == userId &&
        other.category == category;
  }

  @override
  int get hashCode => startDate.hashCode ^ 
      endDate.hashCode ^ 
      type.hashCode ^ 
      userId.hashCode ^ 
      category.hashCode;
}

/// Параметры для статистики за период
class PeriodStatisticsParams {
  final AnalyticsPeriod period;
  final DateTime date;
  final String? userId;

  const PeriodStatisticsParams({
    required this.period,
    required this.date,
    this.userId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PeriodStatisticsParams &&
        other.period == period &&
        other.date == date &&
        other.userId == userId;
  }

  @override
  int get hashCode => period.hashCode ^ date.hashCode ^ userId.hashCode;
}

/// Провайдер для управления формой отчета
final reportFormProvider = StateNotifierProvider<ReportFormNotifier, ReportFormState>((ref) {
  return ReportFormNotifier();
});

/// Состояние формы отчета
class ReportFormState {
  final String title;
  final String description;
  final ReportType selectedType;
  final AnalyticsPeriod selectedPeriod;
  final DateTime selectedDate;
  final bool isGenerating;
  final String? errorMessage;

  const ReportFormState({
    this.title = '',
    this.description = '',
    this.selectedType = ReportType.summary,
    this.selectedPeriod = AnalyticsPeriod.month,
    this.selectedDate = const Duration(),
    this.isGenerating = false,
    this.errorMessage,
  });

  ReportFormState copyWith({
    String? title,
    String? description,
    ReportType? selectedType,
    AnalyticsPeriod? selectedPeriod,
    DateTime? selectedDate,
    bool? isGenerating,
    String? errorMessage,
  }) {
    return ReportFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      selectedType: selectedType ?? this.selectedType,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      selectedDate: selectedDate ?? this.selectedDate,
      isGenerating: isGenerating ?? this.isGenerating,
      errorMessage: errorMessage,
    );
  }
}

/// Нотификатор формы отчета
class ReportFormNotifier extends StateNotifier<ReportFormState> {
  ReportFormNotifier() : super(const ReportFormState());

  /// Обновить заголовок
  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  /// Обновить описание
  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  /// Выбрать тип отчета
  void selectType(ReportType type) {
    state = state.copyWith(selectedType: type);
  }

  /// Выбрать период
  void selectPeriod(AnalyticsPeriod period) {
    state = state.copyWith(selectedPeriod: period);
  }

  /// Выбрать дату
  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  /// Начать генерацию
  void startGenerating() {
    state = state.copyWith(isGenerating: true, errorMessage: null);
  }

  /// Завершить генерацию
  void finishGenerating() {
    state = state.copyWith(isGenerating: false);
  }

  /// Установить ошибку
  void setError(String error) {
    state = state.copyWith(
      isGenerating: false,
      errorMessage: error,
    );
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Сбросить форму
  void reset() {
    state = const ReportFormState();
  }

  /// Проверить валидность формы
  bool get isValid {
    return state.title.isNotEmpty && state.description.isNotEmpty;
  }
}
