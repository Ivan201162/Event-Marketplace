import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/review.dart';
import '../data/repositories/review_repository.dart';

/// Экран добавления отзыва
class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({
    super.key,
    required this.specialistId,
    required this.specialistName,
  });
  final String specialistId;
  final String specialistName;

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final ReviewRepository _reviewRepository = ReviewRepository();

  double _rating = 5;
  bool _isLoading = false;
  String? _selectedBookingId;

  @override
  void initState() {
    super.initState();
    _loadAvailableBookings();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Оставить отзыв'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Информация о специалисте
                      _buildSpecialistInfo(),

                      const SizedBox(height: 24),

                      // Выбор заказа
                      _buildBookingSelector(),

                      const SizedBox(height: 24),

                      // Рейтинг
                      _buildRatingSection(),

                      const SizedBox(height: 24),

                      // Комментарий
                      _buildCommentSection(),

                      const SizedBox(height: 32),

                      // Кнопка отправки
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
      );

  /// Информация о специалисте
  Widget _buildSpecialistInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Text(
                  widget.specialistName.isNotEmpty ? widget.specialistName[0].toUpperCase() : 'С',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.specialistName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Специалист',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  /// Выбор заказа
  Widget _buildBookingSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выберите заказ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getAvailableBookings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey[600],
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нет доступных заказов для отзыва',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Отзыв можно оставить только для завершенных заказов',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return DropdownButtonFormField<String>(
                initialValue: _selectedBookingId,
                decoration: const InputDecoration(
                  labelText: 'Заказ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                items: snapshot.data!
                    .map(
                      (booking) => DropdownMenuItem<String>(
                        value: booking['id'],
                        child: Text(
                          'Заказ от ${_formatDate(booking['eventDate'])} - ${booking['totalPrice']} ₽',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBookingId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите заказ';
                  }
                  return null;
                },
              );
            },
          ),
        ],
      );

  /// Секция рейтинга
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
            child: Column(
              children: [
                // Звезды
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starRating = index + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = starRating.toDouble();
                        });
                      },
                      child: Icon(
                        starRating <= _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 8),

                // Числовое значение
                Text(
                  _rating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),

                const SizedBox(height: 8),

                // Описание рейтинга
                Text(
                  _getRatingDescription(_rating),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );

  /// Секция комментария
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
            decoration: const InputDecoration(
              hintText: 'Расскажите о вашем опыте работы со специалистом...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.comment),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите комментарий';
              }
              if (value.trim().length < 10) {
                return 'Комментарий должен содержать минимум 10 символов';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Минимум 10 символов',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      );

  /// Кнопка отправки
  Widget _buildSubmitButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
              : const Text(
                  'Отправить отзыв',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      );

  /// Загрузить доступные заказы
  Future<void> _loadAvailableBookings() async {
    // Здесь должна быть логика загрузки доступных заказов
    // Пока оставляем пустым
  }

  /// Получить доступные заказы
  Future<List<Map<String, dynamic>>> _getAvailableBookings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      return [];
    }

    // Здесь должна быть логика получения завершенных заказов
    // для которых еще нет отзыва
    // Пока возвращаем тестовые данные
    return [
      {
        'id': 'booking_1',
        'eventDate': DateTime.now().subtract(const Duration(days: 7)),
        'totalPrice': 5000.0,
      },
    ];
  }

  /// Отправить отзыв
  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите заказ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        throw Exception('Пользователь не авторизован');
      }

      final review = Review(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookingId: _selectedBookingId!,
        specialistId: widget.specialistId,
        customerId: authProvider.user!.uid,
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _reviewRepository.addReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Спасибо! Отзыв отправлен'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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

  /// Получить описание рейтинга
  String _getRatingDescription(double rating) {
    if (rating >= 4.5) {
      return 'Отлично';
    } else if (rating >= 3.5) {
      return 'Хорошо';
    } else if (rating >= 2.5) {
      return 'Удовлетворительно';
    } else if (rating >= 1.5) {
      return 'Плохо';
    } else {
      return 'Очень плохо';
    }
  }

  /// Форматирование даты
  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}
