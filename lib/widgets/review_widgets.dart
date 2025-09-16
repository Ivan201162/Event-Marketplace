import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../providers/review_providers.dart';

/// Виджет отзыва
class ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback? onTap;
  final bool showActions;

  const ReviewCard({
    super.key,
    required this.review,
    this.onTap,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                      review.title ?? 'Без заголовка',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildRatingStars(review.rating),
                ],
              ),

              const SizedBox(height: 8),

              // Комментарий
              if (review.hasComment) ...[
                Text(
                  review.comment!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Теги
              if (review.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: review.tags
                      .map((tag) => _buildTagChip(context, tag))
                      .toList(),
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  Row(
                    children: [
                      if (review.isVerified) ...[
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Проверен',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                      if (!review.isPublic) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
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
  }

  /// Построить звезды рейтинга
  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  /// Построить чип тега
  Widget _buildTagChip(BuildContext context, String tag) {
    return Container(
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
  }

  /// Форматировать дату
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Виджет статистики отзывов
class ReviewStatisticsWidget extends StatelessWidget {
  final ReviewStatistics statistics;

  const ReviewStatisticsWidget({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
            if (statistics.commonTags.isNotEmpty) ...[
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
                children: statistics.commonTags
                    .map((tag) => _buildTagChip(context, tag))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Дополнительная информация
            _buildAdditionalInfo(context),
          ],
        ),
      ),
    );
  }

  /// Построить общий рейтинг
  Widget _buildOverallRating(BuildContext context) {
    return Column(
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
          statistics.averageRatingDescription,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${statistics.totalReviews} отзывов',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// Построить разбивку по рейтингам
  Widget _buildRatingBreakdown(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        final rating = 5 - index;
        final percentage = statistics.getRatingPercentage(rating);
        final count = statistics.ratingDistribution[rating] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '$rating',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.star,
                size: 12,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.withOpacity(0.3),
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
  }

  /// Построить чип тега
  Widget _buildTagChip(BuildContext context, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
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
  }

  /// Построить дополнительную информацию
  Widget _buildAdditionalInfo(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoItem(
          context,
          'Проверено',
          '${statistics.verifiedPercentage.toStringAsFixed(0)}%',
          Icons.verified,
          Colors.blue,
        ),
        if (statistics.lastReviewDate != null)
          _buildInfoItem(
            context,
            'Последний',
            _formatDate(statistics.lastReviewDate!),
            Icons.schedule,
            Colors.grey,
          ),
      ],
    );
  }

  /// Построить элемент информации
  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// Построить звезды рейтинга
  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  /// Форматировать дату
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}';
  }
}

/// Виджет формы отзыва
class ReviewFormWidget extends ConsumerStatefulWidget {
  final String bookingId;
  final String customerId;
  final String specialistId;
  final VoidCallback? onSubmit;

  const ReviewFormWidget({
    super.key,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    this.onSubmit,
  });

  @override
  ConsumerState<ReviewFormWidget> createState() => _ReviewFormWidgetState();
}

class _ReviewFormWidgetState extends ConsumerState<ReviewFormWidget> {
  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(reviewFormProvider);

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
                ref.read(reviewFormProvider.notifier).updateTitle(value);
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
                ref.read(reviewFormProvider.notifier).updateComment(value);
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                onPressed: formState.isSubmitting ||
                        !ref.read(reviewFormProvider.notifier).isValid
                    ? null
                    : () => _submitReview(),
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
  Widget _buildRatingSection(BuildContext context, ReviewFormState formState) {
    return Column(
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
                ref.read(reviewFormProvider.notifier).setRating(rating);
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

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
                  ref.read(reviewFormProvider.notifier).addTag(tag);
                } else {
                  ref.read(reviewFormProvider.notifier).removeTag(tag);
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
      BuildContext context, ReviewFormState formState) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Публичный отзыв'),
          subtitle: const Text('Отзыв будет виден другим пользователям'),
          value: formState.isPublic,
          onChanged: (value) {
            ref.read(reviewFormProvider.notifier).togglePublic();
          },
        ),
      ],
    );
  }

  /// Отправить отзыв
  Future<void> _submitReview() async {
    ref.read(reviewFormProvider.notifier).startSubmitting();

    try {
      await ref.read(reviewStateProvider.notifier).createReview(
            bookingId: widget.bookingId,
            customerId: widget.customerId,
            specialistId: widget.specialistId,
            rating: ref.read(reviewFormProvider).rating,
            title: ref.read(reviewFormProvider).title.isEmpty
                ? null
                : ref.read(reviewFormProvider).title,
            comment: ref.read(reviewFormProvider).comment.isEmpty
                ? null
                : ref.read(reviewFormProvider).comment,
            tags: ref.read(reviewFormProvider).selectedTags,
          );

      ref.read(reviewFormProvider.notifier).finishSubmitting();
      widget.onSubmit?.call();
    } catch (e) {
      ref.read(reviewFormProvider.notifier).setError(e.toString());
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
  final String specialistId;
  final bool showAll;

  const ReviewListWidget({
    super.key,
    required this.specialistId,
    this.showAll = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync =
        ref.watch(specialistReviewsProvider(SpecialistReviewsParams(
      specialistId: specialistId,
      onlyPublic: !showAll,
    )));

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
