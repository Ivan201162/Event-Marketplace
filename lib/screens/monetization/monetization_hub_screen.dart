import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/monetization/monetization_card.dart';
import '../analytics/analytics_screen.dart';
import '../boost/boost_post_screen.dart';
import '../donation/donation_screen.dart';
import '../premium/promotion_screen.dart';
import '../subscription/subscription_screen.dart';

class MonetizationHubScreen extends ConsumerWidget {
  const MonetizationHubScreen({
    super.key,
    required this.userId,
  });
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          title: const Text('Монетизация'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.indigo, Colors.white],
              stops: [0.0, 0.3],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.monetization_on,
                            color: Colors.indigo,
                            size: 32,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Центр монетизации',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Увеличьте свой доход и продвиньте свой профиль с помощью премиум-функций',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Stats
                const Text(
                  'Быстрая статистика',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildQuickStatCard(
                        'Доход',
                        '15,420 ₽',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickStatCard(
                        'Донаты',
                        '8',
                        Icons.favorite,
                        Colors.pink,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildQuickStatCard(
                        'Подписка',
                        'Pro',
                        Icons.diamond,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickStatCard(
                        'Премиум',
                        'Активен',
                        Icons.star,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Monetization Options
                const Text(
                  'Доступные функции',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Premium Promotion
                MonetizationCard(
                  title: 'Продвижение профиля',
                  description: 'Поднимите свой профиль в топе поиска',
                  icon: Icons.star,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PromotionScreen(userId: userId),
                      ),
                    );
                  },
                ),

                // Subscriptions
                MonetizationCard(
                  title: 'Подписки',
                  description: 'Расширенные возможности для профессионалов',
                  icon: Icons.diamond,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SubscriptionScreen(userId: userId),
                      ),
                    );
                  },
                ),

                // Donations
                MonetizationCard(
                  title: 'Донаты',
                  description: 'Получайте поддержку от клиентов',
                  icon: Icons.favorite,
                  color: Colors.pink,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DonationScreen(
                          specialistId: userId,
                          specialistName: 'Ваш профиль',
                        ),
                      ),
                    );
                  },
                ),

                // Post Boosting
                MonetizationCard(
                  title: 'Продвижение постов',
                  description: 'Увеличьте охват ваших публикаций',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BoostPostScreen(
                          postId: 'demo_post',
                          postTitle: 'Демо пост для продвижения',
                        ),
                      ),
                    );
                  },
                ),

                // Analytics
                MonetizationCard(
                  title: 'Аналитика',
                  description: 'Отслеживайте доходы и статистику',
                  icon: Icons.analytics,
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnalyticsScreen(userId: userId),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Tips Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: Colors.amber,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Советы по монетизации',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTipItem(
                        'Регулярно обновляйте портфолио',
                        'Качественные работы привлекают больше клиентов',
                      ),
                      _buildTipItem(
                        'Используйте премиум-размещение',
                        'Продвижение профиля увеличивает видимость на 300%',
                      ),
                      _buildTipItem(
                        'Взаимодействуйте с аудиторией',
                        'Отвечайте на комментарии и сообщения',
                      ),
                      _buildTipItem(
                        'Создавайте качественный контент',
                        'Полезные посты получают больше донатов',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );

  Widget _buildQuickStatCard(
          String title, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );

  Widget _buildTipItem(String title, String description) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
