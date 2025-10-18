import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Исправленный экран профиля с безопасной загрузкой данных
class FixedProfileScreen extends ConsumerStatefulWidget {
  const FixedProfileScreen({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
  });

  final String userId;
  final bool isOwnProfile;

  @override
  ConsumerState<FixedProfileScreen> createState() => _FixedProfileScreenState();
}

class _FixedProfileScreenState extends ConsumerState<FixedProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: widget.userId.isEmpty
          ? const Center(child: Text('Ошибка загрузки профиля'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Профиль не найден',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Назад'),
                        ),
                      ],
                    ),
                  );
                }

                final userData = snapshot.data!.data()! as Map<String, dynamic>;
                final isOwnProfile = widget.userId == currentUserId;

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildProfileContent(userData, isOwnProfile),
                );
              },
            ),
    );
  }

  Widget _buildProfileContent(
    Map<String, dynamic> userData,
    bool isOwnProfile,
  ) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(userData),
        _buildProfileInfo(userData, isOwnProfile),
        _buildStatsSection(userData),
        _buildActionButtons(userData, isOwnProfile),
        _buildBioSection(userData),
        _buildTabBar(),
        _buildTabContent(userData),
      ],
    );
  }

  Widget _buildSliverAppBar(Map<String, dynamic> userData) {
    final theme = Theme.of(context);

    return SliverAppBar(
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
                theme.primaryColor.withOpacity(0.8),
                theme.colorScheme.secondary.withOpacity(0.6),
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic> userData, bool isOwnProfile) {
    final theme = Theme.of(context);
    final name = userData['name'] as String? ?? 'Пользователь';
    final avatarUrl = userData['avatar'] as String?;
    final city = userData['city'] as String? ?? '';

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Аватар
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.primaryColor,
              backgroundImage:
                  avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // Имя
            Text(
              name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Город
            if (city.isNotEmpty)
              Text(
                city,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> userData) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('Заявки', '12', theme),
            _buildStatItem('Отзывы', '8', theme),
            _buildStatItem('Рейтинг', '4.8', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) => Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      );

  Widget _buildActionButtons(Map<String, dynamic> userData, bool isOwnProfile) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: isOwnProfile ? _editProfile : _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  isOwnProfile ? 'Редактировать' : 'Написать',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _shareProfile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(color: theme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Поделиться'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioSection(Map<String, dynamic> userData) {
    final theme = Theme.of(context);
    final about = userData['about'] as String? ?? '';

    if (about.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'О себе',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              about,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.primaryColor,
          tabs: const [
            Tab(text: 'Заявки'),
            Tab(text: 'Отзывы'),
            Tab(text: 'Портфолио'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> userData) => SliverFillRemaining(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBookingsTab(),
            _buildReviewsTab(),
            _buildPortfolioTab(),
          ],
        ),
      );

  Widget _buildBookingsTab() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Заявки',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь будут отображаться заявки',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Отзывы',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь будут отображаться отзывы',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Портфолио',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь будет отображаться портфолио',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    // TODO: Реализовать редактирование профиля
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Редактирование профиля')),
    );
  }

  void _sendMessage() {
    // TODO: Реализовать отправку сообщения
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Отправка сообщения')),
    );
  }

  void _shareProfile() {
    // TODO: Реализовать поделиться профилем
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Поделиться профилем')),
    );
  }
}

