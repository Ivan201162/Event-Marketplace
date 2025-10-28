import 'package:event_marketplace_app/models/advertisement.dart';
import 'package:event_marketplace_app/models/promotion_boost.dart';
import 'package:event_marketplace_app/models/subscription_plan.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/screens/monetization/advertisement_campaigns_screen.dart';
import 'package:event_marketplace_app/screens/monetization/my_advertisements_screen.dart';
import 'package:event_marketplace_app/screens/monetization/my_promotions_screen.dart';
import 'package:event_marketplace_app/screens/monetization/my_subscriptions_screen.dart';
import 'package:event_marketplace_app/screens/monetization/promotion_packages_screen.dart';
import 'package:event_marketplace_app/screens/monetization/subscription_plans_screen.dart';
import 'package:event_marketplace_app/services/advertisement_service.dart';
import 'package:event_marketplace_app/services/promotion_service.dart';
import 'package:event_marketplace_app/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonetizationHubScreen extends ConsumerStatefulWidget {
  const MonetizationHubScreen({super.key});

  @override
  ConsumerState<MonetizationHubScreen> createState() =>
      _MonetizationHubScreenState();
}

class _MonetizationHubScreenState extends ConsumerState<MonetizationHubScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final SubscriptionService _subscriptionService = SubscriptionService();
  final PromotionService _promotionService = PromotionService();
  final AdvertisementService _advertisementService = AdvertisementService();

  UserSubscription? _activeSubscription;
  List<PromotionBoost> _activePromotions = [];
  List<Advertisement> _activeAdvertisements = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final currentUserAsync = ref.read(currentUserProvider);
    currentUserAsync.whenData((user) async {
      if (user != null) {
        try {
          final subscription =
              await _subscriptionService.getActiveSubscription(user.id);
          final promotions =
              await _promotionService.getActivePromotions(user.id);
          final advertisements =
              await _advertisementService.getActiveAdvertisements(
            type: AdType.banner,
            limit: 5,
          );

          if (mounted) {
            setState(() {
              _activeSubscription = subscription;
              _activePromotions = promotions;
              _activeAdvertisements = advertisements;
            });
          }
        } catch (e) {
          debugPrint('Error loading user data: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Монетизация'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Подписки', icon: Icon(Icons.star)),
            Tab(text: 'Продвижение', icon: Icon(Icons.trending_up)),
            Tab(text: 'Реклама', icon: Icon(Icons.campaign)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubscriptionsTab(),
          _buildPromotionsTab(),
          _buildAdvertisementsTab(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Текущая подписка
          if (_activeSubscription != null) ...[
            _buildCurrentSubscriptionCard(),
            const SizedBox(height: 16),
          ],

          // Планы подписки
          _buildSectionHeader(
            'Планы подписки',
            'Выберите подходящий тариф для расширения возможностей',
            Icons.star,
            Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildSubscriptionPlansGrid(),

          const SizedBox(height: 24),

          // Мои подписки
          _buildSectionHeader(
            'Мои подписки',
            'Управление активными подписками',
            Icons.subscriptions,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildMySubscriptionsCard(),
        ],
      ),
    );
  }

  Widget _buildPromotionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Активные продвижения
          if (_activePromotions.isNotEmpty) ...[
            _buildActivePromotionsCard(),
            const SizedBox(height: 16),
          ],

          // Пакеты продвижения
          _buildSectionHeader(
            'Пакеты продвижения',
            'Повысьте видимость вашего профиля',
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildPromotionPackagesGrid(),

          const SizedBox(height: 24),

          // Мои продвижения
          _buildSectionHeader(
            'Мои продвижения',
            'Управление активными продвижениями',
            Icons.campaign,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildMyPromotionsCard(),
        ],
      ),
    );
  }

  Widget _buildAdvertisementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Активная реклама
          if (_activeAdvertisements.isNotEmpty) ...[
            _buildActiveAdvertisementsCard(),
            const SizedBox(height: 16),
          ],

          // Рекламные кампании
          _buildSectionHeader(
            'Рекламные кампании',
            'Создайте эффективную рекламную кампанию',
            Icons.campaign,
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildAdvertisementCampaignsGrid(),

          const SizedBox(height: 24),

          // Моя реклама
          _buildSectionHeader(
            'Моя реклама',
            'Управление рекламными объявлениями',
            Icons.ads_click,
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildMyAdvertisementsCard(),
        ],
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    final plan = _activeSubscription!;
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.amber, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Активная подписка',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Осталось дней: ${plan.daysRemaining}',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: plan.progressPercentage,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Автопродление: ${plan.autoRenew ? "Включено" : "Выключено"}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MySubscriptionsScreen(),),
                    );
                  },
                  child: const Text('Управлять',
                      style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePromotionsCard() {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Активные продвижения (${_activePromotions.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._activePromotions.take(3).map(
                  (promotion) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          promotion.type.toString().split('.').last,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
                        Text(
                          '${promotion.daysRemaining} дн.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            if (_activePromotions.length > 3)
              Text(
                'И еще ${_activePromotions.length - 3}...',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyPromotionsScreen(),),
                );
              },
              child: const Text('Посмотреть все',
                  style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAdvertisementsCard() {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Активная реклама (${_activeAdvertisements.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._activeAdvertisements.take(3).map(
                  (ad) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ad.title ?? 'Без названия',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
                        Text(
                          '${ad.daysRemaining} дн.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            if (_activeAdvertisements.length > 3)
              Text(
                'И еще ${_activeAdvertisements.length - 3}...',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyAdvertisementsScreen(),),
                );
              },
              child: const Text('Посмотреть все',
                  style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, String subtitle, IconData icon, Color color,) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionPlansGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.8,
      children: [
        _buildPlanCard(
          'Бесплатный',
          'Базовый функционал',
          '0 ₽',
          '30 дней',
          ['Поиск специалистов', 'Просмотр профилей', 'Базовые фильтры'],
          Colors.grey,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SubscriptionPlansScreen(),),
            );
          },
        ),
        _buildPlanCard(
          'Премиум',
          'Расширенные возможности',
          '499 ₽',
          '30 дней',
          ['Приоритет в поиске', 'Аналитика', 'Продвижение'],
          Colors.amber,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SubscriptionPlansScreen(),),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPromotionPackagesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.8,
      children: [
        _buildPackageCard(
          'Топ профиль',
          'Выделение в списке',
          '299 ₽',
          '7 дней',
          ['Приоритет в поиске', 'Золотая рамка', 'Топ позиция'],
          Colors.green,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PromotionPackagesScreen(),),
            );
          },
        ),
        _buildPackageCard(
          'Продвижение поста',
          'Больше просмотров',
          '199 ₽',
          '3 дня',
          ['Увеличение охвата', 'Приоритет в ленте', 'Аналитика'],
          Colors.orange,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PromotionPackagesScreen(),),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdvertisementCampaignsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.8,
      children: [
        _buildCampaignCard(
          'Баннерная реклама',
          'Верхний баннер',
          'от 500 ₽',
          'за день',
          ['Высокая видимость', 'Таргетинг', 'Аналитика'],
          Colors.purple,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdvertisementCampaignsScreen(),),
            );
          },
        ),
        _buildCampaignCard(
          'Спонсорский контент',
          'В ленте новостей',
          'от 1000 ₽',
          'за день',
          ['Органичный вид', 'Высокий CTR', 'Детальная аналитика'],
          Colors.red,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdvertisementCampaignsScreen(),),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    String title,
    String subtitle,
    String price,
    String duration,
    List<String> features,
    Color color,
    VoidCallback onTap,
  ) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.star, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                price,
                style: Theme.of(
                  context,
                )
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              Text(
                duration,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              ...features.take(2).map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Icon(Icons.check, color: color, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(feature,
                                style: Theme.of(context).textTheme.bodySmall,),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(
    String title,
    String subtitle,
    String price,
    String duration,
    List<String> features,
    Color color,
    VoidCallback onTap,
  ) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                price,
                style: Theme.of(
                  context,
                )
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              Text(
                duration,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              ...features.take(2).map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Icon(Icons.check, color: color, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(feature,
                                style: Theme.of(context).textTheme.bodySmall,),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignCard(
    String title,
    String subtitle,
    String price,
    String duration,
    List<String> features,
    Color color,
    VoidCallback onTap,
  ) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.campaign, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                price,
                style: Theme.of(
                  context,
                )
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              Text(
                duration,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              ...features.take(2).map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Icon(Icons.check, color: color, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(feature,
                                style: Theme.of(context).textTheme.bodySmall,),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMySubscriptionsCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.subscriptions, color: Colors.blue),
        title: const Text('Мои подписки'),
        subtitle: const Text('Управление активными подписками'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const MySubscriptionsScreen(),),
          );
        },
      ),
    );
  }

  Widget _buildMyPromotionsCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.trending_up, color: Colors.green),
        title: const Text('Мои продвижения'),
        subtitle: const Text('Управление активными продвижениями'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyPromotionsScreen()),
          );
        },
      ),
    );
  }

  Widget _buildMyAdvertisementsCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.campaign, color: Colors.purple),
        title: const Text('Моя реклама'),
        subtitle: const Text('Управление рекламными объявлениями'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const MyAdvertisementsScreen(),),
          );
        },
      ),
    );
  }
}
