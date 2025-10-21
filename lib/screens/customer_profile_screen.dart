import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/booking_history.dart';
import '../widgets/customer_stats.dart';
import '../widgets/favorite_specialists.dart';
import '../widgets/profile_header.dart';

/// Экран профиля заказчика
class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key, required this.userId, this.isOwnProfile = false});
  final String userId;
  final bool isOwnProfile;

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();

    // Загружаем профиль при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProfileNotifierProvider.notifier).loadProfile(widget.userId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(widget.userId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: profileAsync.when(
        data: (profile) => profile != null
            ? _buildProfileContent(profile)
            : _buildErrorWidget('Профиль не найден'),
        loading: _buildLoadingWidget,
        error: (error, stack) => _buildErrorWidget('Ошибка загрузки профиля'),
      ),
    );
  }

  Widget _buildProfileContent(UserProfile profile) => NestedScrollView(
    controller: _scrollController,
    headerSliverBuilder: (context, innerBoxIsScrolled) => [
      _buildSliverAppBar(profile),
      _buildProfileHeader(profile),
      _buildStatsSection(profile),
      _buildTabBar(),
    ],
    body: TabBarView(
      controller: _tabController,
      children: [
        BookingHistory(userId: widget.userId),
        FavoriteSpecialists(userId: widget.userId),
        _buildAnniversariesTab(profile),
        _buildSettingsTab(profile),
      ],
    ),
  );

  Widget _buildSliverAppBar(UserProfile profile) => SliverAppBar(
    expandedHeight: 200,
    pinned: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.7),
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Обложка профиля
            if (profile.coverUrl.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: profile.coverUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                  errorWidget: (context, url, error) =>
                      Container(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                ),
              ),
            // Градиент поверх обложки
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.of(context).pop(),
    ),
    actions: [
      if (widget.isOwnProfile) ...[
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () => _editProfile(profile),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showProfileMenu(profile),
        ),
      ] else ...[
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () => _shareProfile(profile),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showProfileMenu(profile),
        ),
      ],
    ],
  );

  Widget _buildProfileHeader(UserProfile profile) => SliverToBoxAdapter(
    child: ProfileHeader(
      profile: profile,
      isOwnProfile: widget.isOwnProfile,
      onFollow: () => _toggleFollow(profile),
      onMessage: () => _sendMessage(profile),
    ),
  );

  Widget _buildStatsSection(UserProfile profile) =>
      SliverToBoxAdapter(child: CustomerStats(userId: widget.userId));

  Widget _buildTabBar() => SliverPersistentHeader(
    pinned: true,
    delegate: _TabBarDelegate(
      TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.history), text: 'Заказы'),
          Tab(icon: Icon(Icons.favorite), text: 'Избранные'),
          Tab(icon: Icon(Icons.event), text: 'Годовщины'),
          Tab(icon: Icon(Icons.settings), text: 'Настройки'),
        ],
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
      ),
    ),
  );

  Widget _buildAnniversariesTab(UserProfile profile) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.event, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('Годовщины и напоминания', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Здесь будут отображаться важные даты\nи напоминания о событиях',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildSettingsTab(UserProfile profile) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _buildSettingsSection('Профиль', [
        _buildSettingsItem(Icons.person, 'Редактировать профиль', () => _editProfile(profile)),
        _buildSettingsItem(Icons.notifications, 'Уведомления', _openNotificationsSettings),
        _buildSettingsItem(Icons.privacy_tip, 'Приватность', _openPrivacySettings),
      ]),
      const SizedBox(height: 24),
      _buildSettingsSection('Приложение', [
        _buildSettingsItem(Icons.help, 'Помощь', _openHelp),
        _buildSettingsItem(Icons.info, 'О приложении', _openAbout),
        _buildSettingsItem(Icons.logout, 'Выйти', _logout, isDestructive: true),
      ]),
    ],
  );

  Widget _buildSettingsSection(String title, List<Widget> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: items),
      ),
    ],
  );

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) => ListTile(
    leading: Icon(icon, color: isDestructive ? Colors.red : null),
    title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : null)),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: onTap,
  );

  Widget _buildLoadingWidget() => Scaffold(
    appBar: AppBar(
      title: const Text('Профиль заказчика'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: const Center(child: CircularProgressIndicator()),
  );

  Widget _buildErrorWidget(String message) => Scaffold(
    appBar: AppBar(
      title: const Text('Профиль заказчика'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(userProfileNotifierProvider.notifier).loadProfile(widget.userId);
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    ),
  );

  void _editProfile(UserProfile profile) {
    // TODO(developer): Навигация к экрану редактирования профиля
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Редактирование профиля')));
  }

  void _showProfileMenu(UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isOwnProfile) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Редактировать профиль'),
                onTap: () {
                  Navigator.pop(context);
                  _editProfile(profile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Настройки'),
                onTap: () {
                  Navigator.pop(context);
                  _tabController.animateTo(3); // Переход к вкладке настроек
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Поделиться'),
                onTap: () {
                  Navigator.pop(context);
                  _shareProfile(profile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Пожаловаться'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO(developer): Показать диалог жалобы
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _shareProfile(UserProfile profile) {
    // TODO(developer): Реализовать функциональность шаринга
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Поделиться профилем')));
  }

  void _toggleFollow(UserProfile profile) {
    // TODO(developer): Реализовать подписку/отписку
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Подписка/отписка')));
  }

  void _sendMessage(UserProfile profile) {
    // TODO(developer): Навигация к чату
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Отправить сообщение')));
  }

  void _openNotificationsSettings() {
    // TODO(developer): Открыть настройки уведомлений
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Настройки уведомлений')));
  }

  void _openPrivacySettings() {
    // TODO(developer): Открыть настройки приватности
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Настройки приватности')));
  }

  void _openHelp() {
    // TODO(developer): Открыть справку
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Справка')));
  }

  void _openAbout() {
    // TODO(developer): Открыть информацию о приложении
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('О приложении')));
  }

  void _logout() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO(developer): Реализовать выход из аккаунта
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Выход из аккаунта')));
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}

/// Делегат для TabBar в SliverPersistentHeader
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
