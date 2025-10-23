import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/booking.dart';
import '../models/review.dart';
import '../models/specialist.dart';
import '../services/review_service.dart';

/// Экран написания/редактирования отзыва
class WriteReviewScreen extends StatefulWidget {
  // Для редактирования

  const WriteReviewScreen(
      {super.key, required this.specialist, this.booking, this.existingReview});
  final Specialist specialist;
  final Booking? booking;
  final Review? existingReview;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _rating = 5;
  List<String> _selectedTags = [];
  bool _isLoading = false;

  // Доступные теги услуг
  final List<String> _availableTags = [
    'Качество работы',
    'Пунктуальность',
    'Профессионализм',
    'Коммуникация',
    'Цена/качество',
    'Оборудование',
    'Креативность',
    'Отзывчивость',
    'Гибкость',
    'Рекомендую',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _commentController.text = widget.existingReview!.comment;
      _selectedTags = List.from(widget.existingReview!.serviceTags);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.existingReview != null) {
        // Редактирование существующего отзыва
        await _reviewService.updateReview(
          widget.existingReview!.id,
          rating: _rating,
          comment: _commentController.text.trim(),
          serviceTags: _selectedTags,
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Отзыв обновлен')));
      } else {
        // Создание нового отзыва
        await _reviewService.createReview(
          specialistId: widget.specialist.id,
          customerId: widget.booking?.customerId ?? '',
          customerName: widget.booking?.customerName ?? '',
          rating: _rating,
          comment: _commentController.text.trim(),
          bookingId: widget.booking?.id,
          eventTitle: widget.booking?.eventTitle,
          specialistName: widget.specialist.name,
          serviceTags: _selectedTags,
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Отзыв добавлен')));
      }

      context.pop(true); // Возвращаем true для обновления списка
    } on Exception catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingReview != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать отзыв' : 'Написать отзыв'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (isEditing && !widget.existingReview!.canEdit)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Время для редактирования отзыва истекло'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
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
              // Информация о специалисте
              _buildSpecialistInfo(),

              const SizedBox(height: 24),

              // Рейтинг
              _buildRatingSection(),

              const SizedBox(height: 24),

              // Комментарий
              _buildCommentSection(),

              const SizedBox(height: 24),

              // Теги услуг
              _buildTagsSection(),

              const SizedBox(height: 32),

              // Кнопка отправки
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialistInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: widget.specialist.avatarUrl != null
                    ? NetworkImage(widget.specialist.avatarUrl!)
                    : null,
                child: widget.specialist.avatarUrl == null
                    ? Text(
                        widget.specialist.name.isNotEmpty
                            ? widget.specialist.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.specialist.name,
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (widget.booking?.eventTitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.booking!.eventTitle!,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildRatingSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Оцените работу специалиста',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (index) => GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingText(_rating),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(
                  color: _getRatingColor(), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      );

  Widget _buildCommentSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Комментарий (необязательно)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  'Расскажите о своем опыте работы с этим специалистом...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
            validator: (value) {
              if (value != null && value.trim().length > 1000) {
                return 'Комментарий не должен превышать 1000 символов';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${_commentController.text.length}/1000',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
          ),
        ],
      );

  Widget _buildTagsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Отметьте, что понравилось (необязательно)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
                selectedColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).primaryColor,
              );
            }).toList(),
          ),
        ],
      );

  Widget _buildSubmitButton() {
    final isEditing = widget.existingReview != null;
    final canEdit = isEditing ? widget.existingReview!.canEdit : true;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading || !canEdit ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                isEditing ? 'Обновить отзыв' : 'Оставить отзыв',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Очень плохо';
      case 2:
        return 'Плохо';
      case 3:
        return 'Удовлетворительно';
      case 4:
        return 'Хорошо';
      case 5:
        return 'Отлично';
      default:
        return '';
    }
  }

  Color _getRatingColor() {
    switch (_rating) {
      case 1:
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
