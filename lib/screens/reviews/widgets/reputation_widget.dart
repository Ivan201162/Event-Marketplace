import 'package:flutter/material.dart';
import '../../../models/review.dart';

class ReputationWidget extends StatelessWidget {
  const ReputationWidget({super.key, required this.reputation});
  final SpecialistReputation reputation;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок и статус
        Row(
          children: [
            Text(
              'Репутация',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            _buildReputationStatus(),
          ],
        ),
        const SizedBox(height: 16),

        // Основная статистика
        _buildMainStats(),
        const SizedBox(height: 16),

        // Детальная статистика
        _buildDetailedStats(),
      ],
    ),
  );

  Widget _buildReputationStatus() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: _getStatusColor().withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(reputation.status.emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          reputation.status.displayName,
          style: TextStyle(color: _getStatusColor(), fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _buildMainStats() => Row(
    children: [
      // Средний рейтинг
      Expanded(
        child: _buildStatItem(
          icon: Icons.star,
          label: 'Средний рейтинг',
          value: reputation.ratingAverage.toStringAsFixed(1),
          color: Colors.amber,
        ),
      ),
      const SizedBox(width: 16),

      // Количество отзывов
      Expanded(
        child: _buildStatItem(
          icon: Icons.rate_review,
          label: 'Отзывов',
          value: reputation.reviewsCount.toString(),
          color: Colors.blue,
        ),
      ),
      const SizedBox(width: 16),

      // Репутационный балл
      Expanded(
        child: _buildStatItem(
          icon: Icons.trending_up,
          label: 'Репутация',
          value: '${reputation.reputationScore.toStringAsFixed(0)}%',
          color: _getStatusColor(),
        ),
      ),
    ],
  );

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) => Column(
    children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _buildDetailedStats() {
    if (reputation.reviewsCount == 0) {
      return const Text(
        'Пока нет отзывов для расчета репутации',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Детальная статистика',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Прогресс-бары для положительных и отрицательных отзывов
        _buildProgressBar(
          label: 'Положительные отзывы (4-5★)',
          value: reputation.positiveReviews,
          total: reputation.reviewsCount,
          color: Colors.green,
        ),
        const SizedBox(height: 8),

        _buildProgressBar(
          label: 'Отрицательные отзывы (1-2★)',
          value: reputation.negativeReviews,
          total: reputation.reviewsCount,
          color: Colors.red,
        ),
        const SizedBox(height: 8),

        _buildProgressBar(
          label: 'Нейтральные отзывы (3★)',
          value: reputation.reviewsCount - reputation.positiveReviews - reputation.negativeReviews,
          total: reputation.reviewsCount,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildProgressBar({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (value / total) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              '$value (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (reputation.status) {
      case ReputationStatus.verifiedExpert:
        return Colors.green;
      case ReputationStatus.reliable:
        return Colors.blue;
      case ReputationStatus.needsExperience:
        return Colors.orange;
      case ReputationStatus.underObservation:
        return Colors.red;
    }
  }
}

/// Компактный виджет репутации для использования в списках
class CompactReputationWidget extends StatelessWidget {
  const CompactReputationWidget({super.key, required this.reputation});
  final SpecialistReputation reputation;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      // Звезды рейтинга
      ...List.generate(
        5,
        (index) => Icon(
          index < reputation.ratingAverage ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        ),
      ),
      const SizedBox(width: 4),

      // Рейтинг
      Text(
        reputation.ratingAverage.toStringAsFixed(1),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      const SizedBox(width: 8),

      // Количество отзывов
      Text('(${reputation.reviewsCount})', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      const SizedBox(width: 8),

      // Статус репутации
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getStatusColor().withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reputation.status.emoji, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 2),
            Text(
              reputation.status.displayName,
              style: TextStyle(color: _getStatusColor(), fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ],
        ),
      ),
    ],
  );

  Color _getStatusColor() {
    switch (reputation.status) {
      case ReputationStatus.verifiedExpert:
        return Colors.green;
      case ReputationStatus.reliable:
        return Colors.blue;
      case ReputationStatus.needsExperience:
        return Colors.orange;
      case ReputationStatus.underObservation:
        return Colors.red;
    }
  }
}
