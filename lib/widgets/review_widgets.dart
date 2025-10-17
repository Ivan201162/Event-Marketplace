import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../providers/review_providers.dart';

/// Виджет отзыва
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.onTap,
    this.showActions = false,
  });
  final Review review;
  final VoidCallback? onTap;
  final bool showActions;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с рейтингом
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        review.title.isNotEmpty ? review.title : 'Без заголовка',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildRatingStars(review.rating.round()),
                  ],
                ),

                const SizedBox(height: 8),

                // Комментарий
                if (review.hasComment) ...[
                  Text(
                    review.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Теги
                if (review.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: review.tags.map((tag) => _buildTagChip(context, tag)).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Информация о дате и статусе
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Row(
                      children: [
                        if (review.isVerified) ...[
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Проверен',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                        if (!review.isPublic) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Приватный',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  /// Построить звезды рейтинга
  Widget _buildRatingStars(int rating) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (index) => Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 20,
          ),
        ),
      );

  /// Построить чип тега
  Widget _buildTagChip(BuildContext context, String tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );

  /// Форматировать дату
  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}

/// Виджет статистики отзывов
class ReviewStatsWidget extends StatelessWidget {
  const ReviewStatsWidget({
    super.key,
    required this.statistics,
  });
  final ReviewStats statistics;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Статистика отзывов',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Общий рейтинг
              Row(
                children: [
                  _buildOverallRating(context),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildRatingBreakdown(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Популярные теги
              if (statistics.tags.isNotEmpty) ...[
                Text(
                  'Популярные теги',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: statistics.tags.map((tag) => _buildTagChip(context, tag)).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Дополнительная информация
              _buildAdditionalInfo(context),
            ],
          ),
        ),
      );

  /// Построить общий рейтинг
  Widget _buildOverallRating(BuildContext context) => Column(
        children: [
          Text(
            statistics.averageRating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          _buildRatingStars(statistics.averageRating.round()),
          const SizedBox(height: 4),
          Text(
            _getRatingDescription(statistics.averageRating.round()),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${statistics.totalReviews} отзывов',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      );

  /// Построить разбивку по рейтингам
  Widget _buildRatingBreakdown(BuildContext context) => Column(
        children: List.generate(5, (index) {
          final rating = 5 - index;
          final percentage = statistics.getRatingPercentage(rating);
          final count = statistics.ratingDistribution[rating.toString()] ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  '$rating',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.star,
                  size: 12,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }),
      );

  /// Построить чип тега
  Widget _buildTagChip(BuildContext context, String tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      );

  /// Построить дополнительную информацию
  Widget _buildAdditionalInfo(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            context,
            'Проверено',
            '${_getVerifiedPercentage().toStringAsFixed(0)}%',
            Icons.verified,
            Colors.blue,
          ),
          _buildInfoItem(
            context,
            'Последний',
            _formatDate(_getLastReviewDate()),
            Icons.schedule,
            Colors.grey,
          ),
        ],
      );

  /// Построить элемент информации
  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      );

  /// Построить звезды рейтинга
  Widget _buildRatingStars(int rating) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (index) => Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 16,
          ),
        ),
      );

  /// Форматировать дату
  String _formatDate(DateTime date) => '${date.day}.${date.month}';

  /// Получить описание рейтинга
  String _getRatingDescription(int rating) {
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
        return 'Не оценено';
    }
  }

  /// Получить процент проверенных отзывов
  double _getVerifiedPercentage() => 85; // TODO: Реализовать реальную логику

  /// Получить дату последнего отзыва
  DateTime _getLastReviewDate() =>
      DateTime.now().subtract(const Duration(days: 2)); // TODO: Реализовать реальную логику
}

/// Виджет формы отзыва
class ReviewFormWidget extends ConsumerStatefulWidget {
  const ReviewFormWidget({
    super.key,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    this.onSubmit,
  });
  final String bookingId;
  final String customerId;
  final String specialistId;
  final VoidCallback? onSubmit;

  @override
  ConsumerState<ReviewFormWidget> createState() => _ReviewFormWidgetState();
}

