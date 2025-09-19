import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive_utils.dart';
import '../providers/app_review_provider.dart';
import '../services/app_review_service.dart';
import '../widgets/responsive_layout.dart';

/// Виджет для отображения диалога запроса отзыва
class AppReviewDialog extends ConsumerWidget {
  const AppReviewDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AlertDialog(
        title: const Row(
          children: [
            Text('⭐'),
            SizedBox(width: 8),
            Expanded(
              child: Text('Оцените приложение'),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Нам важно ваше мнение! Если вам нравится приложение, пожалуйста, оставьте отзыв в магазине.',
            ),
            SizedBox(height: 16),
            Text(
              'Ваша оценка поможет другим пользователям найти наше приложение.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(appReviewProvider.notifier).dismissReviewRequest();
              Navigator.of(context).pop();
            },
            child: const Text('Позже'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(appReviewProvider.notifier).requestReview();
              Navigator.of(context).pop();
            },
            child: const Text('Оценить'),
          ),
        ],
      );
}

/// Виджет для отображения настроек отзывов
class AppReviewSettingsWidget extends ConsumerWidget {
  const AppReviewSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewState = ref.watch(appReviewProvider);
    final reviewStats = ref.watch(reviewStatsProvider);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star),
              const SizedBox(width: 12),
              const Expanded(
                child: ResponsiveText(
                  'Отзывы о приложении',
                  isTitle: true,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.read(appReviewProvider.notifier).refresh(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Статус отзыва
          _buildStatusRow(
            'Статус отзыва',
            reviewState.reviewStatus,
            Color(reviewState.statusColor),
          ),

          // Доступность in-app review
          _buildStatusRow(
            'In-app review',
            reviewState.isAvailable ? 'Доступен' : 'Недоступен',
            reviewState.isAvailable ? Colors.green : Colors.orange,
          ),

          // Рекомендуемое время
          _buildStatusRow(
            'Рекомендуемое время',
            ref.watch(reviewTimingDescriptionProvider),
            Color(ref.watch(reviewTimingColorProvider)),
          ),

          // Статистика
          reviewStats.when(
            data: (stats) => Column(
              children: [
                _buildInfoRow(
                  'Запусков приложения',
                  '${stats.appLaunchCount}',
                  Icons.play_arrow,
                ),
                _buildInfoRow(
                  'Запросов отзыва',
                  '${stats.reviewRequestCount}',
                  Icons.star,
                ),
                if (stats.lastReviewRequest != null)
                  _buildInfoRow(
                    'Последний запрос',
                    stats.formattedLastRequest,
                    Icons.access_time,
                  ),
                if (stats.lastFeatureUsed != null)
                  _buildInfoRow(
                    'Последняя функция',
                    stats.lastFeatureUsed!,
                    Icons.functions,
                  ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Ошибка: $error'),
          ),

          const SizedBox(height: 16),

          // Кнопки действий
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: reviewState.isRequesting
                      ? null
                      : () =>
                          ref.read(appReviewProvider.notifier).requestReview(),
                  icon: reviewState.isRequesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.star),
                  label: Text(
                    reviewState.isRequesting ? 'Запрос...' : 'Запросить отзыв',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: reviewState.isRequesting
                      ? null
                      : () => ref
                          .read(appReviewProvider.notifier)
                          .openStoreListing(),
                  icon: const Icon(Icons.store),
                  label: const Text('Открыть магазин'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Дополнительные кнопки
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref
                      .read(appReviewProvider.notifier)
                      .openReviewPageInBrowser(),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Отзыв в браузере'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showResetDialog(context, ref),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Сбросить'),
                ),
              ),
            ],
          ),

          // Ошибки
          if (reviewState.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResponsiveText(
                      reviewState.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(
              label,
              isSubtitle: true,
            ),
            ResponsiveText(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildInfoRow(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ResponsiveText(
                label,
                isSubtitle: true,
              ),
            ),
            ResponsiveText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить состояние отзывов'),
        content: const Text(
          'Вы уверены, что хотите сбросить все данные о отзывах? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(appReviewProvider.notifier).resetReviewState();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения статистики отзывов
class ReviewStatsWidget extends ConsumerWidget {
  const ReviewStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewStats = ref.watch(reviewStatsProvider);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics),
              SizedBox(width: 12),
              ResponsiveText(
                'Статистика отзывов',
                isTitle: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          reviewStats.when(
            data: (stats) => Column(
              children: [
                _buildStatRow(
                  'Запусков приложения',
                  '${stats.appLaunchCount}',
                  Icons.play_arrow,
                  Colors.blue,
                ),
                _buildStatRow(
                  'Запросов отзыва',
                  '${stats.reviewRequestCount}',
                  Icons.star,
                  Colors.orange,
                ),
                _buildStatRow(
                  'Статус отзыва',
                  stats.isDismissed ? 'Отклонен' : 'Активен',
                  Icons.status,
                  stats.isDismissed ? Colors.red : Colors.green,
                ),
                if (stats.lastReviewRequest != null)
                  _buildStatRow(
                    'Последний запрос',
                    stats.formattedLastRequest,
                    Icons.access_time,
                    Colors.grey[600]!,
                  ),
                if (stats.lastFeatureUsed != null)
                  _buildStatRow(
                    'Последняя функция',
                    stats.lastFeatureUsed!,
                    Icons.functions,
                    Colors.purple,
                  ),
                if (stats.lastFeatureUsedTime != null)
                  _buildStatRow(
                    'Время использования',
                    stats.formattedLastFeatureTime,
                    Icons.schedule,
                    Colors.grey[600]!,
                  ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Ошибка: $error'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ResponsiveText(
                label,
                isSubtitle: true,
              ),
            ),
            ResponsiveText(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      );
}

/// Виджет для отображения рекомендаций по отзывам
class ReviewRecommendationsWidget extends ConsumerWidget {
  const ReviewRecommendationsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewState = ref.watch(appReviewProvider);
    final timing = reviewState.recommendedTiming;

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                ref.watch(reviewTimingIconProvider),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: ResponsiveText(
                  'Рекомендации по отзывам',
                  isTitle: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Текущий статус
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Color(ref.watch(reviewTimingColorProvider)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color(ref.watch(reviewTimingColorProvider)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info,
                  color: Color(ref.watch(reviewTimingColorProvider)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ResponsiveText(
                    ref.watch(reviewTimingDescriptionProvider),
                    style: TextStyle(
                      color: Color(ref.watch(reviewTimingColorProvider)),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Рекомендации
          ..._getRecommendations(timing).map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResponsiveText(
                      recommendation,
                      isSubtitle: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getRecommendations(ReviewTiming timing) {
    switch (timing) {
      case ReviewTiming.now:
        return [
          'Пользователь активно использует приложение',
          'Прошло достаточно времени с последнего запроса',
          'Рекомендуется запросить отзыв сейчас',
          'Используйте in-app review для лучшего UX',
        ];
      case ReviewTiming.soon:
        return [
          'Пользователь использует приложение регулярно',
          'Скоро можно будет запросить отзыв',
          'Дождитесь подходящего момента',
          'Отслеживайте активность пользователя',
        ];
      case ReviewTiming.notYet:
        return [
          'Пользователь еще не достаточно знаком с приложением',
          'Нужно больше времени для оценки',
          'Не запрашивайте отзыв слишком рано',
          'Сосредоточьтесь на улучшении UX',
        ];
    }
  }
}

/// Виджет для отображения кнопки быстрого отзыва
class QuickReviewButton extends ConsumerWidget {
  const QuickReviewButton({
    super.key,
    this.text,
    this.icon,
  });
  final String? text;
  final IconData? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewState = ref.watch(appReviewProvider);

    return ElevatedButton.icon(
      onPressed: reviewState.isRequesting
          ? null
          : () => ref.read(appReviewProvider.notifier).requestReview(),
      icon: reviewState.isRequesting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon ?? Icons.star),
      label: Text(
        reviewState.isRequesting ? 'Запрос...' : (text ?? 'Оценить приложение'),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
    );
  }
}
