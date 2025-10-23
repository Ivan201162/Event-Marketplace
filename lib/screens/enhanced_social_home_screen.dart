import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/social_models.dart';
import '../services/supabase_service.dart';
import '../widgets/animated_profile_banner.dart';
import '../widgets/filters_dialog.dart';
import '../widgets/weekly_leaders_widget.dart';

/// Улучшенный главный экран с профилем, фильтрами и топом специалистов
class EnhancedSocialHomeScreen extends ConsumerStatefulWidget {
  const EnhancedSocialHomeScreen({super.key});

  @override
  ConsumerState<EnhancedSocialHomeScreen> createState() =>
      _EnhancedSocialHomeScreenState();
}

class _EnhancedSocialHomeScreenState
    extends ConsumerState<EnhancedSocialHomeScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _profileAnimationController;
  late Animation<double> _profileAnimation;

  Profile? _currentProfile;
  List<WeeklyLeader> _weeklyLeaders = [];
  bool _isLoadingProfile = true;
  bool _isLoadingLeaders = true;
  bool _showProfileBanner = true;
  String? _selectedCity;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _profileAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
        parent: _profileAnimationController, curve: Curves.easeInOut));

    _scrollController.addListener(_onScroll);
    _loadCurrentProfile();
    _loadWeeklyLeaders();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _profileAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && _showProfileBanner) {
      setState(() {
        _showProfileBanner = false;
      });
      _profileAnimationController.reverse();
    } else if (_scrollController.offset <= 100 && !_showProfileBanner) {
      setState(() {
        _showProfileBanner = true;
      });
      _profileAnimationController.forward();
    }
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser != null) {
        final profile = await SupabaseService.getProfile(currentUser.id);
        setState(() {
          _currentProfile = profile;
          _isLoadingProfile = false;
        });
        _profileAnimationController.forward();
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadWeeklyLeaders() async {
    try {
      final leaders =
          await SupabaseService.getWeeklyLeaders(city: _selectedCity);
      setState(() {
        _weeklyLeaders = leaders;
        _isLoadingLeaders = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLeaders = false;
      });
    }
  }

  Future<void> _showFiltersDialog() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => FiltersDialog(
          selectedCity: _selectedCity, selectedCategory: _selectedCategory),
    );

    if (result != null) {
      setState(() {
        _selectedCity = result['city'];
        _selectedCategory = result['category'];
      });
      _loadWeeklyLeaders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: theme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Event Marketplace',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.8)
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: _showFiltersDialog,
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),

          // Profile Banner (анимированный)
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _profileAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -50 * (1 - _profileAnimation.value)),
                  child: Opacity(
                      opacity: _profileAnimation.value,
                      child: _buildProfileBanner()),
                );
              },
            ),
          ),

          // Search Section
          SliverToBoxAdapter(child: _buildSearchSection()),

          // Quick Actions
          SliverToBoxAdapter(child: _buildQuickActions()),

          // Weekly Leaders Section
          SliverToBoxAdapter(child: _buildWeeklyLeadersSection()),

          // Ideas Feed
          SliverToBoxAdapter(child: _buildIdeasFeed()),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildProfileBanner() {
    if (_isLoadingProfile) {
      return Container(
        height: 120,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentProfile == null) {
      return Container(
        height: 120,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 32, color: Colors.grey),
              const SizedBox(height: 8),
              const Text(
                'Создайте профиль',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => context.push('/profile/edit'),
                child: const Text('Настроить'),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedProfileBanner(
      profile: _currentProfile!,
      onTap: () => context.push('/profile/me'),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Найти специалистов',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск по имени, навыкам, городу...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                  icon: const Icon(Icons.tune), onPressed: _showFiltersDialog),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                context.push('/search', extra: {'query': value});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Быстрые действия',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.add_circle_outline,
                  title: 'Создать заявку',
                  subtitle: 'Найти исполнителя',
                  color: Colors.blue,
                  onTap: () => context.push('/requests/create'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.photo_camera_outlined,
                  title: 'Поделиться',
                  subtitle: 'Добавить пост',
                  color: Colors.green,
                  onTap: () => context.push('/ideas/create'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'Сообщения',
                  subtitle: 'Общение',
                  color: Colors.orange,
                  onTap: () => context.push('/chats'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.people_outline,
                  title: 'Специалисты',
                  subtitle: 'Топ недели',
                  color: Colors.purple,
                  onTap: () => context.push('/specialists'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: color),
            ),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 12, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyLeadersSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Топ специалистов недели',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                  onPressed: () => context.push('/specialists'),
                  child: const Text('Все')),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingLeaders)
            const Center(child: CircularProgressIndicator())
          else if (_weeklyLeaders.isEmpty)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 32, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Пока нет данных',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            WeeklyLeadersWidget(
              leaders: _weeklyLeaders,
              onLeaderTap: (leader) =>
                  context.push('/profile/${leader.userId}'),
            ),
        ],
      ),
    );
  }

  Widget _buildIdeasFeed() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Последние идеи',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                  onPressed: () => context.push('/ideas'),
                  child: const Text('Все')),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline, size: 32, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Идеи появятся здесь',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
