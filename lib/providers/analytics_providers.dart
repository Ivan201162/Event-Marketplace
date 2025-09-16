import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics.dart';
import '../services/analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final userAnalyticsProvider =
    StreamProvider.family<List<Analytics>, (String, AnalyticsFilter)>(
        (ref, params) {
  final (userId, filter) = params;
  final service = ref.read(analyticsServiceProvider);
  return service.getUserAnalytics(userId, filter);
});

final incomeExpenseStatsProvider =
    FutureProvider.family<IncomeExpenseStats, (String, AnalyticsFilter)>(
        (ref, params) {
  final (userId, filter) = params;
  final service = ref.read(analyticsServiceProvider);
  return service.getIncomeExpenseStats(userId, filter);
});

final userBudgetGoalsProvider =
    StreamProvider.family<List<BudgetGoal>, String>((ref, userId) {
  final service = ref.read(analyticsServiceProvider);
  return service.getUserBudgetGoals(userId);
});

final analyticsFilterProvider = StateProvider<AnalyticsFilter>((ref) {
  return const AnalyticsFilter();
});

final incomeChartDataProvider =
    FutureProvider.family<List<ChartData>, (String, int)>((ref, params) {
  final (userId, months) = params;
  final service = ref.read(analyticsServiceProvider);
  return service.getIncomeChartData(userId, months);
});

final expenseChartDataProvider =
    FutureProvider.family<List<ChartData>, (String, int)>((ref, params) {
  final (userId, months) = params;
  final service = ref.read(analyticsServiceProvider);
  return service.getExpenseChartData(userId, months);
});

final incomeCategoryChartDataProvider =
    FutureProvider.family<List<ChartData>, (String, AnalyticsFilter)>(
        (ref, params) {
  final (userId, filter) = params;
  final service = ref.read(analyticsServiceProvider);
  return service.getIncomeCategoryChartData(userId, filter);
});

final expenseCategoryChartDataProvider =
    FutureProvider.family<List<ChartData>, (String, AnalyticsFilter)>(
        (ref, params) {
  final (userId, filter) = params;
  final service = ref.read(analyticsServiceProvider);
  return service.getExpenseCategoryChartData(userId, filter);
});
