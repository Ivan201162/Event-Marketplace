import 'package:flutter/material.dart';

import '../models/specialist.dart';

/// Карточка специалиста
class SpecialistCard extends StatelessWidget {
  const SpecialistCard({
    super.key,
    required this.specialist,
    required this.onTap,
    this.showPrice = true,
    this.showRating = true,
    this.showLocation = true,
  });

  final Specialist specialist;
  final VoidCallback onTap;
  final bool showPrice;
  final bool showRating;
  final bool showLocation;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Аватар
              CircleAvatar(
                radius: 30,
                backgroundImage: specialist.profileImageUrl != null
                    ? NetworkImage(specialist.profileImageUrl!)
                    : null,
                child: specialist.profileImageUrl == null
                    ? Text(
                        specialist.name.isNotEmpty
                            ? specialist.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 20),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Имя и категория
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            specialist.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (specialist.isVerified)
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Категория
                    Text(
                      specialist.categoryDisplayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Рейтинг и отзывы
                    if (showRating)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            specialist.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
                    const SizedBox(height: 4),
                    // Локация
                    if (showLocation && specialist.location != null)
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.grey[600], size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              specialist.location!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    // Цена
                    if (showPrice)
                      Row(
                        children: [
                          Text(
                            '${specialist.price.toInt()} ₽',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            specialist.priceRange,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Статус доступности
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: specialist.isAvailable ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialist.isAvailable ? 'Доступен' : 'Занят',
                    style: TextStyle(
                      fontSize: 10,
                      color: specialist.isAvailable ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}