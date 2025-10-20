import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import '../providers/auth_providers.dart';
import '../services/enhanced_review_service.dart';

/// Улучшенный экран создания отзыва
class EnhancedCreateReviewScreen extends ConsumerStatefulWidget {
  const EnhancedCreateReviewScreen({
    super.key,
    required this.specialistId,
    this.specialistName,
    this.existingReview,
  });

  final String specialistId;
  final String? specialistName;
  final Review? existingReview;

  @override
  ConsumerState<EnhancedCreateReviewScreen> createState() => _EnhancedCreateReviewScreenState();
}

class _EnhancedCreateReviewScreenState extends ConsumerState<EnhancedCreateReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  int _selectedRating = 5;
  final List<String> _selectedServiceTags = [];
  bool _isLoading = false;

  final List<String> _availableServiceTags = [
    'Качество работы',
    'Пунктуальность',
    'Коммуникация',
    'Профессионализм',
    'Цена/качество',
    'Рекомендую',
    'Быстрое выполнение',
    'Креативность',
    'Внимательность',
    'Гибкость',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _selectedRating = widget.existingReview!.rating;
      _commentController.text = widget.existingReview!.comment;
      _selectedServiceTags.addAll(widget.existingReview!.serviceTags);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existingReview != null ? 'Редактировать отзыв' : 'Оставить отзыв',
          ),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            if (widget.existingReview != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteReview,
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
                _buildServiceTagsSection(),

                const SizedBox(height: 32),

                // Кнопка отправки
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      );

  /// Построить информацию о специалисте
  Widget _buildSpecialistInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Text(
                  widget.specialistName?.isNotEmpty ?? false
                      ? widget.specialistName![0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.specialistName ?? 'Специалист',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Оцените качество работы',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  /// Построить секцию рейтинга
  Widget _buildRatingSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Оценка',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = rating;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      rating <= _selectedRating ? Icons.star : Icons.star_border,
                      size: 48,
                      color: rating <= _selectedRating ? Colors.amber : Colors.grey[300],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingText(_selectedRating),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      );

  /// Построить секцию комментария
  Widget _buildCommentSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Комментарий',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _commentController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Расскажите о своем опыте работы со специалистом...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
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
          const SizedBox(height: 8),
          Text(
            'Минимум 10 символов (${_commentController.text.length})',
            style: TextStyle(
              fontSize: 12,
              color: _commentController.text.length < 10 ? Colors.red : Colors.grey[600],
            ),
          ),
        ],
      );

  /// Построить секцию тегов услуг
  Widget _buildServiceTagsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Что понравилось?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите до 5 характеристик',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableServiceTags.map((tag) {
              final isSelected = _selectedServiceTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      if (_selectedServiceTags.length < 5) {
                        _selectedServiceTags.add(tag);
                      }
                    } else {
                      _selectedServiceTags.remove(tag);
                    }
                  });
                },
                selectedColor: Colors.blue[100],
                checkmarkColor: Colors.blue[700],
              );
            }).toList(),
          ),
          if (_selectedServiceTags.length >= 5) ...[
            const SizedBox(height: 8),
            Text(
              'Выбрано максимум тегов (5)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
              ),
            ),
          ],
        ],
      );

  /// Построить кнопку отправки
  Widget _buildSubmitButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.existingReview != null ? 'Обновить отзыв' : 'Оставить отзыв',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      );

  /// Получить текст рейтинга
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

  /// Отправить отзыв
  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      final reviewService = ref.read(enhancedReviewServiceProvider);

      if (widget.existingReview != null) {
        // Обновляем существующий отзыв
        await reviewService.updateReview(
          reviewId: widget.existingReview!.id,
          rating: _selectedRating,
          comment: _commentController.text.trim(),
        );
      } else {
        // Создаем новый отзыв
        await reviewService.createReview(
          specialistId: widget.specialistId,
          customerId: currentUser.uid,
          customerName: currentUser.displayName ?? 'Пользователь',
          rating: _selectedRating,
          comment: _commentController.text.trim(),
          serviceTags: _selectedServiceTags,
          customerAvatar: currentUser.photoURL,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingReview != null ? 'Отзыв обновлен' : 'Отзыв добавлен',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Удалить отзыв
  Future<void> _deleteReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить отзыв'),
        content: const Text('Вы уверены, что хотите удалить этот отзыв?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final reviewService = ref.read(enhancedReviewServiceProvider);
      await reviewService.deleteReview(widget.existingReview!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Отзыв удален'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Провайдер для улучшенного сервиса отзывов
final enhancedReviewServiceProvider =
    Provider<EnhancedReviewService>((ref) => EnhancedReviewService());
