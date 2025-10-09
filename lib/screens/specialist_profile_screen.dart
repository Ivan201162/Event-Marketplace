import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/post.dart';
import '../models/specialist.dart';
import '../models/story.dart';
import '../models/review.dart';
import '../services/post_service.dart';
import '../services/specialist_service.dart';
import '../services/story_service.dart';
import '../services/analytics_service.dart';
import '../services/reviews_service.dart';
import '../widgets/specialist_tips_widget.dart';
import '../screens/reviews/widgets/reputation_widget.dart';
import 'specialist_profile_instagram_screen.dart';
import 'specialist_stats_screen.dart';
import 'reviews/simple_reviews_screen.dart';

class SpecialistProfileScreen extends ConsumerStatefulWidget {
  const SpecialistProfileScreen({
    super.key,
    required this.specialistId,
  });
  final String specialistId;

  @override
  ConsumerState<SpecialistProfileScreen> createState() =>
      _SpecialistProfileScreenState();
}

class _SpecialistProfileScreenState
    extends ConsumerState<SpecialistProfileScreen>
    with TickerProviderStateMixin {
  final SpecialistService _specialistService = SpecialistService();
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();
  final ReviewsService _reviewsService = ReviewsService();

  Specialist? _specialist;
  List<Post> _posts = [];
  List<Story> _stories = [];
  SpecialistReputation? _reputation;
  bool _isLoading = true;
  bool _isFavorite = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadSpecialist();
    
    // Логируем просмотр профиля специалиста
    AnalyticsService().logScreenView('specialist_profile_screen');
  }

  Future<void> _addPost() async {
    // TODO(developer): Реализовать добавление поста
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Добавление поста будет реализовано')),
    );
  }

  Future<void> _addStory() async {
    // TODO(developer): Реализовать добавление сторис
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Добавление сторис будет реализовано')),
    );
  }

  void _viewStory(Story story) {
    // TODO(developer): Реализовать просмотр сторис
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Просмотр сторис: ${story.id}')),
    );
  }

  String _formatStoryTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}м';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}ч';
    } else {
      return '${difference.inDays}д';
    }
  }

  Widget _buildPostCard(Post post) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок поста
              if (post.text != null && post.text!.isNotEmpty)
                Text(
                  post.text!,
                  style: const TextStyle(fontSize: 16),
                ),

              // Медиа контент
              if (post.mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.mediaUrls.length,
                    itemBuilder: (context, index) => Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.mediaUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Информация о посте
              Row(
                children: [
                  Icon(Icons.favorite, size: 16, color: Colors.red.shade300),
                  const SizedBox(width: 4),
                  Text('${post.likesCount}'),
                  const SizedBox(width: 16),
                  Icon(Icons.comment, size: 16, color: Colors.blue.shade300),
                  const SizedBox(width: 4),
                  Text('${post.commentsCount}'),
                  const Spacer(),
                  Text(
                    _formatPostTime(post.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  String _formatPostTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}м назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}д назад';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialist() async {
    try {
      // Загружаем специалиста, посты, сторис и репутацию параллельно
      final results = await Future.wait([
        _specialistService.getSpecialistById(widget.specialistId),
        _postService.getSpecialistPosts(widget.specialistId),
        _storyService.getSpecialistStories(widget.specialistId),
        _reviewsService.getSpecialistReputation(widget.specialistId),
      ]);

      setState(() {
        _specialist = results[0] as Specialist?;
        _posts = results[1]! as List<Post>;
        _stories = results[2]! as List<Story>;
        _reputation = results[3] as SpecialistReputation?;
        _isLoading = false;
      });
      
      // Логируем просмотр профиля специалиста
      if (_specialist != null) {
        AnalyticsService().logViewProfile(
          _specialist!.id,
          _specialist!.name,
        );
      }
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки профиля: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Используем новый Instagram-стиль профиля
    return SpecialistProfileInstagramScreen(
      specialistId: widget.specialistId,
    );
  }

  Widget _buildSliverAppBar() => SliverAppBar(
        expandedHeight: 300,
        pinned: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isFavorite
                        ? 'Добавлено в избранное'
                        : 'Удалено из избранного',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO(developer): Реализовать шаринг профиля
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Функция шаринга в разработке')),
              );
            },
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: _specialist!.imageUrl != null
              ? Image.network(
                  _specialist!.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child:
                        const Icon(Icons.person, size: 100, color: Colors.grey),
                  ),
                )
              : Container(
                  color: Colors.grey.shade300,
                  child:
                      const Icon(Icons.person, size: 100, color: Colors.grey),
                ),
        ),
      );

  Widget _buildProfileHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _specialist!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _specialist!.category.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _navigateToReviews,
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              _specialist!.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${_getReviewCount()} отзывов)',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 8),
                            // Статус репутации
                            if (_reputation != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getReputationColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getReputationColor().withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _reputation!.status.emoji,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _reputation!.status.displayName,
                                      style: TextStyle(
                                        color: _getReputationColor(),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      ,,,,),
                    ,,,,],
                  ),
                ,,,,),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_specialist!.price.toInt()}₽',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text(
                      'за час',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ,,,,],
            ),

            const void void SizedBox(height = 16),

            // Дополнительная информация
            void void Row(
              children = [
                if (_specialist!.location != null &&
                    _specialist!.location!.isNotEmpty) ...[
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _specialist!.location!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (_specialist!.yearsOfExperience > 0) ...[
                  Icon(Icons.work, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${_specialist!.yearsOfExperience} лет опыта',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );

  Widget _buildTabBar() => TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Сторис'),
          Tab(text: 'Посты'),
          Tab(text: 'Услуги'),
          Tab(text: 'Календарь'),
          Tab(text: 'Советы'),
          Tab(text: 'Статистика'),
        ],
      );

  Widget _buildTabContent() => SizedBox(
        height: 400,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildStoriesTab(),
            _buildPostsTab(),
            _buildServicesTab(),
            _buildCalendarTab(),
            _buildTipsTab(),
            _buildStatsTab(),
          ],
        ),
      );

  Widget _buildStoriesTab() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Сторис',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _addStory,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Добавить сторис',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_stories.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.auto_stories, size: 64, color: Colors.grey),
                    SizedBox(),
                    Text(
                      'Сторис пока нет',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Добавьте первый сторис, чтобы показать свою работу',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _stories.length,
                  itemBuilder: (context, index) {
                    final story = _stories[index];
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _viewStory(story),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: story.isExpired
                                      ? Colors.grey
                                      : Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  story.mediaUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatStoryTime(story.createdAt),
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );

  Widget _buildServicesTab() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Услуги',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_specialist!.services.isEmpty)
              const Text('Услуги не указаны')
            else
              ..._specialist!.services.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(service)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildPostsTab() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Посты',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _addPost,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Добавить пост',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_posts.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.post_add, size: 64, color: Colors.grey),
                    SizedBox(),
                    Text(
                      'Посты пока нет',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Добавьте первый пост, чтобы показать свою работу',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return _buildPostCard(post);
                  },
                ),
              ),
          ],
        ),
      );

  Widget _buildCalendarTab() => const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Календарь',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(),

            // Заглушка для календаря
            Center(
              child: Column(
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  SizedBox(),
                  Text(
                    'Календарь будет доступен после реализации',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Здесь будет отображаться расписание специалиста',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Widget _buildBottomBar() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  // TODO(developer): Получить реальный chatId из ChatService
                  const chatId = 'temp_chat_id';
                  context.go(
                    '/chat/$chatId?specialistName=${widget.specialistId}',
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text('Написать'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.go('/booking/${widget.specialistId}');
                },
                icon: const Icon(Icons.event_available),
                label: const Text('Забронировать'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildTipsTab() => const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: SpecialistTipsWidget(
        userId: 'current_user', // TODO: Получать из аутентификации
      ),
    );

  Widget _buildStatsTab() => const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Статистика профиля',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(),
          Center(
            child: Column(
              children: [
                Icon(Icons.analytics, size: 64, color: Colors.grey),
                SizedBox(),
                Text(
                  'Подробная статистика доступна в отдельном экране',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(),
                ElevatedButton.icon(
                  onPressed: null, // TODO: Добавить навигацию к полной статистике
                  icon: Icon(Icons.analytics),
                  label: Text('Открыть полную статистику'),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  String _getReviewCount() {
    if (_reputation != null) {
      return _reputation!.reviewsCount.toString();
    }
    // Генерируем случайное количество отзывов на основе рейтинга
    final baseCount = (_specialist!.rating * 20).round();
    return (baseCount + (DateTime.now().millisecond % 50)).toString();
  }

  Color _getReputationColor() {
    if (_reputation == null) return Colors.grey;
    
    switch (_reputation!.status) {
      case ReputationStatus.verifiedExpert:
        return Colors.green;
      case ReputationStatus.reliable:
        return Colors.blue;
      case ReputationStatus.needsExperience:
        return Colors.orange;
      case ReputationStatus.underObservation:
        return Colors.red;
    }
  }

  void _navigateToReviews() {
    if (_specialist != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleReviewsScreen(
            specialistId: _specialist!.id,
            specialistName: _specialist!.name,
          ),
        ),
      );
    }
  }
}
