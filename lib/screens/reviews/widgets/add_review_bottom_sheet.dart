import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/reviews_service.dart';

class AddReviewBottomSheet extends StatefulWidget {
  const AddReviewBottomSheet({
    super.key,
    required this.specialistId,
    required this.specialistName,
    required this.onReviewAdded,
  });
  final String specialistId;
  final String specialistName;
  final VoidCallback onReviewAdded;

  @override
  State<AddReviewBottomSheet> createState() => _AddReviewBottomSheetState();
}

class _AddReviewBottomSheetState extends State<AddReviewBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _reviewsService = ReviewsService();
  final _imagePicker = ImagePicker();

  double _rating = 5;
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Оставить отзыв',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Информация о специалисте
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Отзыв для: ${widget.specialistName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Рейтинг
              _buildRatingSection(),
              const SizedBox(height: 16),

              // Текст отзыва
              _buildTextSection(),
              const SizedBox(height: 16),

              // Фото
              _buildPhotosSection(),
              const SizedBox(height: 16),

              // Кнопка отправки
              _buildSubmitButton(),
            ],
          ),
        ),
      );

  Widget _buildRatingSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Оценка *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _rating,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _rating.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _rating = value;
                    });
                  },
                ),
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Звезды для визуализации
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < _rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 24,
              ),
            ),
          ),
        ],
      );

  Widget _buildTextSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Текст отзыва *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _textController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Расскажите о вашем опыте работы со специалистом...',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите текст отзыва';
              }
              if (value.trim().length < 20) {
                return 'Отзыв должен содержать минимум 20 символов';
              }
              return null;
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Минимум 20 символов (${_textController.text.length})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _textController.text.length < 20
                      ? Colors.red
                      : Colors.grey,
                ),
          ),
        ],
      );

  Widget _buildPhotosSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Фото (необязательно)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // Выбранные фото
          if (_selectedImages.isNotEmpty) ...[
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Кнопка добавления фото
          if (_selectedImages.length < 3)
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text('Добавить фото (${_selectedImages.length}/3)'),
            ),
        ],
      );

  Widget _buildSubmitButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitReview,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Отправить отзыв'),
        ),
      );

  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          final remainingSlots = 3 - _selectedImages.length;
          final imagesToAdd = images
              .take(remainingSlots)
              .map((xFile) => File(xFile.path))
              .toList();
          _selectedImages.addAll(imagesToAdd);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выборе фото: $e')),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Загружаем фото в Firebase Storage (упрощенная версия)
      final photoUrls = <String>[];
      for (final imageFile in _selectedImages) {
        // Здесь должна быть загрузка в Firebase Storage
        // Для демонстрации используем заглушку
        photoUrls.add(
          'https://picsum.photos/400?random=${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      await _reviewsService.addReview(
        specialistId: widget.specialistId,
        customerId: currentUser.uid,
        customerName: currentUser.displayName ?? 'Пользователь',
        rating: _rating,
        text: _textController.text.trim(),
        photos: photoUrls,
        customerAvatar: currentUser.photoURL,
        specialistName: widget.specialistName,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onReviewAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отзыв успешно добавлен!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении отзыва: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
