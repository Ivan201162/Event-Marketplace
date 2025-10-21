import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Виджет для отображения избранных специалистов
class FavoriteSpecialists extends ConsumerWidget {
  const FavoriteSpecialists({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO(developer): Подключить провайдер для избранных специалистов
    return _buildSpecialistsList(context);
  }

  Widget _buildSpecialistsList(BuildContext context) {
    // Заглушка для демонстрации
    final specialists = _getMockSpecialists();

    if (specialists.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO(developer): Обновить список избранных
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: specialists.length,
        itemBuilder: (context, index) {
          final specialist = specialists[index];
          return _buildSpecialistItem(context, specialist);
        },
      ),
    );
  }

  Widget _buildSpecialistItem(BuildContext context, Map<String, dynamic> specialist) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        // Аватар специалиста
        Stack(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage: specialist['avatarUrl'] != null
                  ? CachedNetworkImageProvider(specialist['avatarUrl'])
                  : null,
              child: specialist['avatarUrl'] == null ? const Icon(Icons.person, size: 30) : null,
            ),
            if (specialist['isVerified'])
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.verified, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Информация о специалисте
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      specialist['name'],
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => _removeFromFavorites(context, specialist['id']),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                specialist['specialization'],
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    specialist['rating'].toString(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${specialist['reviewsCount']} отзывов)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      specialist['city'],
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: specialist['isAvailable']
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      specialist['isAvailable'] ? 'Доступен' : 'Занят',
                      style: TextStyle(
                        color: specialist['isAvailable'] ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'от ${specialist['minPrice']} ₽',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
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

  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'Нет избранных специалистов',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          'Добавьте специалистов в избранное,\nчтобы быстро найти их позже',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _findSpecialists(context),
          icon: const Icon(Icons.search),
          label: const Text('Найти специалистов'),
        ),
      ],
    ),
  );

  void _removeFromFavorites(BuildContext context, String specialistId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить из избранного'),
        content: const Text('Вы уверены, что хотите удалить этого специалиста из избранного?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO(developer): Удалить из избранного
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Удалено из избранного')));
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _findSpecialists(BuildContext context) {
    // TODO(developer): Навигация к поиску специалистов
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Поиск специалистов')));
  }

  List<Map<String, dynamic>> _getMockSpecialists() => [
    {
      'id': '1',
      'name': 'Анна Петрова',
      'specialization': 'Ведущая мероприятий',
      'avatarUrl': null,
      'rating': 4.8,
      'reviewsCount': 127,
      'city': 'Москва',
      'isAvailable': true,
      'isVerified': true,
      'minPrice': 25000,
    },
    {
      'id': '2',
      'name': 'Михаил Иванов',
      'specialization': 'Фотограф',
      'avatarUrl': null,
      'rating': 4.9,
      'reviewsCount': 89,
      'city': 'Санкт-Петербург',
      'isAvailable': false,
      'isVerified': true,
      'minPrice': 15000,
    },
    {
      'id': '3',
      'name': 'Елена Сидорова',
      'specialization': 'Музыкант',
      'avatarUrl': null,
      'rating': 4.7,
      'reviewsCount': 56,
      'city': 'Москва',
      'isAvailable': true,
      'isVerified': false,
      'minPrice': 12000,
    },
  ];
}
