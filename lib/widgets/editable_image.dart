import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Виджет для редактируемого изображения
class EditableImage extends StatelessWidget {
  const EditableImage({
    super.key,
    this.imageUrl,
    required this.onImageChanged,
    required this.placeholder,
  });

  final String? imageUrl;
  final Function(String) onImageChanged;
  final IconData placeholder;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _showImagePicker,
        child: Stack(
          children: [
            // Основное изображение
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) =>
                          Container(color: Colors.grey[300], child: Icon(placeholder, size: 50)),
                    )
                  : Icon(placeholder, size: 50),
            ),
            // Иконка редактирования
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      );

  void _showImagePicker() {
    // TODO: Реализовать выбор изображения
    // Пока что просто вызываем callback с тестовым URL
    onImageChanged('https://placehold.co/200x200/4CAF50/white?text=New');
  }
}
