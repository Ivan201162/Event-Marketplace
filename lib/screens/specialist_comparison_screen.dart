import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist.dart';
import '../models/specialist_comparison.dart';
import '../widgets/specialist_comparison_card.dart';

class SpecialistComparisonScreen extends ConsumerStatefulWidget {
  const SpecialistComparisonScreen({super.key});

  @override
  ConsumerState<SpecialistComparisonScreen> createState() => _SpecialistComparisonScreenState();
}

class _SpecialistComparisonScreenState extends ConsumerState<SpecialistComparisonScreen> {
  SpecialistComparison _comparison = SpecialistComparison.empty();
  ComparisonCriteria _sortCriteria = ComparisonCriteria.rating;
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Сравнение специалистов'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        if (!_comparison.isEmpty)
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearComparison,
            tooltip: 'Очистить сравнение',
          ),
      ],
    ),
    body: _comparison.isEmpty
        ? _buildEmptyState()
        : Column(
            children: [
              // Панель управления
              _buildControlPanel(),

              // Статистика
              _buildStatsPanel(),

              // Список специалистов
              Expanded(child: _buildComparisonList()),
            ],
          ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.compare_arrows, size: 64, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text('Нет специалистов для сравнения', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Добавьте специалистов из списка для сравнения',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/advanced-search'),
          icon: const Icon(Icons.search),
          label: const Text('Найти специалистов'),
        ),
      ],
    ),
  );

  Widget _buildControlPanel() => Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Управление сравнением',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_comparison.count}/${SpecialistComparison.maxSpecialists}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Сортировка
          Row(
            children: [
              const Text('Сортировка:'),
              const SizedBox(width: 8),
              DropdownButton<ComparisonCriteria>(
                value: _sortCriteria,
                items: ComparisonCriteria.values
                    .map(
                      (criteria) => DropdownMenuItem(value: criteria, child: Text(criteria.label)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortCriteria = value;
                    });
                  }
                },
              ),
              const Spacer(),
              IconButton(
                icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                tooltip: _sortAscending ? 'По возрастанию' : 'По убыванию',
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildStatsPanel() {
    final stats = _comparison.stats;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика сравнения',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Средний рейтинг',
                    '${stats.averageRating.toStringAsFixed(1)} ⭐',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Диапазон цен',
                    stats.priceRange.displayString,
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Диапазон опыта',
                    stats.experienceRange.displayString,
                    Icons.work,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Общие услуги',
                    '${stats.commonServices.length}',
                    Icons.list,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _buildComparisonList() {
    final sortedSpecialists = _getSortedSpecialists();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSpecialists.length,
      itemBuilder: (context, index) {
        final specialist = sortedSpecialists[index];
        final isBest = _isBestSpecialist(specialist);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SpecialistComparisonCard(
            specialist: specialist,
            isBest: isBest,
            onRemove: () => _removeSpecialist(specialist.id),
            onViewProfile: () => _viewSpecialistProfile(specialist),
            onBook: () => _bookSpecialist(specialist),
          ),
        );
      },
    );
  }

  List<Specialist> _getSortedSpecialists() {
    final specialists = List<Specialist>.from(_comparison.specialists);

    specialists.sort((a, b) {
      var comparison = 0;

      switch (_sortCriteria) {
        case ComparisonCriteria.rating:
          comparison = a.rating.compareTo(b.rating);
          break;
        case ComparisonCriteria.price:
          comparison = a.hourlyRate.compareTo(b.hourlyRate);
          break;
        case ComparisonCriteria.experience:
          comparison = a.yearsOfExperience.compareTo(b.yearsOfExperience);
          break;
        case ComparisonCriteria.reviews:
          comparison = a.reviewCount.compareTo(b.reviewCount);
          break;
        case ComparisonCriteria.availability:
          comparison = a.isAvailable.toString().compareTo(b.isAvailable.toString());
          break;
        case ComparisonCriteria.location:
          comparison = (a.location ?? '').compareTo(b.location ?? '');
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return specialists;
  }

  bool _isBestSpecialist(Specialist specialist) {
    switch (_sortCriteria) {
      case ComparisonCriteria.rating:
        return specialist.rating ==
            _comparison.specialists.map((s) => s.rating).reduce((a, b) => a > b ? a : b);
      case ComparisonCriteria.price:
        return specialist.hourlyRate ==
            _comparison.specialists.map((s) => s.hourlyRate).reduce((a, b) => a < b ? a : b);
      case ComparisonCriteria.experience:
        return specialist.yearsOfExperience ==
            _comparison.specialists.map((s) => s.yearsOfExperience).reduce((a, b) => a > b ? a : b);
      case ComparisonCriteria.reviews:
        return specialist.reviewCount ==
            _comparison.specialists.map((s) => s.reviewCount).reduce((a, b) => a > b ? a : b);
      case ComparisonCriteria.availability:
        return specialist.isAvailable;
      case ComparisonCriteria.location:
        return true; // Все равны по локации
    }
  }

  void _clearComparison() {
    setState(() {
      _comparison = SpecialistComparison.empty();
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сравнение очищено')));
  }

  void _removeSpecialist(String specialistId) {
    setState(() {
      _comparison = _comparison.removeSpecialist(specialistId);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Специалист удален из сравнения')));
  }

  void _viewSpecialistProfile(Specialist specialist) {
    Navigator.pushNamed(context, '/specialist-profile', arguments: specialist.id);
  }

  void _bookSpecialist(Specialist specialist) {
    Navigator.pushNamed(context, '/booking', arguments: specialist.id);
  }

  /// Добавить специалиста для сравнения (вызывается извне)
  void addSpecialist(Specialist specialist) {
    if (!_comparison.canAddSpecialist(specialist)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя добавить этого специалиста для сравнения')),
      );
      return;
    }

    setState(() {
      _comparison = _comparison.addSpecialist(specialist);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${specialist.name} добавлен для сравнения')));
  }
}
