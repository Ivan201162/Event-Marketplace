import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_extended.dart';
import '../services/review_extended_service.dart';

/// Экран создания расширенного отзыва
class CreateReviewExtendedScreen extends ConsumerStatefulWidget {
  const CreateReviewExtendedScreen({
    super.key,
    required this.specialistId,
    required this.bookingId,
  });
  final String specialistId;
  final String bookingId;

  @override
  ConsumerState<CreateReviewExtendedScreen> createState() =>
      _CreateReviewExtendedScreenState();
}

class _CreateReviewExtendedScreenState
    extends ConsumerState<CreateReviewExtendedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _tagsController = TextEditingController();

  final ReviewExtendedService _reviewService = ReviewExtendedService();

  int _rating = 5;
  double _quality = 5;
  double _communication = 5;
  double _punctuality = 5;
  double _value = 5;

  final List<ReviewMedia> _media = [];
  final List<String> _tags = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Оставить отзыв'),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _submitReview,
              child: const Text('Отправить'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Общий рейтинг
                _buildOverallRating(),

                const SizedBox(height: 24),

                // Детальные оценки
                _buildDetailedRatings(),

                const SizedBox(height: 24),

                // Комментарий
                _buildCommentSection(),

                const SizedBox(height: 24),

                // Медиа
                _buildMediaSection(),

                const SizedBox(height: 24),

                // Теги
                _buildTagsSection(),

                const SizedBox(height: 24),

                // Кнопка отправки
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitReview,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Отправить отзыв'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildOverallRating() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Общая оценка',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _getRatingText(_rating),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildDetailedRatings() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Детальные оценки',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildRatingSlider('Качество услуг', _quality, (value) {
                setState(() {
                  _quality = value;
                });
              }),
              _buildRatingSlider('Общение', _communication, (value) {
                setState(() {
                  _communication = value;
                });
              }),
              _buildRatingSlider('Пунктуальность', _punctuality, (value) {
                setState(() {
                  _punctuality = value;
                });
              }),
              _buildRatingSlider('Соотношение цена/качество', _value, (value) {
                setState(() {
                  _value = value;
                });
              }),
            ],
          ),
        ),
      );

  Widget _buildRatingSlider(
    String label,
    double value,
    Function(double) onChanged,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 40,
            onChanged: onChanged,
          ),
        ],
      );

  Widget _buildCommentSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Комментарий',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Расскажите о вашем опыте...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, оставьте комментарий';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildMediaSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Медиа',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_media.length}/10',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Кнопки добавления медиа
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _media.length < 10 ? _pickPhotos : null,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Фото'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _media.length < 10 ? _pickVideo : null,
                      icon: const Icon(Icons.video_library),
                      label: const Text('Видео'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _media.length < 10 ? _takePhoto : null,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Снять'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Список медиа
              if (_media.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _media.length,
                    itemBuilder: (context, index) {
                      final media = _media[index];
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                media.thumbnailUrl,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error),
                                ),
                              ),
                            ),
                            if (media.type == MediaType.video)
                              const Positioned.fill(
                                child: Center(
                                  child: Icon(
                                    Icons.play_circle_filled,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeMedia(index),
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
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildTagsSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Теги',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Поле ввода тегов
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  hintText: 'Добавить тег...',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.add),
                ),
                onFieldSubmitted: _addTag,
              ),

              const SizedBox(height: 16),

              // Список тегов
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => _removeTag(tag),
                          deleteIcon: const Icon(Icons.close, size: 18),
                        ),
                      )
                      .toList(),
                ),
              ],

              const SizedBox(height: 8),

              // Предустановленные теги
              const Text(
                'Популярные теги:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Профессионализм',
                  'Пунктуальность',
                  'Качество',
                  'Внимательность',
                  'Рекомендую',
                  'Отличная работа',
                ]
                    .map(
                      (tag) => ActionChip(
                        label: Text(tag),
                        onPressed: () => _addTag(tag),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      );

  Future<void> _pickPhotos() async {
    try {
      final images =
          await _reviewService.pickPhotos(maxImages: 10 - _media.length);
      for (final image in images) {
        final media = await _reviewService.uploadPhoto(image);
        if (media != null) {
          setState(() {
            _media.add(media);
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка выбора фото: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final video = await _reviewService.pickVideo();
      if (video != null) {
        final media = await _reviewService.uploadVideo(video);
        if (media != null) {
          setState(() {
            _media.add(media);
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка выбора видео: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _reviewService.takePhoto();
      if (image != null) {
        final media = await _reviewService.uploadPhoto(image);
        if (media != null) {
          setState(() {
            _media.add(media);
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка съемки фото: $e');
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _media.removeAt(index);
    });
  }

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty && !_tags.contains(tag.trim())) {
      setState(() {
        _tags.add(tag.trim());
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO(developer): Получить данные текущего пользователя
      const customerId = 'demo_customer_id';
      const customerName = 'Демо Пользователь';
      const customerPhotoUrl = '';

      final stats = ReviewStats(
        quality: _quality,
        communication: _communication,
        punctuality: _punctuality,
        value: _value,
      );

      final reviewId = await _reviewService.createReview(
        specialistId: widget.specialistId,
        customerId: customerId,
        customerName: customerName,
        customerPhotoUrl: customerPhotoUrl,
        bookingId: widget.bookingId,
        rating: _rating,
        comment: _commentController.text.trim(),
        media: _media,
        tags: _tags,
        stats: stats,
      );

      if (reviewId != null) {
        Navigator.pop(context, true);
        _showSuccessSnackBar('Отзыв успешно создан');
      } else {
        _showErrorSnackBar('Ошибка создания отзыва');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
