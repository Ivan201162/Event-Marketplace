import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/customer_profile.dart';
import '../models/booking.dart';
import '../services/customer_profile_service.dart';
import '../widgets/customer_profile_header.dart';
import '../widgets/customer_family_widget.dart';
import '../widgets/customer_important_dates_widget.dart';
import '../widgets/customer_order_history_widget.dart';

/// Улучшенный экран профиля заказчика
class EnhancedCustomerProfileScreen extends ConsumerStatefulWidget {
  const EnhancedCustomerProfileScreen({
    super.key,
    required this.customerId,
    this.isOwnProfile = false,
  });

  final String customerId;
  final bool isOwnProfile;

  @override
  ConsumerState<EnhancedCustomerProfileScreen> createState() => _EnhancedCustomerProfileScreenState();
}

class _EnhancedCustomerProfileScreenState extends ConsumerState<EnhancedCustomerProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Апп бар с градиентом
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Профиль заказчика',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                if (widget.isOwnProfile) ...[
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: _showSettings,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _editProfile,
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _shareProfile,
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: _showMoreOptions,
                  ),
                ],
              ],
            ),
            
            // Заголовок профиля
            SliverToBoxAdapter(
              child: CustomerProfileHeader(
                customerId: widget.customerId,
                isOwnProfile: widget.isOwnProfile,
                onEditProfile: widget.isOwnProfile ? _editProfile : null,
              ),
            ),
            
            // Табы
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(icon: Icon(Icons.family_restroom), text: 'Семья'),
                    Tab(icon: Icon(Icons.event), text: 'Даты'),
                    Tab(icon: Icon(Icons.history), text: 'Заказы'),
                    Tab(icon: Icon(Icons.analytics), text: 'Статистика'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Семья
            CustomerFamilyWidget(
              customerId: widget.customerId,
              isOwnProfile: widget.isOwnProfile,
              onAddFamilyMember: widget.isOwnProfile ? _addFamilyMember : null,
              onEditFamilyMember: widget.isOwnProfile ? _editFamilyMember : null,
              onRemoveFamilyMember: widget.isOwnProfile ? _removeFamilyMember : null,
            ),
            
            // Важные даты
            CustomerImportantDatesWidget(
              customerId: widget.customerId,
              isOwnProfile: widget.isOwnProfile,
              onAddImportantDate: widget.isOwnProfile ? _addImportantDate : null,
              onEditImportantDate: widget.isOwnProfile ? _editImportantDate : null,
              onRemoveImportantDate: widget.isOwnProfile ? _removeImportantDate : null,
            ),
            
            // История заказов
            CustomerOrderHistoryWidget(
              customerId: widget.customerId,
              onOrderTap: _showOrderDetails,
            ),
            
            // Статистика
            _buildStatisticsTab(),
          ],
        ),
      ),
      
      // Плавающая кнопка для быстрых действий
      floatingActionButton: widget.isOwnProfile
          ? FloatingActionButton.extended(
              onPressed: _showQuickActions,
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            )
          : null,
    );
  }

  Widget _buildStatisticsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(customerProfileServiceProvider).getCustomerStats(widget.customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? {};
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная статистика
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Общая статистика',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Всего заказов',
                              '${stats['totalOrders'] ?? 0}',
                              Icons.shopping_bag,
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Завершено',
                              '${stats['completedOrders'] ?? 0}',
                              Icons.check_circle,
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
                              context,
                              'Потрачено',
                              '${(stats['totalSpent'] ?? 0.0).toStringAsFixed(0)} ₽',
                              Icons.attach_money,
                              Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Средний чек',
                              '${(stats['averageOrderValue'] ?? 0.0).toStringAsFixed(0)} ₽',
                              Icons.receipt,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Семейная статистика
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Семейная информация',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Членов семьи',
                              '${stats['familyMembersCount'] ?? 0}',
                              Icons.family_restroom,
                              Colors.pink,
                            ),
                          ),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Важных дат',
                              '${stats['importantDatesCount'] ?? 0}',
                              Icons.event,
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
                              context,
                              'Предстоящих',
                              '${stats['upcomingDatesCount'] ?? 0}',
                              Icons.schedule,
                              Colors.amber,
                            ),
                          ),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Любимые категории
              if (stats['favoriteCategories'] != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Любимые категории',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ...(stats['favoriteCategories'] as Map<String, int>).entries.map((entry) => 
                          ListTile(
                            leading: Icon(
                              _getCategoryIcon(entry.key),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(entry.key),
                            trailing: Text('${entry.value} заказов'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'photography':
        return Icons.camera_alt;
      case 'music':
        return Icons.music_note;
      case 'catering':
        return Icons.restaurant;
      case 'decoration':
        return Icons.celebration;
      default:
        return Icons.category;
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildSettingsBottomSheet(),
    );
  }

  Widget _buildSettingsBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Редактировать профиль'),
            onTap: () {
              Navigator.pop(context);
              _editProfile();
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Уведомления'),
            onTap: () {
              Navigator.pop(context);
              _showNotificationSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Приватность'),
            onTap: () {
              Navigator.pop(context);
              _showPrivacySettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Помощь'),
            onTap: () {
              Navigator.pop(context);
              _showHelp();
            },
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    Navigator.pushNamed(context, '/edit_customer_profile');
  }

  void _shareProfile() {
    // Логика шаринга профиля
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildMoreOptionsBottomSheet(),
    );
  }

  Widget _buildMoreOptionsBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Пожаловаться'),
            onTap: () {
              Navigator.pop(context);
              _reportProfile();
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Заблокировать'),
            onTap: () {
              Navigator.pop(context);
              _blockProfile();
            },
          ),
        ],
      ),
    );
  }

  void _addFamilyMember() {
    Navigator.pushNamed(context, '/add_family_member');
  }

  void _editFamilyMember(String memberId) {
    Navigator.pushNamed(context, '/edit_family_member', arguments: memberId);
  }

  void _removeFamilyMember(String memberId) {
    // Логика удаления члена семьи
  }

  void _addImportantDate() {
    Navigator.pushNamed(context, '/add_important_date');
  }

  void _editImportantDate(String dateId) {
    Navigator.pushNamed(context, '/edit_important_date', arguments: dateId);
  }

  void _removeImportantDate(String dateId) {
    // Логика удаления важной даты
  }

  void _showOrderDetails(Booking order) {
    Navigator.pushNamed(context, '/order_details', arguments: order.id);
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildQuickActionsBottomSheet(),
    );
  }

  Widget _buildQuickActionsBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: const Text('Добавить члена семьи'),
            onTap: () {
              Navigator.pop(context);
              _addFamilyMember();
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Добавить важную дату'),
            onTap: () {
              Navigator.pop(context);
              _addImportantDate();
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Сделать заказ'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/search_specialists');
            },
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    // Логика настроек уведомлений
  }

  void _showPrivacySettings() {
    // Логика настроек приватности
  }

  void _showHelp() {
    // Логика помощи
  }

  void _reportProfile() {
    // Логика жалобы на профиль
  }

  void _blockProfile() {
    // Логика блокировки профиля
  }
}

/// Делегат для закрепленного таб бара
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

/// Провайдер сервиса профиля заказчика
final customerProfileServiceProvider = Provider<CustomerProfileService>((ref) {
  return CustomerProfileService();
});
