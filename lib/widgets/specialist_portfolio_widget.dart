import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/specialist.dart';
import '../models/common_types.dart';

/// Виджет портфолио специалиста
class SpecialistPortfolioWidget extends StatelessWidget {
  const SpecialistPortfolioWidget({
    super.key,
    required this.specialist,
  });
  final Specialist specialist;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Text(
                  'Портфолио',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (specialist.portfolio.isNotEmpty)
                  TextButton(
                    onPressed: () => _showAllPortfolio(context),
                    child: const Text('Все работы'),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Портфолио
            if (specialist.portfolio.isEmpty) _buildEmptyPortfolio() else _buildPortfolioGrid(),
          ],
        ),
      );

  /// Построить пустое портфолио
  Widget _buildEmptyPortfolio() => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Портфолио пока пусто',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Специалист еще не добавил свои работы',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  /// Построить сетку портфолио
  Widget _buildPortfolioGrid() => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: specialist.portfolio.length > 6 ? 6 : specialist.portfolio.length,
        itemBuilder: (context, index) {
          final portfolioItem = specialist.portfolio[index];
          return _buildPortfolioItem(portfolioItem, index);
        },
      );

  /// Построить элемент портфолио
  Widget _buildPortfolioItem(String portfolioUrl, int index) => GestureDetector(
        onTap: () => _showPortfolioItem(portfolioUrl, index),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Изображение
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    image: DecorationImage(
                      image: NetworkImage(portfolioUrl),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        // Обработка ошибки загрузки изображения
                      },
                    ),
                  ),
                  child: portfolioUrl.isEmpty
                      ? Icon(Icons.image, size: 48, color: Colors.grey[400])
                      : null,
                ),

                // Оверлей
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),

                // Информация
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Работа ${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        specialist.category?.displayName ?? 'Категория',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                // Иконка увеличения
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  /// Показать элемент портфолио
  void _showPortfolioItem(String portfolioUrl, int index) {
    // TODO(developer): Реализовать полноэкранный просмотр портфолио
  }

  /// Показать все портфолио
  void _showAllPortfolio(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Заголовок
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Портфолио ${specialist.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Сетка портфолио
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: specialist.portfolio.length,
                  itemBuilder: (context, index) {
                    final portfolioItem = specialist.portfolio[index];
                    return _buildPortfolioItem(portfolioItem, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет для отображения отдельного элемента портфолио
class PortfolioItemWidget extends StatelessWidget {
  const PortfolioItemWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    this.description,
    this.onTap,
  });
  final String imageUrl;
  final String title;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Изображение
                Expanded(
                  child: imageUrl.isEmpty
                      ? Container(
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.error),
                          ),
                        ),
                ),

                // Информация
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
