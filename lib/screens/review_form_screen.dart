import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/feature_flags.dart';
import '../core/safe_log.dart';
import '../models/review.dart';
import '../providers/auth_providers.dart';
import '../services/review_service.dart';
import '../services/upload_service.dart';

/// Экран создания/редактирования отзыва
class ReviewFormScreen extends ConsumerStatefulWidget {
  // Для редактирования

  const ReviewFormScreen({
    super.key,
    required this.targetId,
    required this.type,
    required this.targetName,
    this.existingReview,
  });
  final String targetId;
  final ReviewType type;
  final String targetName;
  final Review? existingReview;

  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();

  final ReviewService _reviewService = ReviewService();
  final UploadService _uploadService = UploadService();

  int _rating = 5;
  List<String> _images = [];
  List<String> _tags = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.existingReview != null) {
      final review = widget.existingReview!;
      _titleController.text = review.title;
      _contentController.text = review.content;
      _rating = review.rating;
      _images = List.from(review.images);
      _tags = List.from(review.tags);
      _tagsController.text = _tags.join(', ');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingReview != null ? 'Редактировать отзыв' : 'Новый отзыв',
        ),
        actions: [
          if (widget.existingReview != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: _buildForm(currentUser),
    );
  }

  Widget _buildForm(currentUser) => Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Информация о цели отзыва
              _buildTargetInfo(),
              const SizedBox(height: 24),

              // Рейтинг
              _buildRatingSection(),
              const SizedBox(height: 24),

              // Заголовок
              _buildTitleField(),
              const SizedBox(height: 16),

              // Содержимое
              _buildContentField(),
              const SizedBox(height: 16),

              // Теги
              _buildTagsField(),
              const SizedBox(height: 16),

              // Изображения
              if (FeatureFlags.fileUploadEnabled) _buildImagesSection(),

              const SizedBox(height: 32),

              // Кнопки
              _buildActionButtons(),
            ],
          ),
        ),
      );

  Widget _buildTargetInfo() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _getTargetIcon(),
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Отзыв о ${widget.type.name.toLowerCase()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.targetName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildRatingSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Оценка *',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              5,
              (index) => GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getRatingText(_rating),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        ],
      );

  Widget _buildTitleField() => TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Заголовок отзыва *',
          hintText: 'Краткое описание вашего опыта',
          border: OutlineInputBorder(),
        ),
        maxLength: 100,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Введите заголовок отзыва';
          }
          if (value.trim().length < 5) {
            return 'Заголовок должен содержать минимум 5 символов';
          }
          return null;
        },
      );

  Widget _buildContentField() => TextFormField(
        controller: _contentController,
        decoration: const InputDecoration(
          labelText: 'Содержимое отзыва *',
          hintText: 'Подробно опишите ваш опыт...',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        maxLines: 6,
        maxLength: 1000,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Введите содержимое отзыва';
          }
          if (value.trim().length < 20) {
            return 'Отзыв должен содержать минимум 20 символов';
          }
          return null;
        },
      );

  Widget _buildTagsField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Теги',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Теги (через запятую)',
              hintText: 'качество, сервис, атмосфера',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _tags = value
                  .split(',')
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toList();
            },
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      onDeleted: () {
                        setState(() {
                          _tags.remove(tag);
                          _tagsController.text = _tags.join(', ');
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      );

  Widget _buildImagesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Изображения',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте фотографии (максимум 5)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 12),

          // Сетка изображений
          if (_images.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _images.length + (images.length < 5 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _images.length) {
                  return _buildAddImageButton();
                }
                return _buildImagePreview(_images[index], index);
              },
            )
          else
            _buildAddImageButton(),
        ],
      );

  Widget _buildAddImageButton() => GestureDetector(
        onTap: _addImage,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                'Добавить',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildImagePreview(String imageUrl, int index) => Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
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
      );

  Widget _buildActionButtons() => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.existingReview != null
                          ? 'Обновить'
                          : 'Опубликовать',
                    ),
            ),
          ),
        ],
      );

  IconData _getTargetIcon() {
    switch (widget.type) {
      case ReviewType.event:
        return Icons.event;
      case ReviewType.specialist:
        return Icons.person;
      case ReviewType.service:
        return Icons.business;
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Ужасно';
      case 2:
        return 'Плохо';
      case 3:
        return 'Нормально';
      case 4:
        return 'Хорошо';
      case 5:
        return 'Отлично';
      default:
        return '';
    }
  }

  Future<void> _addImage() async {
    if (!FeatureFlags.fileUploadEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Загрузка изображений отключена')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final result = await _uploadService.pickAndUploadImage();
      if (result != null) {
        setState(() {
          _images.add(result.url);
        });
      }
    } catch (e, stackTrace) {
      SafeLog.error('ReviewFormScreen: Error adding image', e, stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки изображения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserAsync = ref.read(currentUserProvider);
    final currentUser = currentUserAsync.value;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не найден')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (widget.existingReview != null) {
        // Обновляем существующий отзыв
        await _reviewService.updateReview(
          widget.existingReview!.id,
          rating: _rating,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          images: _images,
          tags: _tags,
        );
      } else {
        // Создаем новый отзыв
        await _reviewService.createReview(
          reviewerId: currentUser.uid,
          reviewerName: currentUser.name,
          reviewerAvatar: currentUser.photoUrl,
          targetId: widget.targetId,
          type: widget.type,
          rating: _rating,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          images: _images,
          tags: _tags,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingReview != null
                  ? 'Отзыв обновлен'
                  : 'Отзыв отправлен на модерацию',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      SafeLog.error('ReviewFormScreen: Error submitting review', e, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить отзыв'),
        content: const Text(
          'Вы уверены, что хотите удалить этот отзыв? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteReview();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview() async {
    if (widget.existingReview == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _reviewService.deleteReview(widget.existingReview!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Отзыв удален'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      SafeLog.error('ReviewFormScreen: Error deleting review', e, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// Расширение для отображения названия типа отзыва
extension ReviewTypeExtension on ReviewType {
  String get displayName {
    switch (this) {
      case ReviewType.event:
        return 'Событие';
      case ReviewType.specialist:
        return 'Специалист';
      case ReviewType.service:
        return 'Сервис';
    }
  }
}
