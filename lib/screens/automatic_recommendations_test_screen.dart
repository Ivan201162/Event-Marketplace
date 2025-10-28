import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/widgets/automatic_recommendations_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран для тестирования автоматических рекомендаций
class AutomaticRecommendationsTestScreen extends ConsumerStatefulWidget {
  const AutomaticRecommendationsTestScreen({super.key});

  @override
  ConsumerState<AutomaticRecommendationsTestScreen> createState() =>
      _AutomaticRecommendationsTestScreenState();
}

class _AutomaticRecommendationsTestScreenState
    extends ConsumerState<AutomaticRecommendationsTestScreen> {
  final List<String> _selectedSpecialistIds = [];
  final String _testUserId = 'test_user_123';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Тест автоматических рекомендаций'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            _buildSpecialistSelection(),
            const Divider(),
            Expanded(
              child: _selectedSpecialistIds.isEmpty
                  ? const Center(
                      child: Text(
                        'Выберите специалистов для получения рекомендаций',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : AutomaticRecommendationsWidget(
                      selectedSpecialistIds: _selectedSpecialistIds,
                      userId: _testUserId,
                      onSpecialistSelected: _onSpecialistSelected,
                    ),
            ),
          ],
        ),
      );

  Widget _buildSpecialistSelection() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите специалистов:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: _buildSpecialistChips()),
            const SizedBox(height: 16),
            if (_selectedSpecialistIds.isNotEmpty) ...[
              const Text(
                'Выбранные специалисты:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildSelectedSpecialistChips(),),
            ],
          ],
        ),
      );

  List<Widget> _buildSpecialistChips() {
    const testSpecialists = [
      _TestSpecialist('host_1', 'Ведущий Иван', SpecialistCategory.host),
      _TestSpecialist('dj_1', 'DJ Мария', SpecialistCategory.dj),
      _TestSpecialist('photographer_1', 'Фотограф Алексей',
          SpecialistCategory.photographer,),
      _TestSpecialist(
          'videographer_1', 'Видеограф Елена', SpecialistCategory.videographer,),
      _TestSpecialist(
          'decorator_1', 'Декоратор Ольга', SpecialistCategory.decorator,),
      _TestSpecialist(
          'musician_1', 'Музыкант Дмитрий', SpecialistCategory.musician,),
      _TestSpecialist(
          'animator_1', 'Аниматор Анна', SpecialistCategory.animator,),
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

  void _onSpecialistSelected(Specialist specialist) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Выбран специалист: ${specialist.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  _TestSpecialist _getTestSpecialistById(String id) {
    const testSpecialists = [
      _TestSpecialist('host_1', 'Ведущий Иван', SpecialistCategory.host),
      _TestSpecialist('dj_1', 'DJ Мария', SpecialistCategory.dj),
      _TestSpecialist('photographer_1', 'Фотограф Алексей',
          SpecialistCategory.photographer,),
      _TestSpecialist(
          'videographer_1', 'Видеограф Елена', SpecialistCategory.videographer,),
      _TestSpecialist(
          'decorator_1', 'Декоратор Ольга', SpecialistCategory.decorator,),
      _TestSpecialist(
          'musician_1', 'Музыкант Дмитрий', SpecialistCategory.musician,),
      _TestSpecialist(
          'animator_1', 'Аниматор Анна', SpecialistCategory.animator,),
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
