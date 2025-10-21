import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../services/review_service.dart';

/// Экран редактирования отзыва
class EditReviewScreen extends ConsumerStatefulWidget {
  const EditReviewScreen({super.key, required this.review});

  final Review review;

  @override
  ConsumerState<EditReviewScreen> createState() => _EditReviewScreenState();
}

class _EditReviewScreenState extends ConsumerState<EditReviewScreen> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late int _rating;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rating = widget.review.rating;
    _commentController.text = widget.review.comment;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await _reviewService.updateReview(
        widget.review.id,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отзыв успешно обновлен'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _deleteReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить отзыв'),
        content: const Text(
          'Вы уверены, что хотите удалить этот отзыв? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() {
        _isSubmitting = true;
        _error = null;
      });

      try {
        await _reviewService.deleteReview(widget.review.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Отзыв удален'), backgroundColor: Colors.orange),
          );
          Navigator.of(context).pop(true);
        }
      } on Exception catch (e) {
        setState(() {
          _error = e.toString();
        });
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Редактировать отзыв'),
      elevation: 0,
      actions: [
        if (widget.review.canDelete)
          IconButton(
            onPressed: _isSubmitting ? null : _deleteReview,
            icon: const Icon(Icons.delete),
            tooltip: 'Удалить отзыв',
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
            // Информация о заказе
            _buildBookingInfo(),
            const SizedBox(height: 24),

            // Рейтинг
            _buildRatingSection(),
            const SizedBox(height: 24),

            // Комментарий
            _buildCommentSection(),
            const SizedBox(height: 24),

            // Ошибка
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: TextStyle(color: Colors.red[600])),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildBookingInfo() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Информация о заказе',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...[
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Специалист: ${widget.review.specialistName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (widget.review.eventTitle != null) ...[
            Row(
              children: [
                Icon(Icons.event, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Услуга: ${widget.review.eventTitle}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Дата отзыва: ${_formatDate(widget.review.createdAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (widget.review.isEdited) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.edit, size: 16, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Отредактировано: ${_formatDate(widget.review.editedAt!)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.orange[600]),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );

  Widget _buildRatingSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Оцените качество услуги',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Center(
        child: Column(
          children: [
            // Звезды для выбора рейтинга
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final rating = index + 1;
                final isSelected = rating <= _rating;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = rating;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      size: 40,
                      color: isSelected ? Colors.amber : Colors.grey[400],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _getRatingText(_rating),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildCommentSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Комментарий',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _commentController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Поделитесь своими впечатлениями о работе специалиста...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
          ),
        ),
        validator: (value) {
          if (value != null && value.trim().length > 500) {
            return 'Комментарий не должен превышать 500 символов';
          }
          return null;
        },
      ),
      const SizedBox(height: 8),
      Text(
        '${_commentController.text.length}/500',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      ),
    ],
  );

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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
