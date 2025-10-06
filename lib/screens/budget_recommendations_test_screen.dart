import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist.dart';
import '../widgets/budget_recommendations_widget.dart';

/// Экран для тестирования рекомендаций по бюджету
class BudgetRecommendationsTestScreen extends ConsumerStatefulWidget {
  const BudgetRecommendationsTestScreen({super.key});

  @override
  ConsumerState<BudgetRecommendationsTestScreen> createState() =>
      _BudgetRecommendationsTestScreenState();
}

class _BudgetRecommendationsTestScreenState
    extends ConsumerState<BudgetRecommendationsTestScreen> {
  final List<String> _selectedSpecialistIds = [];
  final String _testUserId = 'test_user_123';
  double _currentBudget = 50000;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Тест рекомендаций по бюджету'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            _buildBudgetAndSpecialistSelection(),
            const Divider(),
            Expanded(
              child: _selectedSpecialistIds.isEmpty
                  ? const Center(
                      child: Text(
                        'Выберите специалистов для анализа бюджета',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : BudgetRecommendationsWidget(
                      currentBudget: _currentBudget,
                      selectedSpecialistIds: _selectedSpecialistIds,
                      userId: _testUserId,
                      onBudgetIncrease: _onBudgetIncrease,
                    ),
            ),
          ],
        ),
      );

  Widget _buildBudgetAndSpecialistSelection() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Бюджет
            const Text(
              'Текущий бюджет:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _currentBudget,
                    min: 10000,
                    max: 200000,
                    divisions: 19,
                    label: '${_currentBudget.toStringAsFixed(0)} ₽',
                    onChanged: (value) {
                      setState(() {
                        _currentBudget = value;
                      });
                    },
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${_currentBudget.toStringAsFixed(0)} ₽',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Выбор специалистов
            const Text(
              'Выберите специалистов:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildSpecialistChips(),
            ),
            const SizedBox(height: 16),
            if (_selectedSpecialistIds.isNotEmpty) ...[
              const Text(
                'Выбранные специалисты:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildSelectedSpecialistChips(),
              ),
            ],
          ],
        ),
      );

  List<Widget> _buildSpecialistChips() {
    const testSpecialists = [
      _TestSpecialist('host_1', 'Ведущий Иван', SpecialistCategory.host),
      _TestSpecialist('dj_1', 'DJ Мария', SpecialistCategory.dj),
      _TestSpecialist(
        'photographer_1',
        'Фотограф Алексей',
        SpecialistCategory.photographer,
      ),
      _TestSpecialist(
        'videographer_1',
        'Видеограф Елена',
        SpecialistCategory.videographer,
      ),
      _TestSpecialist(
        'decorator_1',
        'Декоратор Ольга',
        SpecialistCategory.decorator,
      ),
      _TestSpecialist(
        'musician_1',
        'Музыкант Дмитрий',
        SpecialistCategory.musician,
      ),
      _TestSpecialist(
        'animator_1',
        'Аниматор Анна',
        SpecialistCategory.animator,
      ),
    ];

    return testSpecialists.map((specialist) {
      final isSelected = _selectedSpecialistIds.contains(specialist.id);
      return FilterChip(
        label: Text(specialist.name),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _selectedSpecialistIds.add(specialist.id);
            } else {
              _selectedSpecialistIds.remove(specialist.id);
            }
          });
        },
        avatar: Text(specialist.category.emoji),
      );
    }).toList();
  }

  List<Widget> _buildSelectedSpecialistChips() =>
      _selectedSpecialistIds.map((id) {
        final specialist = _getTestSpecialistById(id);
        return Chip(
          label: Text(specialist.name),
          avatar: Text(specialist.category.emoji),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _selectedSpecialistIds.remove(id);
            });
          },
        );
      }).toList();

  void _onBudgetIncrease(double additionalBudget, SpecialistCategory category) {
    setState(() {
      _currentBudget += additionalBudget;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Бюджет увеличен на ${additionalBudget.toStringAsFixed(0)} ₽ для ${category.displayName}',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  _TestSpecialist _getTestSpecialistById(String id) {
    const testSpecialists = [
      _TestSpecialist('host_1', 'Ведущий Иван', SpecialistCategory.host),
      _TestSpecialist('dj_1', 'DJ Мария', SpecialistCategory.dj),
      _TestSpecialist(
        'photographer_1',
        'Фотограф Алексей',
        SpecialistCategory.photographer,
      ),
      _TestSpecialist(
        'videographer_1',
        'Видеограф Елена',
        SpecialistCategory.videographer,
      ),
      _TestSpecialist(
        'decorator_1',
        'Декоратор Ольга',
        SpecialistCategory.decorator,
      ),
      _TestSpecialist(
        'musician_1',
        'Музыкант Дмитрий',
        SpecialistCategory.musician,
      ),
      _TestSpecialist(
        'animator_1',
        'Аниматор Анна',
        SpecialistCategory.animator,
      ),
    ];

    return testSpecialists.firstWhere((s) => s.id == id);
  }
}

/// Тестовый класс специалиста
class _TestSpecialist {
  const _TestSpecialist(this.id, this.name, this.category);

  final String id;
  final String name;
  final SpecialistCategory category;
}

/// Расширение для эмодзи категорий
extension SpecialistCategoryEmoji on SpecialistCategory {
  String get emoji {
    switch (this) {
      case SpecialistCategory.host:
        return '🎤';
      case SpecialistCategory.dj:
        return '🎧';
      case SpecialistCategory.photographer:
        return '📸';
      case SpecialistCategory.videographer:
        return '🎬';
      case SpecialistCategory.decorator:
        return '🎨';
      case SpecialistCategory.musician:
        return '🎵';
      case SpecialistCategory.animator:
        return '🎭';
      case SpecialistCategory.makeup:
        return '💄';
      case SpecialistCategory.florist:
        return '🌸';
      case SpecialistCategory.lighting:
        return '💡';
      case SpecialistCategory.sound:
        return '🔊';
      default:
        return '👤';
    }
  }
}
