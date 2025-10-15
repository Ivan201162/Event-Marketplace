import 'package:flutter/material.dart';
import '../models/smart_specialist.dart';
import '../models/specialist.dart';

/// Карточка специалиста с поддержкой умного поиска
class SpecialistCard extends StatelessWidget {
  const SpecialistCard({
    super.key,
    required this.specialist,
    this.showCompatibility = false,
    this.onTap,
    this.onFavorite,
    this.onContact,
  });

  final dynamic specialist; // SmartSpecialist или Specialist
  final bool showCompatibility;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с фото и основной информацией
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Фото специалиста
                    _buildAvatar(),

                    const SizedBox(width: 12),

                    // Основная информация
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Имя и категория
                          Text(
                            _getSpecialistName(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Категория и город
                          Row(
                            children: [
                              Text(
                                _getCategoryDisplayName(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              if (_getCity() != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _getCity()!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Рейтинг и отзывы
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getRating().toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${_getReviewCount()} отзывов)',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Кнопка избранного
                    IconButton(
                      icon: Icon(
                        Icons.favorite_border,
                        color: Colors.grey[600],
                      ),
                      onPressed: onFavorite,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Описание
                if (_getDescription() != null) ...[
                  Text(
                    _getDescription()!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],

                // Стили работы
                if (_getStyles().isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _getStyles()
                        .take(3)
                        .map(
                          (style) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              style,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Совместимость
                if (showCompatibility && _getCompatibilityScore() > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          color: Colors.green[700],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Совместимость: ${(_getCompatibilityScore() * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Цена и кнопки действий
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Цена
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPriceRangeString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (_getExperienceYears() > 0)
                          Text(
                            'Опыт: ${_getExperienceYears()} лет',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),

                    // Кнопки действий
                    Row(
                      children: [
                        // Кнопка "Написать"
                        ElevatedButton.icon(
                          onPressed: onContact,
                          icon: const Icon(Icons.message, size: 16),
                          label: const Text('Написать'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Кнопка "Подробнее"
                        OutlinedButton(
                          onPressed: onTap,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('Подробнее'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  /// Построить аватар
  Widget _buildAvatar() {
    final imageUrl = _getImageUrl();
    final name = _getSpecialistName();

    return CircleAvatar(
      radius: 30,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
      child: imageUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  /// Получить имя специалиста
  String _getSpecialistName() => specialist is SmartSpecialist
      ? (specialist as SmartSpecialist).name
      : specialist is Specialist
          ? (specialist as Specialist).name
          : 'Специалист';

  /// Получить отображаемое название категории
  String _getCategoryDisplayName() => specialist is SmartSpecialist
      ? (specialist as SmartSpecialist).categoryDisplayName
      : specialist is Specialist
          ? (specialist as Specialist).categoryDisplayName
          : 'Специалист';

  /// Получить город
  String? _getCity() => specialist is SmartSpecialist
      ? (specialist as SmartSpecialist).city
      : specialist is Specialist
          ? (specialist as Specialist).city
          : null;

  /// Получить рейтинг
  double _getRating() => specialist is SmartSpecialist
      ? (specialist as SmartSpecialist).rating
      : specialist is Specialist
          ? (specialist as Specialist).rating
          : 0.0;

  /// Получить количество отзывов
  int _getReviewCount() => specialist is SmartSpecialist
      ? (specialist as SmartSpecialist).reviewsCount
      : specialist is Specialist
          ? (specialist as Specialist).reviewsCount
          : 0;

  /// Получить описание
  String? _getDescription() => specialist is SmartSpecialist
      ? (specialist as SmartSpecialist).description
      : specialist is Specialist
          ? (specialist as Specialist).description
          : null;

  /// Получить стили
  List<String> _getStyles() => specialist is SmartSpecialist
      ? (specialist as SmartSpecialist).styles
      : <String>[];

  /// Получить балл совместимости
  double _getCompatibilityScore() => specialist is SmartSpecialist
      ? (specialist as SmartSpecialist).compatibilityScore
      : 0.0;

  /// Получить диапазон цен
  String _getPriceRangeString() => specialist is SmartSpecialist
      ? (specialist as SmartSpecialist).priceRangeString
      : specialist is Specialist
          ? (specialist as Specialist).priceRangeString
          : 'Цена не указана';

  /// Получить годы опыта
  int _getExperienceYears() => specialist is SmartSpecialist
      ? (specialist as SmartSpecialist).yearsOfExperience
      : specialist is Specialist
          ? (specialist as Specialist).yearsOfExperience
          : 0;

  /// Получить URL изображения
  String? _getImageUrl() => specialist is SmartSpecialist
      ? (specialist as SmartSpecialist).imageUrlValue
      : specialist is Specialist
          ? (specialist as Specialist).imageUrlValue
          : null;
}
