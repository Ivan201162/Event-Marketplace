import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/customer_profile.dart';
import '../services/customer_profile_service.dart';
import '../widgets/enhanced_page_transition.dart';
import '../widgets/responsive_layout.dart';
import 'edit_customer_profile_screen.dart';
import 'customer_booking_history_screen.dart';
import 'customer_important_dates_screen.dart';

/// Экран профиля заказчика
class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({
    super.key,
    required this.customerId,
  });

  final String customerId;

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final CustomerProfileService _profileService = CustomerProfileService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
        largeDesktop: _buildLargeDesktopLayout(),
      );

  Widget _buildMobileLayout() => Scaffold(
        body: CustomScrollView(
          slivers: [
            // AppBar с профилем
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editProfile,
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareProfile,
                ),
              ],
            ),
            // Вкладки
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(icon: Icon(Icons.person), text: 'О себе'),
                    Tab(icon: Icon(Icons.history), text: 'История'),
                    Tab(icon: Icon(Icons.calendar_today), text: 'Даты'),
                    Tab(icon: Icon(Icons.favorite), text: 'Избранное'),
                  ],
                ),
              ),
            ),
            // Контент
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAboutTab(),
                  _buildHistoryTab(),
                  _buildDatesTab(),
                  _buildFavoritesTab(),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildTabletLayout() => Scaffold(
        appBar: AppBar(
          title: const Text('Профиль'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editProfile,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareProfile,
            ),
          ],
        ),
        body: ResponsiveContainer(
          child: Column(
            children: [
              // Заголовок профиля
              _buildProfileHeader(),
              // Вкладки
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.person), text: 'О себе'),
                  Tab(icon: Icon(Icons.history), text: 'История заказов'),
                  Tab(icon: Icon(Icons.calendar_today), text: 'Важные даты'),
                  Tab(icon: Icon(Icons.favorite), text: 'Избранное'),
                ],
              ),
              // Контент
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAboutTab(),
                    _buildHistoryTab(),
                    _buildDatesTab(),
                    _buildFavoritesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDesktopLayout() => Scaffold(
        appBar: AppBar(
          title: const Text('Профиль заказчика'),
          actions: [
            ElevatedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit),
              label: const Text('Редактировать'),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareProfile,
            ),
          ],
        ),
        body: ResponsiveContainer(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Левая панель с профилем
              SizedBox(
                width: 350,
                child: _buildProfileSidebar(),
              ),
              const SizedBox(width: 24),
              // Основной контент
              Expanded(
                child: Column(
                  children: [
                    // Вкладки
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.person), text: 'О себе'),
                        Tab(icon: Icon(Icons.history), text: 'История заказов'),
                        Tab(icon: Icon(Icons.calendar_today), text: 'Важные даты'),
                        Tab(icon: Icon(Icons.favorite), text: 'Избранное'),
                      ],
                    ),
                    // Контент
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAboutTab(),
                          _buildHistoryTab(),
                          _buildDatesTab(),
                          _buildFavoritesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildLargeDesktopLayout() => Scaffold(
        appBar: AppBar(
          title: const Text('Профиль заказчика'),
          actions: [
            ElevatedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit),
              label: const Text('Редактировать'),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareProfile,
            ),
          ],
        ),
        body: ResponsiveContainer(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Левая панель с профилем
              SizedBox(
                width: 400,
                child: _buildProfileSidebar(),
              ),
              const SizedBox(width: 32),
              // Основной контент
              Expanded(
                child: Column(
                  children: [
                    // Вкладки
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.person), text: 'О себе'),
                        Tab(icon: Icon(Icons.history), text: 'История заказов'),
                        Tab(icon: Icon(Icons.calendar_today), text: 'Важные даты'),
                        Tab(icon: Icon(Icons.favorite), text: 'Избранное'),
                      ],
                    ),
                    // Контент
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAboutTab(),
                          _buildHistoryTab(),
                          _buildDatesTab(),
                          _buildFavoritesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Правая панель с дополнительной информацией
              SizedBox(
                width: 300,
                child: _buildInfoSidebar(),
              ),
            ],
          ),
        ),
      );

  Widget _buildProfileHeader() => StreamBuilder<CustomerProfile?>(
        stream: _profileService.getCustomerProfile(widget.customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6200EE), Color(0xFF3700B3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text(
                  'Ошибка загрузки профиля',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          final profile = snapshot.data!;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6200EE), Color(0xFF3700B3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 60), // Отступ для AppBar
                // Аватар и основная информация
                Row(
                  children: [
                    const SizedBox(width: 16),
                    // Аватар
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        image: profile.avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(profile.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profile.avatarUrl == null
                          ? const Icon(Icons.person, size: 40, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Информация о заказчике
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ResponsiveText(
                            profile.displayName,
                            isTitle: true,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          ResponsiveText(
                            profile.locationDisplay,
                            isSubtitle: true,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          // Статистика
                          Row(
                            children: [
                              _buildStatItem('Заказы', '${profile.totalBookings}'),
                              const SizedBox(width: 16),
                              _buildStatItem('Потрачено', profile.formattedTotalSpent),
                              const SizedBox(width: 16),
                              _buildStatItem('Рейтинг', profile.formattedRating),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Прогресс заполнения профиля
                if (profile.profileCompletionPercentage < 1.0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Заполнение профиля',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              profile.formattedCompletionPercentage,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: profile.profileCompletionPercentage,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      );

  Widget _buildProfileSidebar() => StreamBuilder<CustomerProfile?>(
        stream: _profileService.getCustomerProfile(widget.customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Ошибка загрузки профиля'));
          }

          final profile = snapshot.data!;
          return Column(
            children: [
              const SizedBox(height: 20),
              // Аватар
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  image: profile.avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(profile.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profile.avatarUrl == null
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 16),
              // Имя и статус
              ResponsiveText(
                profile.displayName,
                isTitle: true,
              ),
              const SizedBox(height: 4),
              ResponsiveText(
                profile.maritalStatusDisplay,
                isSubtitle: true,
              ),
              const SizedBox(height: 16),
              // Кнопки действий
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit),
                  label: const Text('Редактировать'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _shareProfile,
                  icon: const Icon(Icons.share),
                  label: const Text('Поделиться'),
                ),
              ),
              const SizedBox(height: 24),
              // Статистика
              _buildStatsCard(profile),
              const SizedBox(height: 24),
              // Важные даты
              _buildImportantDatesCard(profile),
            ],
          );
        },
      );

  Widget _buildStatsCard(CustomerProfile profile) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Статистика',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Всего заказов', '${profile.totalBookings}'),
            _buildStatRow('Потрачено', profile.formattedTotalSpent),
            _buildStatRow('Средний рейтинг', profile.formattedRating),
            _buildStatRow('Избранных специалистов', '${profile.favoriteSpecialists.length}'),
            _buildStatRow('Сохраненных идей', '${profile.savedIdeas.length}'),
          ],
        ),
      );

  Widget _buildImportantDatesCard(CustomerProfile profile) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ResponsiveText(
                  'Важные даты',
                  isTitle: true,
                ),
                TextButton(
                  onPressed: _viewImportantDates,
                  child: const Text('Все'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (profile.importantDates.isEmpty)
              const Text(
                'Нет важных дат',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...profile.upcomingImportantDates.take(3).map((date) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            date.title,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          date.formattedDate,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      );

  Widget _buildInfoSidebar() => Column(
        children: [
          const SizedBox(height: 20),
          _buildRecentActivityCard(),
          const SizedBox(height: 24),
          _buildPreferencesCard(),
        ],
      );

  Widget _buildRecentActivityCard() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Недавняя активность',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildActivityItem('Добавил в избранное', '2 часа назад'),
            _buildActivityItem('Оставил отзыв', '1 день назад'),
            _buildActivityItem('Забронировал услугу', '3 дня назад'),
          ],
        ),
      );

  Widget _buildPreferencesCard() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Предпочтения',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildPreferenceItem('Уведомления', 'Включены'),
            _buildPreferenceItem('Приватность', 'Средняя'),
            _buildPreferenceItem('Язык', 'Русский'),
          ],
        ),
      );

  Widget _buildAboutTab() => StreamBuilder<CustomerProfile?>(
        stream: _profileService.getCustomerProfile(widget.customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Ошибка загрузки профиля'));
          }

          final profile = snapshot.data!;
          return ResponsiveList(
            children: [
              _buildAboutSection(profile),
              _buildContactSection(profile),
              _buildFamilySection(profile),
              _buildPreferencesSection(profile),
            ],
          );
        },
      );

  Widget _buildHistoryTab() => ResponsiveList(
        children: [
          _buildHistorySection(),
        ],
      );

  Widget _buildDatesTab() => ResponsiveList(
        children: [
          _buildImportantDatesSection(),
        ],
      );

  Widget _buildFavoritesTab() => ResponsiveList(
        children: [
          _buildFavoritesSection(),
        ],
      );

  Widget _buildAboutSection(CustomerProfile profile) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'О себе',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            ResponsiveText(
              profile.bioDisplay,
              isSubtitle: true,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Возраст', profile.age?.toString() ?? 'Не указан'),
            _buildInfoRow('Местоположение', profile.locationDisplay),
            _buildInfoRow('Семейное положение', profile.maritalStatusDisplay),
            if (profile.weddingDate != null)
              _buildInfoRow('Дата свадьбы', profile.formattedWeddingDate!),
          ],
        ),
      );

  Widget _buildContactSection(CustomerProfile profile) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Контактная информация',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Телефон', profile.phoneDisplay),
            _buildInfoRow('Email', profile.emailDisplay),
            if (profile.socialLinks.isNotEmpty) ...[
              const SizedBox(height: 16),
              const ResponsiveText(
                'Социальные сети',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...profile.socialLinks.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(_getSocialIcon(entry.key), size: 16),
                        const SizedBox(width: 8),
                        Text(entry.value),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      );

  Widget _buildFamilySection(CustomerProfile profile) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Семья',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            if (profile.familyPhotos.isEmpty)
              const Text(
                'Нет семейных фотографий',
                style: TextStyle(color: Colors.grey),
              )
            else
              ResponsiveGrid(
                crossAxisCount: 3,
                children: profile.familyPhotos.map((photo) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photo,
                        width: double.infinity,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )).toList(),
              ),
          ],
        ),
      );

  Widget _buildPreferencesSection(CustomerProfile profile) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Предпочтения',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            ...profile.preferences.entries.map((entry) => _buildInfoRow(
                  entry.key,
                  entry.value.toString(),
                )),
          ],
        ),
      );

  Widget _buildHistorySection() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ResponsiveText(
                  'История заказов',
                  isTitle: true,
                ),
                TextButton(
                  onPressed: _viewBookingHistory,
                  child: const Text('Все заказы'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Здесь будет отображаться история заказов',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );

  Widget _buildImportantDatesSection() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ResponsiveText(
                  'Важные даты',
                  isTitle: true,
                ),
                TextButton(
                  onPressed: _viewImportantDates,
                  child: const Text('Управление'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Здесь будут отображаться важные даты',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );

  Widget _buildFavoritesSection() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Избранное',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Здесь будут отображаться избранные специалисты и идеи',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );

  Widget _buildStatItem(String label, String value) => Column(
        children: [
          ResponsiveText(
            value,
            isTitle: true,
            style: const TextStyle(color: Colors.white),
          ),
          ResponsiveText(
            label,
            isSubtitle: true,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      );

  Widget _buildStatRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(label, isSubtitle: true),
            ResponsiveText(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(label, isSubtitle: true),
            ResponsiveText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  Widget _buildActivityItem(String action, String time) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Icon(Icons.circle, size: 8, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: ResponsiveText(action, isSubtitle: true),
            ),
            ResponsiveText(
              time,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );

  Widget _buildPreferenceItem(String key, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(key, isSubtitle: true),
            ResponsiveText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'vk':
        return Icons.group;
      case 'telegram':
        return Icons.send;
      case 'whatsapp':
        return Icons.chat;
      default:
        return Icons.link;
    }
  }

  void _editProfile() {
    Navigator.of(context).push(
      EnhancedPageTransition(
        child: EditCustomerProfileScreen(customerId: widget.customerId),
        type: PageTransitionType.slideUp,
      ),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Профиль скопирован в буфер обмена')),
    );
  }

  void _viewBookingHistory() {
    Navigator.of(context).push(
      EnhancedPageTransition(
        child: CustomerBookingHistoryScreen(customerId: widget.customerId),
        type: PageTransitionType.slideUp,
      ),
    );
  }

  void _viewImportantDates() {
    Navigator.of(context).push(
      EnhancedPageTransition(
        child: CustomerImportantDatesScreen(customerId: widget.customerId),
        type: PageTransitionType.slideUp,
      ),
    );
  }
}

/// Делегат для SliverTabBar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: _tabBar,
      );

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
