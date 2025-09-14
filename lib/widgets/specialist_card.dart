import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist.dart';
import '../providers/specialist_providers.dart';

/// Карточка специалиста
class SpecialistCard extends ConsumerWidget {
  final Specialist specialist;
  final VoidCallback? onTap;
  final bool showActions;
  final bool showAvailability;

  const SpecialistCard({
    super.key,
    required this.specialist,
    this.onTap,
    this.showActions = true,
    this.showAvailability = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoriteSpecialistsProvider).contains(specialist.id);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с именем и статусом
              _buildHeader(context, ref, isFavorite),
              
              const SizedBox(height: 12),
              
              // Описание
              if (specialist.description != null) ...[
                Text(
                  specialist.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Категория и подкатегории
              _buildCategorySection(),
              
              const SizedBox(height: 12),
              
              // Рейтинг и опыт
              _buildRatingAndExperience(),
              
              const SizedBox(height: 12),
              
              // Цена и доступность
              _buildPriceAndAvailability(),
              
              const SizedBox(height: 12),
              
              // Действия
              if (showActions) _buildActions(context, ref, isFavorite),
            ],
          ),
        ),
      ),
    );
  }

  /// Построить заголовок
  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isFavorite) {
    return Row(
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
              fontSize: 18,
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Имя и статус
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      specialist.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (specialist.isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '✓',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    specialist.categoryDisplayName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (specialist.experienceLevel != ExperienceLevel.beginner) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        specialist.experienceLevelDisplayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        
        // Кнопка избранного
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey,
          ),
          onPressed: () {
            if (isFavorite) {
              ref.read(favoriteSpecialistsProvider.notifier).removeFromFavorites(specialist.id);
            } else {
              ref.read(favoriteSpecialistsProvider.notifier).addToFavorites(specialist.id);
            }
          },
        ),
      ],
    );
  }

  /// Построить секцию категории
  Widget _buildCategorySection() {
    if (specialist.subcategories.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: specialist.subcategories.take(3).map((subcategory) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            subcategory,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Построить рейтинг и опыт
  Widget _buildRatingAndExperience() {
    return Row(
      children: [
        // Рейтинг
        if (specialist.rating > 0) ...[
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                specialist.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${specialist.reviewCount})',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
        
        // Опыт
        Row(
          children: [
            Icon(Icons.work_outline, color: Colors.grey[600], size: 16),
            const SizedBox(width: 4),
            Text(
              '${specialist.yearsOfExperience} лет опыта',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Построить цену и доступность
  Widget _buildPriceAndAvailability() {
    return Row(
      children: [
        // Цена
        Expanded(
          child: Row(
            children: [
              Icon(Icons.attach_money, color: Colors.green[600], size: 16),
              const SizedBox(width: 4),
              Text(
                specialist.priceRange,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),
        
        // Доступность
        if (showAvailability) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: specialist.isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  specialist.isAvailable ? Icons.check_circle : Icons.cancel,
                  color: specialist.isAvailable ? Colors.green : Colors.red,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  specialist.isAvailable ? 'Доступен' : 'Занят',
                  style: TextStyle(
                    fontSize: 12,
                    color: specialist.isAvailable ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Построить действия
  Widget _buildActions(BuildContext context, WidgetRef ref, bool isFavorite) {
    return Row(
      children: [
        // Кнопка "Забронировать"
        Expanded(
          child: ElevatedButton.icon(
            onPressed: specialist.isAvailable ? () => _showBookingDialog(context) : null,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text('Забронировать'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Кнопка "Подробнее"
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.info_outline, size: 16),
          label: const Text('Подробнее'),
        ),
      ],
    );
  }

  /// Показать диалог бронирования
  void _showBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Забронировать ${specialist.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Специалист: ${specialist.name}'),
            Text('Категория: ${specialist.categoryDisplayName}'),
            Text('Цена: ${specialist.priceRange}'),
            const SizedBox(height: 16),
            const Text('Выберите дату и время для бронирования:'),
            const SizedBox(height: 16),
            // TODO: Добавить календарь для выбора даты
            const Text('Календарь будет добавлен в следующем шаге'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Бронирование ${specialist.name} будет реализовано в следующем шаге'),
                ),
              );
            },
            child: const Text('Забронировать'),
          ),
        ],
      ),
    );
  }
}

/// Компактная карточка специалиста для списков
class CompactSpecialistCard extends ConsumerWidget {
  final Specialist specialist;
  final VoidCallback? onTap;

  const CompactSpecialistCard({
    super.key,
    required this.specialist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoriteSpecialistsProvider).contains(specialist.id);

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Аватар
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  specialist.name.isNotEmpty ? specialist.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            specialist.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (specialist.isVerified)
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialist.categoryDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (specialist.rating > 0) ...[
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            specialist.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          specialist.priceRange,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
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
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                  size: 20,
                ),
                onPressed: () {
                  if (isFavorite) {
                    ref.read(favoriteSpecialistsProvider.notifier).removeFromFavorites(specialist.id);
                  } else {
                    ref.read(favoriteSpecialistsProvider.notifier).addToFavorites(specialist.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
