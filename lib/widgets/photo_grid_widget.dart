import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/customer_profile_extended.dart';

/// Виджет сетки фотографий
class PhotoGridWidget extends StatelessWidget {
  const PhotoGridWidget({
    super.key,
    required this.photos,
    required this.onPhotoTap,
    required this.onPhotoEdit,
    required this.onPhotoDelete,
  });
  final List<InspirationPhoto> photos;
  final void Function(InspirationPhoto) onPhotoTap;
  final void Function(InspirationPhoto) onPhotoEdit;
  final void Function(InspirationPhoto) onPhotoDelete;

  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return _buildPhotoCard(context, photo);
        },
      );

  Widget _buildPhotoCard(BuildContext context, InspirationPhoto photo) => Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Фото
            Positioned.fill(
              child: GestureDetector(
                onTap: () => onPhotoTap(photo),
                child: CachedNetworkImage(
                  imageUrl: photo.url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ),
            ),

            // Индикатор публичности
            if (photo.isPublic)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.public,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),

            // Теги (если есть)
            if (photo.tags.isNotEmpty)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    photo.tags.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            // Меню действий
            Positioned(
              top: 8,
              left: 8,
              child: PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onPhotoEdit(photo);
                      break;
                    case 'delete':
                      onPhotoDelete(photo);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Редактировать'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Удалить', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
