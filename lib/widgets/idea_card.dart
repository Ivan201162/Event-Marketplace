import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/idea.dart';

class IdeaCard extends StatelessWidget {
  const IdeaCard({
    super.key,
    required this.idea,
    this.onTap,
    this.onLike,
    this.onSave,
    this.showAuthor = true,
    this.isLiked = false,
    this.isSaved = false,
  });
  final Idea idea;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final bool showAuthor;
  final bool isLiked;
  final bool isSaved;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображение
              Expanded(
                flex: 3,
                child: _buildImage(context),
              ),

              // Контент
              Expanded(
                flex: 2,
                child: _buildContent(context),
              ),
            ],
          ),
        ),
      );

  Widget _buildImage(BuildContext context) => Stack(
        children: [
          // Основное изображение
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: idea.mainImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: idea.mainImageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.error),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                  ),
          ),

          // Индикатор типа контента
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    idea.category.emoji,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    idea.category.displayName,
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

          // Индикатор видео
          if (idea.hasVideo)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),

          // Кнопки действий
          Positioned(
            bottom: 8,
            right: 8,
            child: Column(
              children: [
                // Кнопка сохранения
                if (onSave != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? Colors.amber : Colors.white,
                        size: 20,
                      ),
                      onPressed: onSave,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),

                // Кнопка лайка
                if (onLike != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                        size: 20,
                      ),
                      onPressed: onLike,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ),

          // Счетчик медиафайлов
          if (idea.mediaCount > 1)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${idea.mediaCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _buildContent(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              idea.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Описание
            Expanded(
              child: Text(
                idea.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 8),

            // Теги
            if (idea.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: idea.tags
                    .take(2)
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

            const SizedBox(height: 8),

            // Статистика и автор
            Row(
              children: [
                // Статистика
                Expanded(
                  child: Row(
                    children: [
                      if (idea.likesCount > 0) ...[
                        Icon(
                          Icons.favorite,
                          size: 12,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${idea.likesCount}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (idea.savesCount > 0) ...[
                        Icon(
                          Icons.bookmark,
                          size: 12,
                          color: Colors.amber.shade600,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${idea.savesCount}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),

                // Автор
                if (showAuthor)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage: idea.authorAvatar != null
                            ? NetworkImage(idea.authorAvatar!)
                            : null,
                        child: idea.authorAvatar == null
                            ? Text(
                                idea.authorName.isNotEmpty
                                    ? idea.authorName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        idea.authorName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );
}

/// Компактная карточка идеи для списков
class CompactIdeaCard extends StatelessWidget {
  const CompactIdeaCard({
    super.key,
    required this.idea,
    this.onTap,
    this.onLike,
    this.onSave,
    this.isLiked = false,
    this.isSaved = false,
  });
  final Idea idea;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final bool isLiked;
  final bool isSaved;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Изображение
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: idea.mainImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: idea.mainImageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.error),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image),
                        ),
                ),

                const SizedBox(width: 12),

                // Контент
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idea.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        idea.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            idea.category.emoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            idea.category.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          if (idea.likesCount > 0) ...[
                            Icon(
                              Icons.favorite,
                              size: 12,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${idea.likesCount}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Кнопки действий
                Column(
                  children: [
                    if (onSave != null)
                      IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? Colors.amber : null,
                          size: 20,
                        ),
                        onPressed: onSave,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    if (onLike != null)
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : null,
                          size: 20,
                        ),
                        onPressed: onLike,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
