import 'package:event_marketplace_app/models/review.dart';
import 'package:event_marketplace_app/services/analytics_service.dart';
import 'package:event_marketplace_app/services/reviews_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class AddReviewScreen extends ConsumerStatefulWidget {
  // Для редактирования

  const AddReviewScreen({
    required this.specialistId, required this.specialistName, super.key,
    this.existingReview,
  });
  final String specialistId;
  final String specialistName;
  final Review? existingReview;

  @override
  ConsumerState<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends ConsumerState<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _reviewsService = ReviewsService();
  final _analyticsService = AnalyticsService();

  double _rating = 5;
  List<String> _photos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _textController.text = widget.existingReview!.text;
      _rating = widget.existingReview!.rating;
      _photos = List<String>.from(widget.existingReview!.photos);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_photos.length >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(
          content: Text('Можно добавить максимум 3 фотографии'),),);
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _photos.add(image.path);
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.existingReview != null) {
        // Редактирование существующего отзыва
        await _reviewsService.updateReview(
          widget.existingReview!.id,
          _textController.text,
          _rating,
          _photos,
        );

        _analyticsService.logEvent('edit_review', {
          'specialist_id': widget.specialistId,
          'review_id': widget.existingReview!.id,
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Отзыв обновлен')));
      } else {
        // Создание нового отзыва
        await _reviewsService.addReview(
          specialistId: widget.specialistId,
          customerId: 'current_user', // TODO: Получать из аутентификации
          customerName: 'Текущий пользователь', // TODO: Получать из профиля
          rating: _rating,
          text: _textController.text,
          photos: _photos,
        );

        _analyticsService.logEvent('add_review', {
          'specialist_id': widget.specialistId,
          'rating': _rating,
          'has_photos': _photos.isNotEmpty,
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Отзыв добавлен')));
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.existingReview != null
              ? 'Редактировать отзыв'
              : 'Добавить отзыв',),
          actions: [
            if (widget.existingReview != null)
              IconButton(
                  icon: const Icon(Icons.delete), onPressed: _showDeleteDialog,),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Информация о специалисте
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          widget.specialistName.isNotEmpty
                              ? widget.specialistName[0].toUpperCase()
                              : 'С',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold,),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.specialistName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold,),
                            ),
                            Text(
                              'Оставьте отзыв о работе специалиста',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 14,),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Рейтинг
                const Text('Оценка',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(
                    5,
                    (index) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = (index + 1).toDouble();
                        });
                      },
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getRatingText(_rating),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),

                const SizedBox(height: 24),

                // Текст отзыва
                const Text('Отзыв',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _textController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText:
                        'Расскажите о своем опыте работы с этим специалистом...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 20) {
                      return 'Отзыв должен содержать минимум 20 символов';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Фотографии
                const Text(
                  'Фотографии (необязательно)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (_photos.isNotEmpty) ...[
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      itemBuilder: (context, index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _photos[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.image),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removePhoto(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 16,),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_photos.length < 3)
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Добавить фото'),
                  ),

                const SizedBox(height: 32),

                // Кнопка отправки
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(widget.existingReview != null
                            ? 'Обновить отзыв'
                            : 'Отправить отзыв',),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
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

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить отзыв'),
        content: const Text('Вы уверены, что хотите удалить этот отзыв?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteReview();
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview() async {
    if (widget.existingReview == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _reviewsService.deleteReview(widget.existingReview!.id);

      _analyticsService.logEvent('delete_review', {
        'specialist_id': widget.specialistId,
        'review_id': widget.existingReview!.id,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Отзыв удален')));

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
