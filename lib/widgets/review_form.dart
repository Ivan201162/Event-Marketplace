import 'package:event_marketplace_app/models/review.dart';
import 'package:event_marketplace_app/providers/review_providers.dart';
import 'package:event_marketplace_app/widgets/rating_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Форма для добавления отзыва
class ReviewForm extends ConsumerStatefulWidget {
  const ReviewForm({
    required this.specialistId, required this.specialistName, super.key,
    this.onReviewSubmitted,
    this.initialReview,
  });

  final String specialistId;
  final String specialistName;
  final void Function(Review)? onReviewSubmitted;
  final Review? initialReview;

  @override
  ConsumerState<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialReview != null) {
      _rating = widget.initialReview!.rating.toDouble();
      _commentController.text = widget.initialReview!.comment ?? '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialReview != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            isEditing ? 'Редактировать отзыв' : 'Оставить отзыв',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Оцените работу ${widget.specialistName}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 24),

          // Выбор рейтинга
          Center(
            child: Column(
              children: [
                Text(
                  'Ваша оценка',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                RatingSelectorWidget(
                  rating: _rating,
                  onRatingChanged: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                  starSize: 40,
                ),
                const SizedBox(height: 8),
                if (_rating > 0)
                  Text(
                    _getRatingText(_rating),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Комментарий
          Text(
            'Комментарий',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Расскажите о вашем опыте работы с этим специалистом...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пожалуйста, оставьте комментарий';
              }
              if (value.trim().length < 10) {
                return 'Комментарий должен содержать минимум 10 символов';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          // Кнопки
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading || _rating == 0 ? null : _submitReview,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Сохранить' : 'Отправить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Пожалуйста, выберите оценку'),
            backgroundColor: Colors.red,),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reviewService = ref.read(reviewServiceProvider);

      if (widget.initialReview != null) {
        // Редактирование существующего отзыва
        await reviewService.updateReview(
          widget.initialReview!.id,
          _rating.round(),
          _commentController.text.trim(),
        );
      } else {
        // Создание нового отзыва
        final reviewId = await reviewService.createReview(
          specialistId: widget.specialistId,
          clientId: 'current_user_id', // TODO(developer): Get from auth
          clientName: 'Current User', // TODO(developer): Get from auth
          specialistName: widget.specialistName,
          rating: _rating.round(),
          comment: _commentController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Create a Review object for callback
        final review = Review(
          id: reviewId,
          specialistId: widget.specialistId,
          clientId: 'current_user_id',
          clientName: 'Current User',
          specialistName: widget.specialistName,
          rating: _rating.round(),
          comment: _commentController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        widget.onReviewSubmitted?.call(review);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialReview != null
                ? 'Отзыв обновлен'
                : 'Отзыв добавлен',),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),);
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

/// Диалог для добавления отзыва
class ReviewFormDialog extends StatelessWidget {
  const ReviewFormDialog({
    required this.specialistId, required this.specialistName, super.key,
    this.onReviewSubmitted,
    this.initialReview,
  });

  final String specialistId;
  final String specialistName;
  final void Function(Review)? onReviewSubmitted;
  final Review? initialReview;

  @override
  Widget build(BuildContext context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: ReviewForm(
              specialistId: specialistId,
              specialistName: specialistName,
              onReviewSubmitted: onReviewSubmitted,
              initialReview: initialReview,
            ),
          ),
        ),
      );
}
