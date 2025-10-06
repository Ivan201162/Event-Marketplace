import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../models/specialist.dart';
import 'safe_button.dart';

class SpecialistCard extends ConsumerWidget {
  const SpecialistCard({
    super.key,
    required this.specialist,
    this.onTap,
    this.showFullInfo = false,
    this.showFavoriteButton = true,
    this.showQuickActions = true,
  });
  final Specialist specialist;
  final VoidCallback? onTap;
  final bool showFullInfo;
  final bool showFavoriteButton;
  final bool showQuickActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с аватаром и основной информацией
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: BrandColors.primary.withOpacity(0.1),
                          backgroundImage: specialist.imageUrlValue != null
                              ? NetworkImage(specialist.imageUrlValue!)
                              : null,
                          child: specialist.imageUrlValue == null
                              ? Text(
                                  specialist.name.isNotEmpty
                                      ? specialist.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: BrandColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        if (specialist.isVerified)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: BrandColors.primary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.verified,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  specialist.displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showFavoriteButton)
                                IconButton(
                                  icon: const Icon(Icons.favorite_border),
                                  onPressed: () {
                                    // Добавляем в избранное
                                    _addToFavorites(context, specialist);
                                  },
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                specialist.category.icon,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                specialist.category.displayName,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                specialist.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${specialist.reviewsCount} отзывов)',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              if (specialist.isOnline ?? false) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Онлайн',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${specialist.price.toInt()}₽',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: BrandColors.accent,
                          ),
                        ),
                        const Text(
                          'за час',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        if (specialist.priceRange != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'от ${specialist.priceRange!.minPrice.toInt()}₽',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Описание
                if (specialist.description != null &&
                    specialist.description!.isNotEmpty)
                  Text(
                    specialist.description!,
                    style: const TextStyle(fontSize: 14),
                    maxLines: showFullInfo ? null : 2,
                    overflow: showFullInfo ? null : TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // Дополнительная информация
                Row(
                  children: [
                    if (specialist.location != null &&
                        specialist.location!.isNotEmpty) ...[
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          specialist.location!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (specialist.yearsOfExperience > 0) ...[
                      Icon(Icons.work, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${specialist.yearsOfExperience} лет',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),

                if (showFullInfo) ...[
                  const SizedBox(height: 12),

                  // Услуги
                  if (specialist.services.isNotEmpty) ...[
                    const Text(
                      'Услуги:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                service,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    if (specialist.services.length > 3)
                      Text(
                        '+${specialist.services.length - 3} еще',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],

                  const SizedBox(height: 12),

                  // Доступные даты
                  if (specialist.availableDates.isNotEmpty) ...[
                    const Text(
                      'Доступные даты:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialist.availableDates.take(3).join(', '),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 12),

                // Быстрые действия
                if (showQuickActions) ...[
                  Row(
                    children: [
                      Expanded(
                        child: SafeButton(
                          onPressed: () {
                            _openChat(context, specialist);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat, size: 16),
                              SizedBox(width: 8),
                              Text('Чат'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SafeButton(
                          onPressed: () {
                            _bookSpecialist(context, specialist);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BrandColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available, size: 16),
                              SizedBox(width: 8),
                              Text('Забронировать'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Кнопка "Подробнее"
                SizedBox(
                  width: double.infinity,
                  child: SafeButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Подробнее'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  String _getReviewCount() {
    // Генерируем случайное количество отзывов на основе рейтинга
    final baseCount = (specialist.rating * 20).round();
    return (baseCount + (DateTime.now().millisecond % 50)).toString();
  }

  /// Добавить специалиста в избранное
  void _addToFavorites(BuildContext context, Specialist specialist) {
    // TODO: Реализовать добавление в избранное через Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${specialist.name} добавлен в избранное'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () {
            // TODO: Удалить из избранного
          },
        ),
      ),
    );
  }

  /// Открыть чат с специалистом
  void _openChat(BuildContext context, Specialist specialist) {
    context.push('/chat/chat_${specialist.id}');
  }

  /// Забронировать специалиста
  void _bookSpecialist(BuildContext context, Specialist specialist) {
    context.push('/booking/${specialist.id}');
  }
}
