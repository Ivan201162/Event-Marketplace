import 'package:flutter/material.dart';
import '../models/profile_statistics.dart';

/// Виджет статистики профиля специалиста
class ProfileStatisticsWidget extends StatelessWidget {
  const ProfileStatisticsWidget({
    super.key,
    required this.statistics,
  });

  final ProfileStatistics statistics;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Статистика профиля',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Индикатор онлайн статуса
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statistics.onlineStatus ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statistics.onlineStatus ? 'Онлайн' : 'Оффлайн',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Основная статистика
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Просмотры',
                    statistics.views.toString(),
                    Icons.visibility,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Лайки',
                    statistics.likes.toString(),
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Рейтинг',
                    statistics.rating.toStringAsFixed(1),
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Отзывы',
                    statistics.reviewsCount.toString(),
                    Icons.rate_review,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Заказы',
                    statistics.completedOrders.toString(),
                    Icons.work,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Средняя цена',
                    '${statistics.averagePrice.toInt()}₽',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Дополнительная информация
            _buildAdditionalInfo(),
          ],
        ),
      );

  Widget _buildStatCard(
          String title, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildAdditionalInfo() => Column(
        children: [
          _buildInfoRow(
            'Время ответа',
            '${statistics.responseTime.toInt()} ч',
            Icons.access_time,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Портфолио',
            '${statistics.portfolioItems} работ',
            Icons.photo_library,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Соцсети',
            '${statistics.socialLinks} ссылок',
            Icons.link,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Закреплённые посты',
            '${statistics.pinnedPosts} постов',
            Icons.push_pin,
          ),
          if (statistics.lastActive != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Последняя активность',
              _formatLastActive(statistics.lastActive!),
              Icons.schedule,
            ),
          ],
        ],
      );

  Widget _buildInfoRow(String label, String value, IconData icon) => Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн назад';
    } else {
      return '${lastActive.day}.${lastActive.month}.${lastActive.year}';
    }
  }
}
