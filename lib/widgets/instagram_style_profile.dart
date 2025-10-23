import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/specialist.dart';
import '../services/test_data_service.dart';
import '../theme/app_theme.dart';

/// Профиль специалиста в стиле Instagram
class InstagramStyleProfile extends ConsumerStatefulWidget {
  const InstagramStyleProfile({super.key, required this.specialistId});

  final String specialistId;

  @override
  ConsumerState<InstagramStyleProfile> createState() =>
      _InstagramStyleProfileState();
}

class _InstagramStyleProfileState extends ConsumerState<InstagramStyleProfile>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TestDataService _testDataService = TestDataService();

  Specialist? _specialist;
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSpecialist();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialist() async {
    try {
      // Используем тестовые данные
      final specialists = _testDataService.getSpecialists();
      final specialistData = specialists.first; // Используем первого для демо
      final specialist = Specialist.fromMap(specialistData);

      setState(() {
        _specialist = specialist;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_specialist == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Профиль специалиста'),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop()),
        ),
        body: const Center(child: Text('Специалист не найден')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileHeader(),
                _buildStoriesSection(),
                _buildContactsSection(),
                _buildTabBar(),
                _buildTabContent(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() => SliverAppBar(
        expandedHeight: 0,
        floating: true,
        pinned: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _specialist!.displayName,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: _showOptionsMenu,
          ),
        ],
      );

  Widget _buildProfileHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Аватар
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: BrandColors.primary.withValues(alpha: 0.1),
                    backgroundImage: _specialist!.imageUrlValue != null
                        ? NetworkImage(_specialist!.imageUrlValue!)
                        : null,
                    child: _specialist!.imageUrlValue == null
                        ? Text(
                            _specialist!.name.isNotEmpty
                                ? _specialist!.name[0].toUpperCase()
                                : 'С',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: BrandColors.primary,
                            ),
                          )
                        : null,
                  ),
                ),

                const SizedBox(width: 20),

                // Статистика
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Посты', '12'),
                      _buildStatColumn('Подписчики', '1.2K'),
                      _buildStatColumn('Подписки', '89'),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Информация о специалисте
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _specialist!.displayName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _specialist!.category.toString(),
                  style: const TextStyle(
                      fontSize: 14, color: BrandColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  _specialist!.description?.isNotEmpty == true
                      ? _specialist!.description!
                      : 'Опытный специалист в области ${_specialist!.category.toString().toLowerCase()}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isFollowing = !_isFollowing;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing
                          ? Colors.grey.shade200
                          : BrandColors.primary,
                      foregroundColor:
                          _isFollowing ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_isFollowing ? 'Подписки' : 'Подписаться'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Реализовать сообщение
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Сообщение'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    // TODO: Реализовать звонок
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Icon(Icons.phone),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatColumn(String label, String value) => Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: BrandColors.textSecondary)),
        ],
      );

  Widget _buildStoriesSection() => Container(
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 8, // Демо количество сторис
          itemBuilder: (context, index) => Container(
            width: 70,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: index == 0
                          ? Colors.grey.shade300
                          : BrandColors.primary,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: BrandColors.primary.withValues(alpha: 0.1),
                    child: index == 0
                        ? const Icon(Icons.add, color: BrandColors.primary)
                        : Text(
                            '$index',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BrandColors.primary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  index == 0 ? 'Добавить' : 'История $index',
                  style: const TextStyle(
                      fontSize: 12, color: BrandColors.textSecondary),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildContactsSection() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BrandColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Контакты и цены',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: BrandColors.textSecondary),
                const SizedBox(width: 8),
                Text(_specialist!.city ?? '',
                    style: const TextStyle(color: BrandColors.textSecondary)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: BrandColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(_specialist!.pricePerHour ?? 0).toInt()}₽/ч',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: BrandColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '${_specialist!.rating} (${_specialist!.reviewCount} отзывов)',
                  style: const TextStyle(color: BrandColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildTabBar() => Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(icon: Icon(Icons.grid_on)),
            Tab(icon: Icon(Icons.video_library)),
            Tab(icon: Icon(Icons.person_pin)),
          ],
        ),
      );

  Widget _buildTabContent() => SizedBox(
        height: 400,
        child: TabBarView(
          controller: _tabController,
          children: [_buildPostsGrid(), _buildVideosGrid(), _buildTaggedGrid()],
        ),
      );

  Widget _buildPostsGrid() => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 12,
        itemBuilder: (context, index) => Container(
          color: BrandColors.primary.withValues(alpha: 0.1),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: BrandColors.primary,
              ),
            ),
          ),
        ),
      );

  Widget _buildVideosGrid() => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          color: BrandColors.secondary.withValues(alpha: 0.1),
          child: const Center(
            child: Icon(Icons.play_circle_outline,
                size: 32, color: BrandColors.secondary),
          ),
        ),
      );

  Widget _buildTaggedGrid() => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          color: BrandColors.accent.withValues(alpha: 0.1),
          child: Center(
            child: Text(
              'T${index + 1}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: BrandColors.accent,
              ),
            ),
          ),
        ),
      );

  Widget _buildBottomBar() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Реализовать бронирование
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Забронировать'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Реализовать избранное
              },
              icon: const Icon(Icons.favorite_border),
              label: const Text('В избранное'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      );

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Поделиться'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Реализовать поделиться
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Пожаловаться'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Реализовать жалобу
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Заблокировать'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Реализовать блокировку
              },
            ),
          ],
        ),
      ),
    );
  }
}
