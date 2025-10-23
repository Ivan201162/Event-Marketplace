import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/idea.dart';
import '../utils/color_utils.dart';

/// Виджет идеи
class IdeaWidget extends StatelessWidget {
  const IdeaWidget({
    super.key,
    required this.idea,
    this.onTap,
    this.onLike,
    this.onSave,
    this.onShare,
  });
  final Idea idea;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображения
              if (idea.images.isNotEmpty) _buildImages(),

              // Основная информация
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок и категория
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            idea.title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: idea.categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: idea.categoryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                ColorUtils.getCategoryIcon(
                                    idea.category ?? 'другое'),
                                size: 14,
                                color: idea.categoryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                idea.category ?? 'Без категории',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: idea.categoryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Описание
                    Text(
                      idea.description ?? idea.shortDesc,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Теги
                    if (idea.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: idea.tags
                            .take(3)
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[600]),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Автор и дата
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: idea.authorPhotoUrl != null
                              ? CachedNetworkImageProvider(idea.authorPhotoUrl!)
                              : null,
                          child: idea.authorPhotoUrl == null
                              ? Text(
                                  (idea.authorName?.isNotEmpty == true)
                                      ? (idea.authorName![0]).toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 10),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            idea.authorName ?? 'Неизвестный автор',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          _formatDate(idea.createdAt),
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Действия
                    _buildActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildImages() {
    final List<String> images = idea.images;
    if (images.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (BuildContext context, int index) {
          final String image = images[index];
          return CachedNetworkImage(
            imageUrl: image,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
                color: Colors.grey[200], child: const Icon(Icons.error)),
          );
        },
      ),
    );
  }

  Widget _buildActions() => Row(
        children: [
          // Лайк
          GestureDetector(
            onTap: onLike,
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 20,
                  color: idea.likesCount > 0 ? Colors.red : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  idea.likesCount.toString(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Просмотры
          Row(
            children: [
              Icon(Icons.visibility, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                idea.viewsCount.toString(),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Сохранения
          GestureDetector(
            onTap: onSave,
            child: Row(
              children: [
                Icon(
                  Icons.bookmark,
                  size: 20,
                  color: idea.savesCount > 0 ? Colors.blue : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  (idea.savesCount).toString(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Комментарии
          Row(
            children: [
              Icon(Icons.comment, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                (idea.commentsCount).toString(),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // Шаринг
          GestureDetector(
            onTap: onShare,
            child: Icon(Icons.share, size: 20, color: Colors.grey[600]),
          ),
        ],
      );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

/// Виджет для отображения идеи в списке
class IdeaListTile extends StatelessWidget {
  const IdeaListTile({
    super.key,
    required this.idea,
    this.onTap,
    this.onLike,
    this.onSave,
    this.onShare,
  });
  final Idea idea;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: (idea.images).isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: (idea.images).first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: idea.categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  ColorUtils.getCategoryIcon(idea.category ?? 'другое'),
                  color: idea.categoryColor,
                  size: 24,
                ),
              ),
        title: Text(
          idea.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(idea.description ?? idea.shortDesc,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: idea.categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    idea.category ?? 'Без категории',
                    style: TextStyle(
                      fontSize: 10,
                      color: idea.categoryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(idea.createdAt),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Icon(
                    Icons.favorite,
                    size: 16,
                    color: idea.likesCount > 0 ? Colors.red : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                Text((idea.likesCount).toString(),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onSave,
                  child: Icon(
                    Icons.bookmark,
                    size: 16,
                    color: idea.savesCount > 0 ? Colors.blue : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                Text((idea.savesCount).toString(),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        onTap: onTap,
      );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

/// Виджет для отображения идеи в сетке
class IdeaGridTile extends StatelessWidget {
  const IdeaGridTile({
    super.key,
    required this.idea,
    this.onTap,
    this.onLike,
    this.onSave,
    this.onShare,
  });
  final Idea idea;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображение
              Expanded(
                flex: 3,
                child: (idea.images).isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: (idea.images).first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.error)),
                      )
                    : Container(
                        color: idea.categoryColor.withValues(alpha: 0.1),
                        child: Center(
                          child: Icon(
                            ColorUtils.getCategoryIcon(
                                idea.category ?? 'другое'),
                            size: 32,
                            color: idea.categoryColor,
                          ),
                        ),
                      ),
              ),

              // Информация
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок
                      Text(
                        idea.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Категория
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: idea.categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          idea.category ?? 'Без категории',
                          style: TextStyle(
                            fontSize: 10,
                            color: idea.categoryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Действия
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onLike,
                            child: Icon(
                              Icons.favorite,
                              size: 16,
                              color: idea.likesCount > 0
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text((idea.likesCount).toString(),
                              style: const TextStyle(fontSize: 12)),
                          const Spacer(),
                          GestureDetector(
                            onTap: onSave,
                            child: Icon(
                              Icons.bookmark,
                              size: 16,
                              color: idea.savesCount > 0
                                  ? Colors.blue
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text((idea.savesCount).toString(),
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
