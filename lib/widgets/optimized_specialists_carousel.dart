import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/specialist.dart';
import '../providers/optimized_data_providers.dart';

/// Оптимизированный карусель специалистов с реальными данными
class OptimizedSpecialistsCarousel extends ConsumerWidget {
  final bool isCountryWide;
  final String? city;

  const OptimizedSpecialistsCarousel({
    super.key,
    required this.isCountryWide,
    this.city,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = {
      'city': isCountryWide ? null : city,
      'limit': 10,
    };

    final specialistsAsync = ref.watch(popularSpecialistsProvider(params));

    return specialistsAsync.when(
      data: (specialists) {
        if (specialists.isEmpty) {
          return _buildEmptyState(context);
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: specialists.length,
            itemBuilder: (context, index) {
              final specialist = specialists[index];
              return _buildSpecialistCard(context, specialist);
            },
          ),
        );
      },
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildSpecialistCard(BuildContext context, Specialist specialist) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _onSpecialistTap(context, specialist),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Аватар и статус
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          backgroundImage: specialist.avatarUrl != null
                              ? CachedNetworkImageProvider(specialist.avatarUrl!)
                              : null,
                          child: specialist.avatarUrl == null
                              ? Text(
                                  specialist.name.isNotEmpty ? specialist.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                )
                              : null,
                        ),
                        if (specialist.isVerified)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    if (specialist.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Доступен',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Имя
                Text(
                  specialist.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Категория
                Text(
                  specialist.categoryDisplayName ?? 'Специалист',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
                      color: Colors.amber[600],
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      specialist.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      specialist.priceRange,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Город
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        specialist.location ?? 'Не указано',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildLoadingState(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Специалисты не найдены',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить фильтры',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _onSpecialistTap(BuildContext context, Specialist specialist) {
    context.push('/specialist/${specialist.id}');
  }
}
