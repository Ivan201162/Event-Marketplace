import 'package:flutter/material.dart';
import '../data/repositories/review_repository.dart';
import 'add_review_screen.dart';

/// Диалог напоминания об отзыве
class ReviewReminderDialog extends StatefulWidget {
  const ReviewReminderDialog({
    super.key,
    required this.bookingId,
    required this.specialistId,
    required this.specialistName,
    required this.eventDate,
  });
  final String bookingId;
  final String specialistId;
  final String specialistName;
  final DateTime eventDate;

  @override
  State<ReviewReminderDialog> createState() => _ReviewReminderDialogState();
}

class _ReviewReminderDialogState extends State<ReviewReminderDialog> {
  final ReviewRepository _reviewRepository = ReviewRepository();
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Оцените специалиста',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Информация о заказе
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.specialistName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Заказ от ${_formatDate(widget.eventDate)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Текст напоминания
        Text(
          'Ваш заказ завершен! Пожалуйста, оставьте отзыв о работе специалиста. Это поможет другим пользователям сделать правильный выбор.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 16),

        // Преимущества отзыва
        Row(
          children: [
            const Icon(Icons.thumb_up, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Помогает другим пользователям',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.verified, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Повышает качество сервиса',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    ),
    actions: [
      // Кнопка "Позже"
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: Text('Позже', style: TextStyle(color: Colors.grey[600])),
      ),

      // Кнопка "Оставить отзыв"
      ElevatedButton(
        onPressed: _isLoading ? null : _leaveReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Оставить отзыв'),
      ),
    ],
  );

  /// Оставить отзыв
  void _leaveReview() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AddReviewScreen(
          specialistId: widget.specialistId,
          specialistName: widget.specialistName,
        ),
      ),
    );
  }

  /// Форматирование даты
  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}

/// Баннер напоминания об отзыве
class ReviewReminderBanner extends StatefulWidget {
  const ReviewReminderBanner({
    super.key,
    required this.bookingId,
    required this.specialistId,
    required this.specialistName,
    required this.eventDate,
    this.onDismiss,
  });
  final String bookingId;
  final String specialistId;
  final String specialistName;
  final DateTime eventDate;
  final VoidCallback? onDismiss;

  @override
  State<ReviewReminderBanner> createState() => _ReviewReminderBannerState();
}

class _ReviewReminderBannerState extends State<ReviewReminderBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showReviewDialog,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Иконка
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 24),
                ),

                const SizedBox(width: 16),

                // Текст
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Оцените специалиста',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Оставьте отзыв о работе ${widget.specialistName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // Кнопка закрытия
                IconButton(
                  onPressed: _dismissBanner,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Показать диалог отзыва
  void _showReviewDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => ReviewReminderDialog(
        bookingId: widget.bookingId,
        specialistId: widget.specialistId,
        specialistName: widget.specialistName,
        eventDate: widget.eventDate,
      ),
    );
  }

  /// Скрыть баннер
  void _dismissBanner() {
    setState(() {
      _isDismissed = true;
    });
    widget.onDismiss?.call();
  }
}

/// Виджет статуса отзыва в истории заказов
class ReviewStatusWidget extends StatefulWidget {
  const ReviewStatusWidget({
    super.key,
    required this.bookingId,
    required this.specialistId,
    required this.specialistName,
  });
  final String bookingId;
  final String specialistId;
  final String specialistName;

  @override
  State<ReviewStatusWidget> createState() => _ReviewStatusWidgetState();
}

class _ReviewStatusWidgetState extends State<ReviewStatusWidget> {
  final ReviewRepository _reviewRepository = ReviewRepository();
  bool _hasReview = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkReviewStatus();
  }

  Future<void> _checkReviewStatus() async {
    try {
      final review = await _reviewRepository.getReviewByBookingId(widget.bookingId);
      if (mounted) {
        setState(() {
          _hasReview = review != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_hasReview) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.green, size: 16),
            const SizedBox(width: 4),
            Text(
              'Отзыв оставлен',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_border, color: Colors.orange, size: 16),
          const SizedBox(width: 4),
          Text(
            'Оставить отзыв',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.orange, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
