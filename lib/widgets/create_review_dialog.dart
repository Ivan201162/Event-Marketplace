import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../providers/auth_providers.dart';
import '../services/review_service.dart';

/// Диалог для создания отзыва
class CreateReviewDialog extends ConsumerStatefulWidget {
  const CreateReviewDialog({
    super.key,
    required this.specialistId,
    required this.specialistName,
  });
  final String specialistId;
  final String specialistName;

  @override
  ConsumerState<CreateReviewDialog> createState() => _CreateReviewDialogState();
}

class _CreateReviewDialogState extends ConsumerState<CreateReviewDialog> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _textController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'О специалисте: ${widget.specialistName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),

              const SizedBox(height: 24),

              // Рейтинг
              Text(
                'Оценка',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 12),

              _buildRatingSelector(),

              const SizedBox(height: 24),

              // Текст отзыва
              Text(
                'Комментарий',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _textController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Расскажите о своем опыте работы с этим специалистом...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: BrandColors.primary),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Отправить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildRatingSelector() => Row(
        children: List.generate(5, (index) {
          final isSelected = index < _rating;
          return GestureDetector(
            onTap: () {
              setState(() {
                _rating = index + 1;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                isSelected ? Icons.star : Icons.star_border,
                size: 32,
                color: isSelected ? Colors.amber : Colors.grey[400],
              ),
            ),
          );
        }),
      );

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите оценку'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, напишите комментарий'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      final createReview = CreateReview(
        specialistId: widget.specialistId,
        customerId: currentUser.id,
        text: _textController.text.trim(),
        rating: _rating,
        customerName: currentUser.displayName ??
            '${currentUser.firstName} ${currentUser.lastName}',
        customerAvatar: currentUser.photoURL,
      );

      await _reviewService.addReview(createReview);

      if (mounted) {
        Navigator.of(context)
            .pop(true); // Возвращаем true для обновления списка отзывов
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Отзыв успешно добавлен'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Кнопка для открытия диалога создания отзыва
class CreateReviewButton extends ConsumerWidget {
  const CreateReviewButton({
    super.key,
    required this.specialistId,
    required this.specialistName,
    this.onReviewAdded,
  });
  final String specialistId;
  final String specialistName;
  final VoidCallback? onReviewAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ElevatedButton.icon(
        onPressed: () => _showCreateReviewDialog(context),
        icon: const Icon(Icons.rate_review),
        label: const Text('Оставить отзыв'),
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.primary,
          foregroundColor: Colors.white,
        ),
      );

  Future<void> _showCreateReviewDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateReviewDialog(
        specialistId: specialistId,
        specialistName: specialistName,
      ),
    );

    if (result ?? false && onReviewAdded != null) {
      onReviewAdded!();
    }
  }
}
