import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/local_data_providers.dart';

/// Виджет "Популярные специалисты недели"
class WeeklyPopularSpecialistsWidget extends ConsumerWidget {
  const WeeklyPopularSpecialistsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularSpecialistsAsync = ref.watch(localSpecialistsProvider);

    return popularSpecialistsAsync.when(
      data: (specialists) {
        if (specialists.isEmpty) {
          return _buildEmptyState();
        }

        // Берем топ-10 специалистов
        final topSpecialists = specialists.take(10).toList();

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: topSpecialists.length,
            itemBuilder: (context, index) {
              final specialist = topSpecialists[index];
              return _buildSpecialistCard(context, specialist, index + 1);
            },
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildSpecialistCard(
      BuildContext context, Map<String, dynamic> specialist, int rank) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => context.push('/specialist/${specialist['id']}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ранг и аватар
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                          color: _getRankColor(rank), shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: specialist['photoUrl'] != null
                          ? NetworkImage(specialist['photoUrl'])
                          : null,
                      child: specialist['photoUrl'] == null
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Имя
                Text(
                  specialist['name'] ?? 'Специалист',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Категория
                Text(
                  specialist['category'] ?? 'Категория',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Город
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        specialist['city'] ?? 'Город',
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Рейтинг
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      '${specialist['rating'] ?? 0.0}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.orange[300]!;
      default:
        return Colors.blue;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Нет данных о специалистах',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
          color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Ошибка загрузки',
                style: TextStyle(color: Colors.red[700], fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