class _ReviewFormWidgetState extends ConsumerState<ReviewFormWidget> {
  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(reviewFormProvider) as ReviewFormState;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Оставить отзыв',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Рейтинг
            _buildRatingSection(context, formState),
            const SizedBox(height: 16),

            // Заголовок
            TextField(
              decoration: const InputDecoration(
                labelText: 'Заголовок (необязательно)',
                hintText: 'Краткое описание отзыва',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read<ReviewFormNotifier>(reviewFormProvider.notifier).updateTitle(value);
              },
            ),
            const SizedBox(height: 16),

            // Комментарий
            TextField(
              decoration: const InputDecoration(
                labelText: 'Комментарий',
                hintText: 'Подробно опишите ваше мнение',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              onChanged: (value) {
                ref.read<ReviewFormNotifier>(reviewFormProvider.notifier).updateComment(value);
              },
            ),
            const SizedBox(height: 16),

            // Теги
            _buildTagsSection(context, formState),
            const SizedBox(height: 16),

            // Настройки
            _buildSettingsSection(context, formState),
            const SizedBox(height: 16),

            // Ошибка
            if (formState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formState.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Кнопка отправки
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (formState.isSubmitting ||
                        !((ref.read<ReviewFormNotifier>(
                          reviewFormProvider.notifier,
                        ) as dynamic)
                            .isValid as bool))
                    ? null
                    : _submitReview,
                child: formState.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Отправить отзыв'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить секцию рейтинга
  Widget _buildRatingSection(BuildContext context, ReviewFormState formState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Оценка',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final rating = index + 1;
              return GestureDetector(
                onTap: () {
                  ref.read<ReviewFormNotifier>(reviewFormProvider.notifier).setRating(rating);
                },
                child: Icon(
                  rating <= formState.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            _getRatingDescription(formState.rating),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      );

  /// Построить секцию тегов
  Widget _buildTagsSection(BuildContext context, ReviewFormState formState) {
    final availableTags = ReviewTags.getTagsByRating(formState.rating);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Теги (необязательно)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: availableTags.map((tag) {
            final isSelected = formState.selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read<ReviewFormNotifier>(reviewFormProvider.notifier).addTag(tag);
                } else {
                  ref.read<ReviewFormNotifier>(reviewFormProvider.notifier).removeTag(tag);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Построить секцию настроек
  Widget _buildSettingsSection(
    BuildContext context,
    ReviewFormState formState,
  ) =>
      Column(
        children: [
          SwitchListTile(
            title: const Text('Публичный отзыв'),
            subtitle: const Text('Отзыв будет виден другим пользователям'),
            value: formState.isPublic,
            onChanged: (value) {
              ref.read<ReviewFormNotifier>(reviewFormProvider.notifier).togglePublic();
            },
          ),
        ],
      );

  /// Отправить отзыв
  Future<void> _submitReview() async {
    ref.read<ReviewFormNotifier>(reviewFormProvider.notifier).startSubmitting();

    try {
      final review = Review(
        id: '',
        specialistId: widget.specialistId,
        customerId: 'current_user_id',
        customerName: 'Current User',
        rating: (ref.read(reviewFormProvider) as ReviewFormState).rating.toDouble(),
        text: (ref.read(reviewFormProvider) as ReviewFormState).comment,
        serviceTags: [],
        date: DateTime.now(),
      );

      await ref.read<ReviewStateNotifier>(reviewStateProvider.notifier).createReview(review);

      ref.read<ReviewFormNotifier>(reviewFormProvider.notifier).finishSubmitting();
      widget.onSubmit?.call();
    } on Exception catch (e) {
      ref.read<ReviewFormNotifier>(reviewFormProvider.notifier).setError(e.toString());
    }
  }

  /// Получить описание рейтинга
  String _getRatingDescription(int rating) {
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
        return 'Не оценено';
    }
  }
}

/// Виджет списка отзывов
class ReviewListWidget extends ConsumerWidget {
  const ReviewListWidget({
    super.key,
    required this.specialistId,
    this.showAll = false,
  });
  final String specialistId;
  final bool showAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(specialistReviewsProvider(specialistId));

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Нет отзывов',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Отзывы появятся после завершения заявок',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ReviewCard(review: review),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки отзывов: $error'),
          ],
        ),
      ),
    );
  }
}
