import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Улучшенный экран профиля пользователя
class ProfileScreenEnhanced extends ConsumerStatefulWidget {

  const ProfileScreenEnhanced({super.key, this.userId});
  final String? userId;

  @override
  ConsumerState<ProfileScreenEnhanced> createState() =>
      _ProfileScreenEnhancedState();
}

class _ProfileScreenEnhancedState extends ConsumerState<ProfileScreenEnhanced>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _tabController = TabController(length: 4, vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ),);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final isOwnProfile =
        widget.userId == null || widget.userId == user.value?.uid;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF60A5FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Заголовок профиля
              _buildProfileHeader(isOwnProfile),

              // Основной контент
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildProfileContent(user, isOwnProfile),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Заголовок профиля
  Widget _buildProfileHeader(bool isOwnProfile) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Кнопка назад
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Заголовок
          const Text(
            'Профиль',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // Действия
          if (isOwnProfile) ...[
            IconButton(
              onPressed: _showProfileOptions,
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 24,
              ),
            ),
          ] else ...[
            IconButton(
              onPressed: _showUserOptions,
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Основной контент профиля
  Widget _buildProfileContent(AsyncValue user, bool isOwnProfile) {
    return user.when(
      data: (userData) {
        if (userData == null) {
          return _buildErrorState('Пользователь не найден');
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Информация о пользователе
              _buildUserInfo(userData, isOwnProfile),

              const SizedBox(height: 24),

              // Статистика
              _buildUserStats(userData),

              const SizedBox(height: 24),

              // Действия
              if (isOwnProfile)
                _buildOwnProfileActions()
              else
                _buildOtherProfileActions(),

              const SizedBox(height: 24),

              // Вкладки профиля
              _buildProfileTabs(userData, isOwnProfile),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
      loading: _buildLoadingState,
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  /// Информация о пользователе
  Widget _buildUserInfo(dynamic userData, bool isOwnProfile) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Аватар
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                child: userData.avatarUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: userData.avatarUrl!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          placeholder: (context, url) => ShimmerBox(
                            width: 120,
                            height: 120,
                            borderRadius: 60,
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 60,
                      ),
              ),
              if (isOwnProfile)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _changeAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E3A8A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Имя пользователя
          if (_isEditing && isOwnProfile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Введите имя',
                  border: InputBorder.none,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(
              userData.name ?? 'Пользователь',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),

          const SizedBox(height: 8),

          // Био
          if (_isEditing && isOwnProfile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _bioController,
                decoration: const InputDecoration(
                  hintText: 'Расскажите о себе',
                  border: InputBorder.none,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
            )
          else
            Text(
              userData.bio ?? 'Пользователь Event Marketplace',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 8),

          // Город
          if (_isEditing && isOwnProfile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  hintText: 'Введите город',
                  border: InputBorder.none,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  userData.city ?? 'Город не указан',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Статистика пользователя
  Widget _buildUserStats(dynamic userData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              title: 'Идеи',
              value: '${userData.ideasCount ?? 0}',
              icon: Icons.lightbulb_outline,
              color: Colors.orange,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              title: 'Заявки',
              value: '${userData.requestsCount ?? 0}',
              icon: Icons.assignment_outlined,
              color: Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              title: 'Подписчики',
              value: '${userData.followersCount ?? 0}',
              icon: Icons.people_outline,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  /// Элемент статистики
  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Действия для собственного профиля
  Widget _buildOwnProfileActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isEditing ? _saveProfile : _editProfile,
                  icon: Icon(_isEditing ? Icons.save : Icons.edit),
                  label: Text(_isEditing ? 'Сохранить' : 'Редактировать'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.go('/settings');
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Настройки'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Действия для чужого профиля
  Widget _buildOtherProfileActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startChat,
              icon: const Icon(Icons.chat),
              label: const Text('Написать'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _followUser,
              icon: const Icon(Icons.person_add),
              label: const Text('Подписаться'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A8A),
                side: const BorderSide(color: Color(0xFF1E3A8A)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Контент пользователя
  Widget _buildUserContent(dynamic userData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Активность',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),

          const SizedBox(height: 16),

          // Заглушка для контента
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.timeline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Активность появится здесь',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Идеи, заявки и другие действия пользователя',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Состояние загрузки
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загрузка профиля...'),
        ],
      ),
    );
  }

  /// Состояние ошибки
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  /// Показать опции профиля
  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
              leading: const Icon(Icons.settings),
              title: const Text('Настройки'),
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Безопасность'),
              onTap: () {
                Navigator.pop(context);
                _showSecurityOptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text('Монетизация'),
              onTap: () {
                Navigator.pop(context);
                context.go('/monetization');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Выйти', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Показать опции пользователя
  void _showUserOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Написать сообщение'),
              onTap: () {
                Navigator.pop(context);
                _startChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Подписаться'),
              onTap: () {
                Navigator.pop(context);
                _followUser();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Поделиться профилем'),
              onTap: () {
                Navigator.pop(context);
                _shareProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Пожаловаться',
                  style: TextStyle(color: Colors.red),),
              onTap: () {
                Navigator.pop(context);
                _reportUser();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Редактировать профиль
  void _editProfile() {
    setState(() {
      _isEditing = true;
      _nameController.text = ref.read(authStateProvider).value?.name ?? '';
      _bioController.text = ref.read(authStateProvider).value?.bio ?? '';
      _cityController.text = ref.read(authStateProvider).value?.city ?? '';
    });
  }

  /// Сохранить профиль
  Future<void> _saveProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'city': _cityController.text.trim(),
        'updatedAt': Timestamp.now(),
      });

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профиль обновлен'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Изменить аватар
  void _changeAvatar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Смена аватара будет реализована'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Начать чат
  void _startChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Чат будет реализован'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Подписаться на пользователя
  void _followUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Подписка будет реализована'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Поделиться профилем
  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Шаринг будет реализован'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Пожаловаться на пользователя
  void _reportUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Жалоба будет реализована'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Показать опции безопасности
  void _showSecurityOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Безопасность будет реализована'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Выйти из аккаунта
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка выхода: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Вкладки профиля в стиле Instagram
  Widget _buildProfileTabs(dynamic userData, bool isOwnProfile) {
    return Column(
      children: [
        // TabBar
        TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1E3A8A),
          labelColor: const Color(0xFF1E3A8A),
          unselectedLabelColor: Colors.grey[600],
          tabs: const [
            Tab(icon: Icon(Icons.grid_on)),
            Tab(icon: Icon(Icons.video_library)),
            Tab(icon: Icon(Icons.bookmark_border)),
            Tab(icon: Icon(Icons.emoji_events)),
          ],
        ),

        // TabBarView
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsTab(userData),
              _buildReelsTab(userData),
              _buildMediaTab(userData),
              _buildAchievementsTab(userData),
            ],
          ),
        ),
      ],
    );
  }

  /// Вкладка постов
  Widget _buildPostsTab(dynamic userData) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 12, // Заглушка
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.image, color: Colors.grey),
        );
      },
    );
  }

  /// Вкладка рилсов
  Widget _buildReelsTab(dynamic userData) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 8, // Заглушка
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.play_circle_outline, color: Colors.grey),
        );
      },
    );
  }

  /// Вкладка медиа
  Widget _buildMediaTab(dynamic userData) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 6, // Заглушка
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.photo_library, color: Colors.grey),
        );
      },
    );
  }

  /// Вкладка достижений
  Widget _buildAchievementsTab(dynamic userData) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Заглушка
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.emoji_events, color: Colors.orange),
            title: Text('Достижение ${index + 1}'),
            subtitle: const Text('Описание достижения'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }
}
