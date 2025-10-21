import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/smart_search_service.dart';

/// Виджет популярных специалистов недели
class PopularSpecialistsWidget extends ConsumerStatefulWidget {
  const PopularSpecialistsWidget({super.key});

  @override
  ConsumerState<PopularSpecialistsWidget> createState() => _PopularSpecialistsWidgetState();
}

class _PopularSpecialistsWidgetState extends ConsumerState<PopularSpecialistsWidget> {
  final SmartSearchService _searchService = SmartSearchService();
  List<Map<String, dynamic>> _specialists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPopularSpecialists();
  }

  Future<void> _loadPopularSpecialists() async {
    setState(() => _isLoading = true);
    try {
      final specialists = await _searchService.getPopularSpecialists();
      setState(() {
        _specialists = specialists;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки популярных специалистов: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Популярные специалисты недели',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: Переход к полному списку популярных специалистов
                  },
                  child: const Text('Все'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_specialists.isEmpty)
              _buildEmptyState()
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _specialists.length,
                  itemBuilder: (context, index) {
                    final specialist = _specialists[index];
                    return _buildSpecialistCard(specialist);
                  },
                ),
              ),
          ],
        ),
      );

  Widget _buildEmptyState() => Container(
        height: 200,
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Популярные специалисты появятся здесь', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );

  Widget _buildSpecialistCard(Map<String, dynamic> specialist) {
    final name = (specialist['name'] as String?) ?? 'Без имени';
    final category = (specialist['category'] as String?) ?? 'Специалист';
    final rating = (specialist['rating'] as num? ?? 0.0).toDouble();
    final price = (specialist['price'] ?? 0).toInt();
    final avatarUrl = specialist['avatarUrl'] as String?;
    final isVerified = (specialist['isVerified'] as bool?) ?? false;
    final isOnline = (specialist['isOnline'] as bool?) ?? false;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          // Аватар с бейджами
          Stack(
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: avatarUrl != null
                      ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                      : null,
                  color: avatarUrl == null ? Colors.grey[300] : null,
                ),
                child: avatarUrl == null
                    ? const Center(child: Icon(Icons.person, size: 40, color: Colors.grey))
                    : null,
              ),

              // Бейджи
              Positioned(top: 8, left: 8, child: _buildBadges(isVerified, isOnline)),

              // Рейтинг
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Информация
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'от $price₽',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (isOnline)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges(bool isVerified, bool isOnline) {
    final badges = <Widget>[];

    if (isVerified) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, color: Colors.white, size: 10),
              SizedBox(width: 2),
              Text(
                'ТОП',
                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (badges.isNotEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: badges);
    }

    return const SizedBox.shrink();
  }
}
