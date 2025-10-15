import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// import '../models/specialist.dart'; // Unused import removed
import '../providers/local_data_providers.dart';
import 'specialist_badges_widget.dart';

/// Виджет "Популярные специалисты недели"
class WeeklyPopularSpecialistsWidget extends ConsumerWidget {
  const WeeklyPopularSpecialistsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularSpecialistsAsync = ref.watch(localSpecialistsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '⭐ Популярные специалисты недели',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/search?sort=popularity'),
                child: const Text('Все'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: popularSpecialistsAsync.when(
            data: (specialists) {
              if (specialists.isEmpty) {
                return const Center(
                  child: Text('Популярные специалисты не найдены'),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: specialists.length,
                itemBuilder: (context, index) {
                  final specialist = specialists[index];
                  return _buildSpecialistCard(context, specialist);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Text('Ошибка загрузки: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialistCard(
    BuildContext context,
    Map<String, dynamic> specialist,
  ) {
    final name = specialist['name'] as String? ?? 'Без имени';
    final category = specialist['category'] as String? ?? 'Не указано';
    final rating = (specialist['rating'] as num?)?.toDouble() ?? 0.0;
    final price = (specialist['price'] as num?)?.toInt() ?? 0;
    final avatarUrl = specialist['avatarUrl'] as String?;
    final city = specialist['city'] as String? ?? 'Город не указан';
    final reviewsCount = (specialist['reviewsCount'] as int?) ?? 0;
    final isOnline = specialist['isOnline'] as bool? ?? false;

    final badges = SpecialistBadge.fromSpecialistData(specialist);

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Аватар с онлайн статусом
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  height: 80,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: avatarUrl != null
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildAvatarPlaceholder(name),
                        )
                      : _buildAvatarPlaceholder(name),
                ),
              ),
              if (isOnline)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          // Информация о специалисте
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    city,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),

                  // Рейтинг и цена
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviewsCount)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'от $price ₽',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Бейджи
          if (badges.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: SpecialistBadgesWidget(
                badges: badges,
                size: 12,
                showText: false,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .map((word) => word.isNotEmpty ? word[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    return Container(
      color: Colors.blue[100],
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.blue[800],
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}

// Провайдер уже определен в local_data_providers.dart
