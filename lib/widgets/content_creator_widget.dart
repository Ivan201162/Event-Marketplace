import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_creator.dart';
import '../services/content_creator_service.dart';
import 'responsive_layout.dart';

/// Виджет для отображения карточки контент-мейкера
class ContentCreatorCard extends ConsumerWidget {
  const ContentCreatorCard({
    super.key,
    required this.creator,
    this.onTap,
  });
  final ContentCreator creator;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResponsiveCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с рейтингом
            Row(
              children: [
                Expanded(
                  child: ResponsiveText(
                    creator.name,
                    isTitle: true,
                  ),
                ),
                if (creator.rating != null) ...[
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    creator.rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  if (creator.reviewCount != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${creator.reviewCount})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Описание
            ResponsiveText(
              creator.description,
              isSubtitle: true,
            ),

            const SizedBox(height: 12),

            // Поддерживаемые форматы
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: creator.formats.take(3).map(_buildFormatChip).toList(),
            ),

            if (creator.formats.length > 3) ...[
              const SizedBox(height: 4),
              Text(
                '+${creator.formats.length - 3} еще',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Цена и портфолио
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (creator.priceRange != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      creator.priceRange!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
                Row(
                  children: [
                    const Icon(
                      Icons.photo_library,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${creator.portfolioSize} работ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildFormatChip(ContentFormat format) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          format.name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.blue,
          ),
        ),
      );
}

/// Виджет для отображения детальной информации о контент-мейкере
class ContentCreatorDetailWidget extends ConsumerWidget {
  const ContentCreatorDetailWidget({
    super.key,
    required this.creatorId,
  });
  final String creatorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Consumer(
        builder: (context, ref, child) => ref
            .watch(contentCreatorProvider(creatorId))
            .when(
              data: (creator) {
                if (creator == null) {
                  return const Center(child: Text('Контент-мейкер не найден'));
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок
                      ResponsiveCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ResponsiveText(
                                    creator.name,
                                    isTitle: true,
                                  ),
                                ),
                                if (creator.rating != null) ...[
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    creator.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  if (creator.reviewCount != null) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${creator.reviewCount} отзывов)',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            ResponsiveText(
                              creator.description,
                              isSubtitle: true,
                            ),
                            if (creator.location != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    creator.location!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Поддерживаемые форматы
                      ResponsiveCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ResponsiveText(
                              'Поддерживаемые форматы',
                              isTitle: true,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: creator.formats
                                  .map(_buildFormatCard)
                                  .toList(),
                            ),
                          ],
                        ),
                      ),

                      // Портфолио
                      ResponsiveCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ResponsiveText(
                                  'Портфолио',
                                  isTitle: true,
                                ),
                                const Spacer(),
                                Text(
                                  '${creator.portfolioSize} работ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (creator.mediaShowcase.isEmpty) ...[
                              const Center(
                                child: Text('Портфолио пусто'),
                              ),
                            ] else ...[
                              _buildPortfolioGrid(creator.mediaShowcase),
                            ],
                          ],
                        ),
                      ),

                      // Цены
                      if (creator.priceRange != null) ...[
                        ResponsiveCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ResponsiveText(
                                'Цены',
                                isTitle: true,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.attach_money,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    ResponsiveText(
                                      creator.priceRange!,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Ошибка: $error')),
            ),
      );

  Widget _buildFormatCard(ContentFormat format) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              format.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            ResponsiveText(
              format.description,
              isSubtitle: true,
            ),
            if (format.platforms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: format.platforms
                    .map(
                      (platform) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          platform,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      );

  Widget _buildPortfolioGrid(List<MediaShowcase> media) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: media.length,
        itemBuilder: (context, index) {
          final item = media[index];
          return _buildPortfolioItem(item);
        },
      );

  Widget _buildPortfolioItem(MediaShowcase item) => GestureDetector(
        onTap: () => _showMediaPreview(item),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Превью медиа
                if (item.type == MediaType.image) ...[
                  Image.network(
                    item.url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image)),
                  ),
                ] else if (item.type == MediaType.video) ...[
                  Stack(
                    children: [
                      if (item.coverUrl != null) ...[
                        Image.network(
                          item.coverUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image)),
                        ),
                      ] else ...[
                        Container(
                          color: Colors.grey.withValues(alpha: 0.3),
                          child: const Center(child: Icon(Icons.video_library)),
                        ),
                      ],
                      const Center(
                        child: Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    color: Colors.grey.withValues(alpha: 0.3),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.type.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.type.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Заголовок
                if (item.title != null) ...[
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
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
                      child: Text(
                        item.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );

  void _showMediaPreview(MediaShowcase item) {
    // TODO: Реализовать полноэкранный просмотр медиа
    print('Просмотр медиа: ${item.title}');
  }
}

/// Виджет для списка контент-мейкеров
class ContentCreatorListWidget extends ConsumerWidget {
  const ContentCreatorListWidget({
    super.key,
    this.location,
    this.categories,
    this.formats,
    this.onCreatorSelected,
  });
  final String? location;
  final List<String>? categories;
  final List<String>? formats;
  final Function(ContentCreator)? onCreatorSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Consumer(
        builder: (context, ref, child) => ref
            .watch(
              contentCreatorsProvider(
                location: location,
                categories: categories,
                formats: formats,
              ),
            )
            .when(
              data: (creators) {
                if (creators.isEmpty) {
                  return const Center(
                    child: Text('Контент-мейкеры не найдены'),
                  );
                }

                return ListView.builder(
                  itemCount: creators.length,
                  itemBuilder: (context, index) {
                    final creator = creators[index];
                    return ContentCreatorCard(
                      creator: creator,
                      onTap: () => onCreatorSelected?.call(creator),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Ошибка: $error')),
            ),
      );
}

/// Провайдер для контент-мейкера
final contentCreatorProvider =
    FutureProvider.family<ContentCreator?, String>((ref, creatorId) async {
  final service = ref.read(contentCreatorServiceProvider);
  return service.getContentCreator(creatorId);
});

/// Провайдер для списка контент-мейкеров
final contentCreatorsProvider =
    FutureProvider.family<List<ContentCreator>, Map<String, dynamic>>(
        (ref, params) async {
  final service = ref.read(contentCreatorServiceProvider);
  return service.getContentCreators(
    location: params['location'],
    categories: params['categories'],
    formats: params['formats'],
    limit: params['limit'] ?? 20,
  );
});

/// Провайдер для сервиса контент-мейкеров
final contentCreatorServiceProvider =
    Provider<ContentCreatorService>((ref) => ContentCreatorService());
