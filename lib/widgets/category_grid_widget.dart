import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/local_data_providers.dart';

class CategoryGridWidget extends ConsumerWidget {
  const CategoryGridWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(localCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(context, category);
          },
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        context.push('/search?category=${Uri.encodeComponent(category['name']!)}');
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(category['name']!),
              size: 36,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              category['name']!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Ведущие':
        return Icons.mic;
      case 'DJ':
        return Icons.headset;
      case 'Фотографы':
        return Icons.camera_alt;
      case 'Видеографы':
        return Icons.videocam;
      case 'Декораторы':
        return Icons.palette;
      case 'Аниматоры':
        return Icons.sentiment_very_satisfied;
      case 'Организатор мероприятий':
        return Icons.event;
      case 'Музыканты':
        return Icons.music_note;
      case 'Танцоры':
        return Icons.dance;
      case 'Кейтеринг':
        return Icons.restaurant;
      default:
        return Icons.category;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Нет доступных категорий', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      height: 200,
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              'Ошибка загрузки категорий',
              style: TextStyle(color: Colors.red[700], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
