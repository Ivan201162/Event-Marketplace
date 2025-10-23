import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Провайдер для получения аналитики специалиста
final specialistAnalyticsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value({});

  return FirebaseFirestore.instance
      .collection('analytics')
      .doc('specialist_${user.uid}')
      .snapshots()
      .map((snapshot) => snapshot.data() ?? {});
});

/// Провайдер для получения аналитики заказчика
final customerAnalyticsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value({});

  return FirebaseFirestore.instance
      .collection('analytics')
      .doc('customer_${user.uid}')
      .snapshots()
      .map((snapshot) => snapshot.data() ?? {});
});

/// Экран аналитики
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSpecialist = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final specialistDoc = await FirebaseFirestore.instance
        .collection('specialists')
        .doc(user.uid)
        .get();

    setState(() {
      _isSpecialist = specialistDoc.exists;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Аналитика'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: _isSpecialist
              ? TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Как специалист'),
                    Tab(text: 'Как заказчик'),
                  ],
                )
              : null,
        ),
        body: _isSpecialist
            ? TabBarView(
                controller: _tabController,
                children: [_SpecialistAnalyticsTab(), _CustomerAnalyticsTab()],
              )
            : _CustomerAnalyticsTab(),
      );
}

/// Вкладка аналитики специалиста
class _SpecialistAnalyticsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(specialistAnalyticsProvider);

    return analyticsAsync.when(
      data: (analytics) {
        if (analytics.isEmpty) {
          return _buildEmptyState('Аналитика специалиста');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCards(analytics),
              const SizedBox(height: 24),
              _buildIncomeChart(analytics),
              const SizedBox(height: 24),
              _buildBookingsChart(analytics),
              const SizedBox(height: 24),
              _buildTopCustomers(analytics),
              const SizedBox(height: 24),
              _buildRatingStats(analytics),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> analytics) {
    final totalIncome = analytics['totalIncome'] ?? 0.0;
    final totalBookings = analytics['totalBookings'] ?? 0;
    final averageRating = analytics['averageRating'] ?? 0.0;
    final completedBookings = analytics['completedBookings'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Общая статистика',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Общий доход',
              NumberFormat.currency(locale: 'ru_RU', symbol: '₽')
                  .format(totalIncome),
              Icons.attach_money,
              Colors.green,
            ),
            _buildStatCard('Всего заказов', totalBookings.toString(),
                Icons.event, Colors.blue),
            _buildStatCard(
              'Средний рейтинг',
              averageRating.toStringAsFixed(1),
              Icons.star,
              Colors.orange,
            ),
            _buildStatCard(
              'Выполнено',
              completedBookings.toString(),
              Icons.check_circle,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
          String title, String value, IconData icon, Color color) =>
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );

  Widget _buildIncomeChart(Map<String, dynamic> analytics) {
    final monthlyIncome = analytics['monthlyIncome'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Доход по месяцам',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (monthlyIncome.isEmpty)
              const Center(
                child: Text('Данных о доходах пока нет',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              _buildSimpleBarChart(monthlyIncome),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleBarChart(List<dynamic> data) {
    final maxValue = data.isNotEmpty
        ? data
            .map((e) => (e['amount'] ?? 0.0) as double)
            .reduce((a, b) => a > b ? a : b)
        : 1.0;

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: data.take(6).map((item) {
          final amount = (item['amount'] ?? 0.0) as double;
          final month = item['month'] as String? ?? '';
          final height = maxValue > 0 ? (amount / maxValue) * 150 : 0.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                NumberFormat.currency(
                  locale: 'ru_RU',
                  symbol: '₽',
                  decimalDigits: 0,
                ).format(amount),
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(month, style: const TextStyle(fontSize: 10)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingsChart(Map<String, dynamic> analytics) {
    final bookingsByStatus =
        analytics['bookingsByStatus'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Заказы по статусам',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...bookingsByStatus.entries.map((entry) {
              final status = entry.key;
              final count = entry.value as int? ?? 0;
              final color = _getStatusColor(status);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(_getStatusText(status)),
                    const Spacer(),
                    Text(count.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCustomers(Map<String, dynamic> analytics) {
    final topCustomers = analytics['topCustomers'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Топ-5 заказчиков',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (topCustomers.isEmpty)
              const Center(
                child: Text('Данных о заказчиках пока нет',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ...topCustomers.asMap().entries.map((entry) {
                final index = entry.key;
                final customer = entry.value as Map<String, dynamic>;
                final name = customer['name'] as String? ?? 'Неизвестно';
                final bookings = customer['bookings'] as int? ?? 0;
                final totalSpent = customer['totalSpent'] as double? ?? 0.0;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text('$bookings заказов'),
                  trailing: Text(
                    NumberFormat.currency(
                      locale: 'ru_RU',
                      symbol: '₽',
                      decimalDigits: 0,
                    ).format(totalSpent),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStats(Map<String, dynamic> analytics) {
    final ratingDistribution =
        analytics['ratingDistribution'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Распределение оценок',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...ratingDistribution.entries.map((entry) {
              final rating = entry.key;
              final count = entry.value as int? ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < int.parse(rating)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$rating звезд'),
                    const Spacer(),
                    Text(count.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Ожидают подтверждения';
      case 'confirmed':
        return 'Подтверждены';
      case 'completed':
        return 'Выполнены';
      case 'cancelled':
        return 'Отменены';
      default:
        return status;
    }
  }
}

/// Вкладка аналитики заказчика
class _CustomerAnalyticsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(customerAnalyticsProvider);

    return analyticsAsync.when(
      data: (analytics) {
        if (analytics.isEmpty) {
          return _buildEmptyState('Аналитика заказчика');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomerOverviewCards(analytics),
              const SizedBox(height: 24),
              _buildSpendingChart(analytics),
              const SizedBox(height: 24),
              _buildBookingFrequency(analytics),
              const SizedBox(height: 24),
              _buildTopSpecialists(analytics),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildCustomerOverviewCards(Map<String, dynamic> analytics) {
    final totalSpent = analytics['totalSpent'] ?? 0.0;
    final totalBookings = analytics['totalBookings'] ?? 0;
    final averageRating = analytics['averageRating'] ?? 0.0;
    final favoriteCategory =
        analytics['favoriteCategory'] as String? ?? 'Не определено';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Моя статистика',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Потрачено всего',
              NumberFormat.currency(locale: 'ru_RU', symbol: '₽')
                  .format(totalSpent),
              Icons.money_off,
              Colors.red,
            ),
            _buildStatCard(
              'Всего заказов',
              totalBookings.toString(),
              Icons.shopping_cart,
              Colors.blue,
            ),
            _buildStatCard(
              'Средняя оценка',
              averageRating.toStringAsFixed(1),
              Icons.star,
              Colors.orange,
            ),
            _buildStatCard('Любимая категория', favoriteCategory,
                Icons.favorite, Colors.pink),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
          String title, String value, IconData icon, Color color) =>
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );

  Widget _buildSpendingChart(Map<String, dynamic> analytics) {
    final monthlySpending =
        analytics['monthlySpending'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Расходы по месяцам',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (monthlySpending.isEmpty)
              const Center(
                child: Text('Данных о расходах пока нет',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              _buildSimpleBarChart(monthlySpending, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleBarChart(List<dynamic> data, Color color) {
    final maxValue = data.isNotEmpty
        ? data
            .map((e) => (e['amount'] ?? 0.0) as double)
            .reduce((a, b) => a > b ? a : b)
        : 1.0;

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: data.take(6).map((item) {
          final amount = (item['amount'] ?? 0.0) as double;
          final month = item['month'] as String? ?? '';
          final height = maxValue > 0 ? (amount / maxValue) * 150 : 0.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                NumberFormat.currency(
                  locale: 'ru_RU',
                  symbol: '₽',
                  decimalDigits: 0,
                ).format(amount),
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: height,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 4),
              Text(month, style: const TextStyle(fontSize: 10)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingFrequency(Map<String, dynamic> analytics) {
    final bookingFrequency =
        analytics['bookingFrequency'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Частота заказов',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...bookingFrequency.entries.map((entry) {
              final period = entry.key;
              final count = entry.value as int? ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(_getPeriodText(period)),
                    const Spacer(),
                    Text(count.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSpecialists(Map<String, dynamic> analytics) {
    final topSpecialists = analytics['topSpecialists'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Любимые специалисты',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (topSpecialists.isEmpty)
              const Center(
                child: Text('Данных о специалистах пока нет',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ...topSpecialists.asMap().entries.map((entry) {
                final index = entry.key;
                final specialist = entry.value as Map<String, dynamic>;
                final name = specialist['name'] as String? ?? 'Неизвестно';
                final category = specialist['category'] as String? ?? '';
                final bookings = specialist['bookings'] as int? ?? 0;
                final rating = specialist['rating'] as double? ?? 0.0;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text('$category • $bookings заказов'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _getPeriodText(String period) {
    switch (period) {
      case 'thisMonth':
        return 'В этом месяце';
      case 'lastMonth':
        return 'В прошлом месяце';
      case 'thisYear':
        return 'В этом году';
      case 'lastYear':
        return 'В прошлом году';
      default:
        return period;
    }
  }
}

Widget _buildEmptyState(String title) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Аналитика $title',
              style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text(
            'Данных пока нет. Аналитика появится после первых заказов.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

Widget _buildErrorState(String error) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Ошибка загрузки аналитики',
              style: TextStyle(fontSize: 18, color: Colors.red)),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
