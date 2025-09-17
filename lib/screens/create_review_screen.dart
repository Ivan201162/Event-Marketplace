import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/review_providers.dart';
import '../models/review.dart';

/// Экран создания отзыва
class CreateReviewScreen extends ConsumerStatefulWidget {
  final String targetId;

  const CreateReviewScreen({
    super.key,
    required this.targetId,
  });

  @override
  ConsumerState<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends ConsumerState<CreateReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();

  int _rating = 5;
  List<String> _selectedTags = [];
  bool _isPublic = true;

  final List<String> _availableTags = [
    'Профессионализм',
    'Пунктуальность',
    'Качество работы',
    'Общение',
    'Цена',
    'Рекомендую',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewFormState = ref.watch(reviewFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать отзыв'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: reviewFormState.isLoading ? null : _submitReview,
            child: const Text('Отправить'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Рейтинг
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Оцените качество работы',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            onPressed: () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 40,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getRatingText(_rating),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Заголовок отзыва
              Text(
                'Заголовок отзыва',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Краткое описание вашего опыта',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите заголовок отзыва';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Комментарий
              Text(
                'Подробный отзыв',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Расскажите подробнее о вашем опыте...',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите текст отзыва';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Теги
              Text(
                'Отметьте подходящие характеристики',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
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
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Настройки приватности
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Настройки приватности',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Публичный отзыв'),
                        subtitle: const Text(
                            'Отзыв будет виден другим пользователям'),
                        value: _isPublic,
                        onChanged: (value) {
                          setState(() {
                            _isPublic = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Кнопка отправки
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: reviewFormState.isLoading ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: reviewFormState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Отправить отзыв'),
                ),
              ),

              if (reviewFormState.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reviewFormState.errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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

  void _submitReview() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(reviewFormProvider.notifier)
        .createReview(
          targetId: widget.targetId,
          type: ReviewType.specialist,
          title: _titleController.text.trim(),
          content: _commentController.text.trim(),
          rating: _rating,
          tags: _selectedTags,
        )
        .then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отзыв отправлен успешно')),
        );
        Navigator.of(context).pop();
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $error')),
        );
      }
    });
  }
}
