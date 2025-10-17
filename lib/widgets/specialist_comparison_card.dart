import 'package:flutter/material.dart';

import '../models/specialist.dart';
import '../models/specialist_comparison.dart';

class SpecialistComparisonCard extends StatelessWidget {
  const SpecialistComparisonCard({
    super.key,
    required this.specialist,
    required this.isBest,
    required this.onRemove,
    required this.onViewProfile,
    required this.onBook,
  });
  final Specialist specialist;
  final bool isBest;
  final VoidCallback onRemove;
  final VoidCallback onViewProfile;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) => Card(
        elevation: isBest ? 4 : 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isBest ? Border.all(color: Colors.amber, width: 2) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с кнопкой удаления
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Аватар
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              specialist.name.isNotEmpty ? specialist.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Имя и категория
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  specialist.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  specialist.category.displayName,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Индикатор лучшего
                    if (isBest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Лучший',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(width: 8),

                    // Кнопка удаления
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onRemove,
                      tooltip: 'Удалить из сравнения',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Основные характеристики
                _buildCharacteristics(),

                const SizedBox(height: 16),

                // Описание
                if (specialist.description != null && specialist.description!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Описание:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialist.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Услуги
                if (specialist.services.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Услуги:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: specialist.services
                            .take(3)
                            .map(
                              (service) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  service,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      if (specialist.services.length > 3)
                        Text(
                          'и еще ${specialist.services.length - 3}...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Кнопки действий
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewProfile,
                        icon: const Icon(Icons.person),
                        label: const Text('Профиль'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: specialist.isAvailable ? onBook : null,
                        icon: const Icon(Icons.book_online),
                        label: const Text('Забронировать'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildCharacteristics() => Row(
        children: [
          // Рейтинг
          Expanded(
            child: _buildCharacteristicItem(
              'Рейтинг',
              '${specialist.rating.toStringAsFixed(1)} ⭐',
              Icons.star,
              Colors.amber,
            ),
          ),

          // Цена
          Expanded(
            child: _buildCharacteristicItem(
              'Цена',
              '${specialist.hourlyRate.toStringAsFixed(0)} ₽/час',
              Icons.attach_money,
              Colors.green,
            ),
          ),

          // Опыт
          Expanded(
            child: _buildCharacteristicItem(
              'Опыт',
              '${specialist.yearsOfExperience} лет',
              Icons.work,
              Colors.blue,
            ),
          ),
        ],
      );

  Widget _buildCharacteristicItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Container(
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

/// Виджет для отображения детального сравнения
class DetailedComparisonWidget extends StatelessWidget {
  const DetailedComparisonWidget({
    super.key,
    required this.comparison,
    required this.criteria,
  });
  final SpecialistComparison comparison;
  final ComparisonCriteria criteria;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Сравнение по ${criteria.label.toLowerCase()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Таблица сравнения
              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                children: [
                  // Заголовок
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Критерий',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...comparison.specialists.map(
                        (specialist) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            specialist.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Строки сравнения
                  _buildComparisonRow(
                    'Рейтинг',
                    (s) => '${s.rating.toStringAsFixed(1)} ⭐',
                  ),
                  _buildComparisonRow(
                    'Цена',
                    (s) => '${s.hourlyRate.toStringAsFixed(0)} ₽/час',
                  ),
                  _buildComparisonRow(
                    'Опыт',
                    (s) => '${s.yearsOfExperience} лет',
                  ),
                  _buildComparisonRow('Отзывы', (s) => '${s.reviewCount}'),
                  _buildComparisonRow(
                    'Доступность',
                    (s) => s.isAvailable ? 'Доступен' : 'Занят',
                  ),
                  _buildComparisonRow(
                    'Локация',
                    (s) => s.location ?? 'Не указана',
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  TableRow _buildComparisonRow(
    String label,
    String Function(Specialist) getValue,
  ) =>
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(label),
          ),
          ...comparison.specialists.map(
            (specialist) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                getValue(specialist),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
}
