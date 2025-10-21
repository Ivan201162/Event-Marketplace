import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist.dart';
import '../providers/specialist_pricing_providers.dart';
import '../widgets/specialist_average_price_widget.dart';

/// Экран для тестирования среднего прайса специалиста
class SpecialistPricingTestScreen extends ConsumerStatefulWidget {
  const SpecialistPricingTestScreen({super.key});

  @override
  ConsumerState<SpecialistPricingTestScreen> createState() => _SpecialistPricingTestScreenState();
}

class _SpecialistPricingTestScreenState extends ConsumerState<SpecialistPricingTestScreen> {
  String? _selectedSpecialistId;
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Тест среднего прайса специалиста'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    body: Column(
      children: [
        _buildSpecialistSelection(),
        const Divider(),
        Expanded(
          child: _selectedSpecialistId == null
              ? const Center(
                  child: Text(
                    'Выберите специалиста для просмотра статистики цен',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : SpecialistAveragePriceWidget(
                  specialistId: _selectedSpecialistId!,
                  showHistory: _showHistory,
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
          'Выберите специалиста:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _buildSpecialistChips()),
        const SizedBox(height: 16),
        if (_selectedSpecialistId != null) ...[
          const Text(
            'Настройки отображения:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Показать историю цен'),
            subtitle: const Text('Отображать график изменения цен по месяцам'),
            value: _showHistory,
            onChanged: (value) {
              setState(() {
                _showHistory = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _updatePricingData,
            icon: const Icon(Icons.refresh),
            label: const Text('Обновить данные'),
          ),
        ],
      ],
    ),
  );

  List<Widget> _buildSpecialistChips() {
    const testSpecialists = [
      _TestSpecialist('specialist_1', 'Фотограф Алексей', SpecialistCategory.photographer),
      _TestSpecialist('specialist_2', 'Видеограф Елена', SpecialistCategory.videographer),
      _TestSpecialist('specialist_3', 'Ведущий Иван', SpecialistCategory.host),
      _TestSpecialist('specialist_4', 'DJ Мария', SpecialistCategory.dj),
      _TestSpecialist('specialist_5', 'Декоратор Ольга', SpecialistCategory.decorator),
      _TestSpecialist('specialist_6', 'Музыкант Дмитрий', SpecialistCategory.musician),
      _TestSpecialist('specialist_7', 'Аниматор Анна', SpecialistCategory.animator),
    ];

    return testSpecialists.map((specialist) {
      final isSelected = _selectedSpecialistId == specialist.id;
      return FilterChip(
        label: Text(specialist.name),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedSpecialistId = selected ? specialist.id : null;
          });
        },
        avatar: Text(specialist.category.emoji),
      );
    }).toList();
  }

  Future<void> _updatePricingData() async {
    if (_selectedSpecialistId == null) return;

    try {
      final notifier = ref.read(specialistPricingProvider.notifier);
      await notifier.updateSpecialistAveragePrice(_selectedSpecialistId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные о ценах обновлены'), backgroundColor: Colors.green),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
