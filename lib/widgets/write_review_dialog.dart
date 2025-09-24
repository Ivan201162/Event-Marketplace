import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/review_service.dart';

class WriteReviewDialog extends StatefulWidget {
  const WriteReviewDialog({
    super.key,
    required this.bookingId,
    required this.specialistId,
  });

  final String bookingId;
  final String specialistId;

  @override
  State<WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<WriteReviewDialog> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();
  
  double _rating = 5.0;
  List<String> _selectedTags = [];
  bool _isSubmitting = false;

  final List<String> _availableTags = [
    'Качество',
    'Пунктуальность',
    'Цена',
    'Общение',
    'Профессионализм',
    'Креативность',
    'Надежность',
    'Сервис',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Написать отзыв'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Рейтинг
            const Text(
              'Оцените качество услуг:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = (index + 1).toDouble()),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 32,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            
            // Комментарий
            const Text(
              'Комментарий:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Расскажите о вашем опыте...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 16),
            
            // Теги
            const Text(
              'Что понравилось больше всего:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _availableTags.map((tag) => FilterChip(
                label: Text(tag),
                selected: _selectedTags.contains(tag),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Отправить'),
        ),
      ],
    );
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, напишите комментарий')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Получаем ID текущего пользователя (в реальном приложении из AuthService)
      final currentUserId = 'current_user_id'; // TODO: Получить из AuthService
      
      await _reviewService.createReview(
        bookingId: widget.bookingId,
        specialistId: widget.specialistId,
        customerId: currentUserId,
        rating: _rating,
        comment: _commentController.text.trim(),
        tags: _selectedTags,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отзыв успешно отправлен')),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки отзыва: $e')),
        );
      }
    }
  }
}