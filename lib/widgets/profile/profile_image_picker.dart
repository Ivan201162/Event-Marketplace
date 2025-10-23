import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Виджет для выбора изображения профиля
class ProfileImagePicker extends StatelessWidget {
  const ProfileImagePicker({
    super.key,
    this.imageUrl,
    required this.onImagePicked,
    this.size = 80,
    this.isCover = false,
  });

  final String? imageUrl;
  final VoidCallback onImagePicked;
  final double size;
  final bool isCover;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onImagePicked,
      child: Container(
        width: size,
        height: isCover ? size * 0.6 : size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isCover ? 8 : size / 2),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
          ),
          color: Colors.grey[100],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCover ? 8 : size / 2),
          child: imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCover ? Icons.image : Icons.person,
            size: size * 0.4,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            isCover ? 'Обложка' : 'Фото',
            style: TextStyle(
              fontSize: size * 0.15,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
