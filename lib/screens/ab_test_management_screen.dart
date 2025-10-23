import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ab_test.dart';
import '../services/ab_test_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран управления A/B тестами
class ABTestManagementScreen extends ConsumerStatefulWidget {
  const ABTestManagementScreen({super.key});

  @override
  ConsumerState<ABTestManagementScreen> createState() =>
      _ABTestManagementScreenState();
}

class _ABTestManagementScreenState
    extends ConsumerState<ABTestManagementScreen> {
  final ABTestService _abTestService = ABTestService();
  List<ABTest> _tests = [];
  bool _isLoading = true;
  String _selectedTab = 'tests';

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        appBar: AppBar(title: const Text('Управление A/B тестами')),
        body: Column(
          children: [
            // Вкладки
            _buildTabs(),

            // Контент
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 'tests'
                      ? _buildTestsTab()
                      : _selectedTab == 'create'
                          ? _buildCreateTab()
                          : _buildStatisticsTab(),
            ),
          ],
        ),
      );

  Widget _buildTabs() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(child: _buildTabButton('tests', 'Тесты', Icons.science)),
            Expanded(child: _buildTabButton('create', 'Создать', Icons.add)),
            Expanded(
                child: _buildTabButton(
                    'statistics', 'Статистика', Icons.analytics)),
          ],
        ),
      );

  Widget _buildTabButton(String tab, String title, IconData icon) {
    final isSelected = _selectedTab == tab;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
        if (tab == 'statistics') {
          _loadStatistics();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected
                  ? Colors.blue
                  : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestsTab() => Column(
        children: [
          // Заголовок с кнопками
          ResponsiveCard(
            child: Row(
              children: [
                Text('A/B тесты',
                    style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadTests,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedTab = 'create';
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Создать тест'),
                ),
              ],
            ),
          ),

          // Список тестов
          Expanded(
            child: _tests.isEmpty
                ? const Center(child: Text('A/B тесты не найдены'))
                : ListView.builder(
                    itemCount: _tests.length,
                    itemBuilder: (context, index) {
                      final test = _tests[index];
                      return _buildTestCard(test);
                    },
                  ),
          ),
        ],
      );

  Widget _buildTestCard(ABTest test) {
    final statusColor = _getStatusColor(test.status);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(_getStatusIcon(test.status), color: statusColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(test.name,
                      style: Theme.of(context).textTheme.titleMedium)),
              _buildStatusChip(test.status),
              PopupMenuButton<String>(
                onSelected: (value) => _handleTestAction(value, test),
                itemBuilder: (context) => [
                  if (test.canStart) ...[
                    const PopupMenuItem(
                      value: 'start',
                      child: ListTile(
                          leading: Icon(Icons.play_arrow),
                          title: Text('Запустить')),
                    ),
                  ],
                  if (test.isActive) ...[
                    const PopupMenuItem(
                      value: 'stop',
                      child: ListTile(
                          leading: Icon(Icons.stop), title: Text('Остановить')),
                    ),
                    const PopupMenuItem(
                      value: 'statistics',
                      child: ListTile(
                          leading: Icon(Icons.analytics),
                          title: Text('Статистика')),
                    ),
                  ],
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Редактировать')),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                        leading: Icon(Icons.delete), title: Text('Удалить')),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Описание
          Text(test.description),

          const SizedBox(height: 12),

          // Варианты
          Text(
            'Варианты:',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: test.variants
                .map(
                  (variant) => Chip(
                    label: Text(
                      '${variant.name} (${variant.trafficPercentage.toStringAsFixed(0)}%)',
                    ),
                    backgroundColor: variant.isControl
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: variant.isControl ? Colors.blue : Colors.green,
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 12),

          // Метаданные
          Row(
            children: [
              _buildInfoChip(
                'Трафик',
                '${test.targeting.trafficPercentage.toStringAsFixed(0)}%',
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                  'Метрика', test.metrics.primaryMetric, Colors.green),
            ],
          ),

          const SizedBox(height: 12),

          // Прогресс
          if (test.isActive) ...[
            Text(
              'Прогресс: ${test.completionPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: test.completionPercentage / 100,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
            const SizedBox(height: 8),
          ],

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Создан: ${_formatDateTime(test.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (test.endDate != null) ...[
                const Spacer(),
                Text(
                  'Завершится: ${_formatDateTime(test.endDate!)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTab() => SingleChildScrollView(
        child: ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Создать A/B тест',
                  style: Theme.of(context).textTheme.titleMedium),

              const SizedBox(height: 16),

              // Форма создания теста
              _buildCreateTestForm(),
            ],
          ),
        ),
      );

  Widget _buildCreateTestForm() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final primaryMetricController = TextEditingController();
    final trafficController = TextEditingController(text: '100');

    return Column(
      children: [
        // Основная информация
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Название теста',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
              labelText: 'Описание', border: OutlineInputBorder()),
          maxLines: 3,
        ),

        const SizedBox(height: 16),

        TextField(
          controller: primaryMetricController,
          decoration: const InputDecoration(
            labelText: 'Основная метрика',
            border: OutlineInputBorder(),
            hintText: 'Например: conversion_rate, click_rate',
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: trafficController,
          decoration: const InputDecoration(
            labelText: 'Процент трафика',
            border: OutlineInputBorder(),
            suffixText: '%',
          ),
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 24),

        // Кнопка создания
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _createTest(
              nameController.text,
              descriptionController.text,
              primaryMetricController.text,
              double.tryParse(trafficController.text) ?? 100.0,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Создать тест'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() => FutureBuilder<List<ABTestStatistics>>(
        future: _loadAllStatistics(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final statistics = snapshot.data!;

          return SingleChildScrollView(
            child:
                Column(children: statistics.map(_buildStatisticsCard).toList()),
          );
        },
      );

  Widget _buildStatisticsCard(ABTestStatistics stats) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Статистика: ${stats.testName}',
                style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 16),

            // Основные метрики
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Участники',
                    '${stats.totalParticipants}',
                    Colors.blue,
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Конверсии',
                    '${stats.totalConversions}',
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Конверсия',
                    '${(stats.overallConversionRate * 100).toStringAsFixed(2)}%',
                    Colors.orange,
                    Icons.percent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Статистика по вариантам
            Text(
              'Результаты по вариантам:',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),

            const SizedBox(height: 8),

            ...stats.variantStatistics.values.map(
              (variantStats) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            variantStats.variantName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${variantStats.participants} участников, ${variantStats.conversions} конверсий',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(variantStats.conversionRate * 100).toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Статистическая значимость
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: stats.isStatisticallySignificant
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: stats.isStatisticallySignificant
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    stats.isStatisticallySignificant
                        ? Icons.check_circle
                        : Icons.warning,
                    color: stats.isStatisticallySignificant
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stats.isStatisticallySignificant
                          ? 'Результаты статистически значимы (${(stats.confidenceLevel * 100).toStringAsFixed(0)}% доверия)'
                          : 'Результаты не статистически значимы',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: stats.isStatisticallySignificant
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildStatCard(
          String title, String value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildStatusChip(ABTestStatus status) {
    final color = _getStatusColor(status);
    final text = status.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(
          '$label: $value',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      );

  Color _getStatusColor(ABTestStatus status) {
    switch (status) {
      case ABTestStatus.draft:
        return Colors.grey;
      case ABTestStatus.running:
        return Colors.green;
      case ABTestStatus.paused:
        return Colors.orange;
      case ABTestStatus.completed:
        return Colors.blue;
      case ABTestStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ABTestStatus status) {
    switch (status) {
      case ABTestStatus.draft:
        return Icons.edit;
      case ABTestStatus.running:
        return Icons.play_arrow;
      case ABTestStatus.paused:
        return Icons.pause;
      case ABTestStatus.completed:
        return Icons.check_circle;
      case ABTestStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  Future<void> _loadTests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tests = await _abTestService.getABTests();
      setState(() {
        _tests = tests;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка загрузки A/B тестов: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    // Статистика загружается автоматически в _buildStatisticsTab()
  }

  Future<List<ABTestStatistics>> _loadAllStatistics() async {
    try {
      final activeTests =
          _tests.where((test) => test.isActive || test.isCompleted).toList();
      final statistics = <ABTestStatistics>[];

      for (final test in activeTests) {
        try {
          final stats = await _abTestService.getTestStatistics(test.id);
          statistics.add(stats);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Ошибка загрузки статистики для теста ${test.id}: $e');
          }
        }
      }

      return statistics;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка загрузки статистики: $e');
      }
      return [];
    }
  }

  void _handleTestAction(String action, ABTest test) {
    switch (action) {
      case 'start':
        _startTest(test);
        break;
      case 'stop':
        _stopTest(test);
        break;
      case 'statistics':
        _showTestStatistics(test);
        break;
      case 'edit':
        _editTest(test);
        break;
      case 'delete':
        _deleteTest(test);
        break;
    }
  }

  Future<void> _startTest(ABTest test) async {
    try {
      await _abTestService.startABTest(test.id);
      unawaited(_loadTests());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('A/B тест "${test.name}" запущен'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка запуска теста: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _stopTest(ABTest test) async {
    try {
      await _abTestService.stopABTest(test.id);
      unawaited(_loadTests());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A/B тест "${test.name}" остановлен'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка остановки теста: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showTestStatistics(ABTest test) {
    // TODO(developer): Показать детальную статистику теста
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
        content: Text('Статистика для теста "${test.name}" будет показана')));
  }

  void _editTest(ABTest test) {
    // TODO(developer): Реализовать редактирование теста
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Редактирование теста "${test.name}" будет реализовано')),
    );
  }

  void _deleteTest(ABTest test) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить A/B тест'),
        content: Text('Вы уверены, что хотите удалить тест "${test.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _abTestService.deleteABTest(test.id);
                unawaited(_loadTests());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('A/B тест удален'),
                      backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Ошибка удаления теста: $e'),
                      backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTest(
    String name,
    String description,
    String primaryMetric,
    double trafficPercentage,
  ) async {
    if (name.isEmpty || description.isEmpty || primaryMetric.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните все обязательные поля'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Создаем варианты по умолчанию
      final variants = [
        ABTestVariant(
          id: 'control',
          name: 'Контрольная группа',
          description: 'Оригинальная версия',
          trafficPercentage: 50,
          isControl: true,
          createdAt: DateTime.now(),
        ),
        ABTestVariant(
          id: 'treatment',
          name: 'Тестовая группа',
          description: 'Новая версия',
          trafficPercentage: 50,
          createdAt: DateTime.now(),
        ),
      ];

      final targeting = ABTestTargeting(trafficPercentage: trafficPercentage);

      final metrics = ABTestMetrics(primaryMetric: primaryMetric);

      await _abTestService.createABTest(
        name: name,
        description: description,
        variants: variants,
        targeting: targeting,
        metrics: metrics,
      );

      unawaited(_loadTests());
      setState(() {
        _selectedTab = 'tests';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('A/B тест "$name" создан'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка создания теста: $e'),
            backgroundColor: Colors.red),
      );
    }
  }
}
