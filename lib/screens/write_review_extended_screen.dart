import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/booking.dart';
import '../models/review.dart';
import '../models/specialist.dart';
import '../services/review_service.dart';

/// Расширенный экран написания/редактирования отзыва
class WriteReviewExtendedScreen extends StatefulWidget {
  // Для редактирования

  const WriteReviewExtendedScreen({
    super.key,
    required this.specialist,
    this.booking,
    this.existingReview,
  });
  final Specialist specialist;
  final Booking? booking;
  final Review? existingReview;

  @override
  State<WriteReviewExtendedScreen> createState() =>
      _WriteReviewExtendedScreenState();
}

class _WriteReviewExtendedScreenState extends State<WriteReviewExtendedScreen> {
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
          _rating,
          _commentController.text.trim(),
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Отзыв обновлен')));
      } else {
        // Создание нового отзыва
        await _reviewService.createReview(
          specialistId: widget.specialist.id,
          clientId: widget.booking?.customerId ??
              'current_customer_id', // TODO(developer): Получить из AuthService
          clientName: widget.booking?.customerName ?? 'Заказчик',
          specialistName: widget.specialist.name,
          rating: _rating,
          comment: _commentController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.existingReview != null
              ? 'Редактировать отзыв'
              : 'Оставить отзыв'),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop()),
          actions: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              TextButton(
                  onPressed: _submitReview, child: const Text('Отправить')),
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

                const SizedBox(height: 24),

                // Информация о заказе
                if (widget.booking != null) _buildBookingInfo(),
              ],
            ),
          ),
        ),
      );

  Widget _buildSpecialistInfo() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: widget.specialist.imageUrlValue != null
                  ? NetworkImage(widget.specialist.imageUrlValue!)
                  : null,
              child: widget.specialist.imageUrlValue == null
                  ? Text(
                      widget.specialist.name.isNotEmpty
                          ? widget.specialist.name[0].toUpperCase()
                          : 'С',
                      style: const TextStyle(fontSize: 20),
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
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.specialist.category.displayName,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Расскажите о своем опыте работы со специалистом...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
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
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      );

  Widget _buildTagsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Отметьте качества специалиста',
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
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue,
              );
            }).toList(),
          ),
        ],
      );

  Widget _buildBookingInfo() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Информация о заказе',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.booking!.eventTitle.isNotEmpty
                        ? widget.booking!.eventTitle
                        : widget.booking!.title ?? 'Заказ',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${widget.booking!.eventDate.day}.${widget.booking!.eventDate.month}.${widget.booking!.eventDate.year}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (widget.booking!.location != null &&
                widget.booking!.location!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.booking!.location!,
                        style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ],
          ],
        ),
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

  Color _getRatingColor() {
    switch (_rating) {
      case 1:
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
