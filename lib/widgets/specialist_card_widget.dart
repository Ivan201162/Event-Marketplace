import 'package:flutter/material.dart';

import '../models/common_types.dart';
import '../models/specialist.dart';

/// Виджет карточки специалиста
class SpecialistCardWidget extends StatelessWidget {
  const SpecialistCardWidget({
    super.key,
    required this.specialist,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
    this.onBook,
  });
  final Specialist specialist;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с аватаром и информацией
                Row(
                  children: [
                    // Аватар
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: specialist.imageUrlValue != null
                          ? NetworkImage(specialist.imageUrlValue!)
                          : null,
                      child: specialist.imageUrlValue == null
                          ? Text(
                              specialist.name.isNotEmpty ? specialist.name[0].toUpperCase() : 'С',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),

                    const SizedBox(width: 12),

                    // Информация о специалисте
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            specialist.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            specialist.category?.displayName ?? 'Категория',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                (specialist.avgRating ?? 0) > 0
                                    ? (specialist.avgRating ?? 0).toStringAsFixed(1)
                                    : specialist.rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${specialist.reviewCount} отзывов)',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Кнопка избранного
                    IconButton(
                      onPressed: onFavoriteToggle,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Описание
                if (specialist.description != null && specialist.description!.isNotEmpty)
                  Text(
                    specialist.description!,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // Дополнительная информация
                Row(
                  children: [
                    // Местоположение
                    if (specialist.location != null && specialist.location!.isNotEmpty) ...[
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          specialist.location!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],

                    // Опыт
                    if ((specialist.yearsOfExperience ?? 0) > 0) ...[
                      Icon(Icons.work, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${specialist.yearsOfExperience ?? 0} лет',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Цена и действия
                Row(
                  children: [
                    // Цена
                    Text(
                      '${specialist.price?.toInt() ?? 0}₽/час',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const Spacer(),

                    // Кнопка бронирования
                    ElevatedButton(
                      onPressed: onBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Забронировать'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
