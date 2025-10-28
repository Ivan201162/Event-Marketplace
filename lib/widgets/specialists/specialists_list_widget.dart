import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_marketplace_app/services/test_data_service.dart';
import 'package:flutter/material.dart';

/// Виджет списка специалистов
class SpecialistsListWidget extends StatefulWidget {
  const SpecialistsListWidget({
    required this.searchQuery, required this.category, required this.city, required this.sortBy, required this.minPrice, required this.maxPrice, required this.onSpecialistTap, super.key,
  });

  final String searchQuery;
  final String category;
  final String city;
  final String sortBy;
  final double minPrice;
  final double maxPrice;
  final ValueChanged<String> onSpecialistTap;

  @override
  State<SpecialistsListWidget> createState() => _SpecialistsListWidgetState();
}

class _SpecialistsListWidgetState extends State<SpecialistsListWidget> {
  final TestDataService _testDataService = TestDataService();
  List<Map<String, dynamic>> _specialists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpecialists();
  }

  @override
  void didUpdateWidget(SpecialistsListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.category != widget.category ||
        oldWidget.city != widget.city ||
        oldWidget.sortBy != widget.sortBy ||
        oldWidget.minPrice != widget.minPrice ||
        oldWidget.maxPrice != widget.maxPrice) {
      _loadSpecialists();
    }
  }

  Future<void> _loadSpecialists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final specialists = _testDataService.getSpecialists();

      // Фильтрация
      final filteredSpecialists = specialists.where((specialist) {
        // Поиск по имени
        if (widget.searchQuery.isNotEmpty) {
          final name = specialist['name'] as String? ?? '';
          if (!name.toLowerCase().contains(widget.searchQuery.toLowerCase())) {
            return false;
          }
        }

        // Фильтр по категории
        if (widget.category != 'Все') {
          final specialties = specialist['specialties'] as List<dynamic>? ?? [];
          if (!specialties.any((s) => s.toString().contains(widget.category))) {
            return false;
          }
        }

        // Фильтр по городу
        if (widget.city != 'Все города') {
          final city = specialist['city'] as String? ?? '';
          if (city != widget.city) {
            return false;
          }
        }

        // Фильтр по цене
        final price = (specialist['price'] as num?)?.toDouble() ?? 0;
        if (price < widget.minPrice || price > widget.maxPrice) {
          return false;
        }

        return true;
      }).toList();

      // Сортировка
      final sortedSpecialists = filteredSpecialists.toList();
      switch (widget.sortBy) {
        case 'Рейтинг':
          sortedSpecialists.sort((a, b) {
            final ratingA = (a['rating'] as num?)?.toDouble() ?? 0;
            final ratingB = (b['rating'] as num?)?.toDouble() ?? 0;
            return ratingB.compareTo(ratingA);
          });
        case 'Цена (по возрастанию)':
          sortedSpecialists.sort((a, b) {
            final priceA = (a['price'] as num?)?.toDouble() ?? 0;
            final priceB = (b['price'] as num?)?.toDouble() ?? 0;
            return priceA.compareTo(priceB);
          });
        case 'Цена (по убыванию)':
          sortedSpecialists.sort((a, b) {
            final priceA = (a['price'] as num?)?.toDouble() ?? 0;
            final priceB = (b['price'] as num?)?.toDouble() ?? 0;
            return priceB.compareTo(priceA);
          });
        case 'Популярность':
          sortedSpecialists.sort((a, b) {
            final reviewsA = (a['reviewsCount'] as num?)?.toInt() ?? 0;
            final reviewsB = (b['reviewsCount'] as num?)?.toInt() ?? 0;
            return reviewsB.compareTo(reviewsA);
          });
        case 'Дата регистрации':
          sortedSpecialists.sort((a, b) {
            final dateA = a['createdAt'] as DateTime? ?? DateTime.now();
            final dateB = b['createdAt'] as DateTime? ?? DateTime.now();
            return dateB.compareTo(dateA);
          });
      }

      setState(() {
        _specialists = sortedSpecialists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_specialists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text('Специалисты не найдены', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить параметры поиска',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSpecialists,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _specialists.length,
        itemBuilder: (context, index) {
          final specialist = _specialists[index];
          return _buildSpecialistCard(context, specialist);
        },
      ),
    );
  }

  Widget _buildSpecialistCard(
      BuildContext context, Map<String, dynamic> specialist,) {
    final theme = Theme.of(context);
    final name = specialist['name'] as String? ?? 'Неизвестно';
    final city = specialist['city'] as String? ?? '';
    final rating = (specialist['rating'] as num?)?.toDouble() ?? 0;
    final price = (specialist['price'] as num?)?.toDouble() ?? 0;
    final reviewsCount = (specialist['reviewsCount'] as num?)?.toInt() ?? 0;
    final avatarUrl = specialist['avatarUrl'] as String?;
    final specialties = specialist['specialties'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => widget.onSpecialistTap(specialist['id'] as String? ?? ''),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Аватар
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                child: avatarUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: avatarUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 60,
                            height: 60,
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            child: Icon(Icons.person,
                                size: 30, color: theme.primaryColor,),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            child: Icon(Icons.person,
                                size: 30, color: theme.primaryColor,),
                          ),
                        ),
                      )
                    : Icon(Icons.person, size: 30, color: theme.primaryColor),
              ),

              const SizedBox(width: 16),

              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Имя
                    Text(
                      name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 4),

                    // Город
                    if (city.isNotEmpty)
                      Text(
                        city,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Специализации
                    if (specialties.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: specialties
                            .take(2)
                            .map(
                              (specialty) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2,),
                                decoration: BoxDecoration(
                                  color:
                                      theme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  specialty.toString(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.primaryColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),

                    const SizedBox(height: 8),

                    // Рейтинг и цена
                    Row(
                      children: [
                        // Рейтинг
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($reviewsCount)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),

                        const Spacer(),

                        // Цена
                        Text(
                          'от ${price.toInt()} ₽',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Стрелка
              Icon(
                Icons.chevron_right,
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
