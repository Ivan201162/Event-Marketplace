import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/post.dart';
import '../models/specialist.dart';
import '../models/story.dart';
import '../services/post_service.dart';
import '../services/specialist_service.dart';
import '../services/story_service.dart';
import '../widgets/back_button_handler.dart';
import '../widgets/instagram_post_viewer.dart';
import '../widgets/instagram_story_viewer.dart';

class SpecialistProfileInstagramScreen extends ConsumerStatefulWidget {
  const SpecialistProfileInstagramScreen(
      {super.key, required this.specialistId});
  final String specialistId;

  @override
  ConsumerState<SpecialistProfileInstagramScreen> createState() =>
      _SpecialistProfileInstagramScreenState();
}

class _SpecialistProfileInstagramScreenState
    extends ConsumerState<SpecialistProfileInstagramScreen>
    with TickerProviderStateMixin {
  final SpecialistService _specialistService = SpecialistService();
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();

  Specialist? _specialist;
  List<Post> _posts = [];
  List<Story> _stories = [];
  bool _isLoading = true;
  bool _isFavorite = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSpecialist();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialist() async {
    try {
      // Загружаем специалиста, посты и сторис параллельно
      final results = await Future.wait([
        _specialistService.getSpecialistById(widget.specialistId),
        _postService.getSpecialistPosts(widget.specialistId),
        _storyService.getSpecialistStories(widget.specialistId),
      ]);

      setState(() {
        _specialist = results[0] as Specialist?;
        _posts = results[1]! as List<Post>;
        _stories = results[2]! as List<Story>;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка загрузки профиля: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addPost() async {
    // TODO(developer): Реализовать добавление поста
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Добавление поста будет реализовано')));
  }

  Future<void> _addStory() async {
    // TODO(developer): Реализовать добавление сторис
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Добавление сторис будет реализовано')));
  }

  void _viewStory(Story story) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => InstagramStoryViewer(
          stories: _stories,
          initialIndex: _stories.indexOf(story),
          specialist: _specialist!,
        ),
      ),
    );
  }

  void _viewPost(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            InstagramPostViewer(post: post, specialist: _specialist!),
      ),
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

  Widget _buildStoryCircle(Story story, {bool isAddButton = false}) {
    if (isAddButton) {
      return GestureDetector(
        onTap: _addStory,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade400, width: 2),
            color: Colors.grey.shade100,
          ),
          child: const Icon(Icons.add, color: Colors.grey, size: 30),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _viewStory(story),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: story.isExpired ? Colors.grey : Colors.blue, width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            story.mediaUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildPostGrid() {
    if (_posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_on, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Публикаций пока нет',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Поделитесь своими работами с клиентами',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return GestureDetector(
          onTap: () => _viewPost(post),
          child: Container(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            child: post.mediaUrls.isNotEmpty
                ? Image.network(
                    post.mediaUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image, color: Colors.grey),
                  )
                : const Icon(Icons.image, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildServicesList() {
    if (_specialist!.servicesWithPrices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Услуги не указаны',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text('Добавьте свои услуги и цены',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _specialist!.servicesWithPrices.length,
      itemBuilder: (context, index) {
        final service =
            _specialist!.servicesWithPrices.entries.elementAt(index);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(service.key),
            trailing: Text(
              '${service.value.toInt()}₽',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactsSection() {
    if (_specialist!.contacts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Контакты',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._specialist!.contacts.entries.map((contact) {
            IconData icon;
            switch (contact.key.toLowerCase()) {
              case 'phone':
              case 'телефон':
                icon = Icons.phone;
                break;
              case 'email':
              case 'почта':
                icon = Icons.email;
                break;
              case 'instagram':
                icon = Icons.camera_alt;
                break;
              case 'vk':
              case 'вконтакте':
                icon = Icons.group;
                break;
              case 'telegram':
                icon = Icons.send;
                break;
              default:
                icon = Icons.link;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(contact.value,
                          style: const TextStyle(fontSize: 14))),
                ],
              ),
            );
          }),
        ],
      ),
    );
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

    return BackButtonHandler(
      child: Scaffold(
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
      ),
    );
  }

  Widget _buildSliverAppBar() => SliverAppBar(
        expandedHeight: 200,
        pinned: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorite
                      ? 'Добавлено в избранное'
                      : 'Удалено из избранного'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(
                  content: Text('Функция шаринга в разработке')));
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
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _specialist!.category.displayName,
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade600),
                      ),
                      if (_specialist!.location != null &&
                          _specialist!.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              _specialist!.location!,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: ClipOval(
                        child: _specialist!.imageUrl != null
                            ? Image.network(
                                _specialist!.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person,
                                        size: 40, color: Colors.grey),
                              )
                            : const Icon(Icons.person,
                                size: 40, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Статистика
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('${_posts.length}', 'Публикаций'),
                _buildStatColumn(
                    _specialist!.rating.toStringAsFixed(1), 'Рейтинг'),
                _buildStatColumn(_getReviewCount(), 'Отзывов'),
              ],
            ),

            const SizedBox(height: 16),

            // Описание
            if (_specialist!.description != null &&
                _specialist!.description!.isNotEmpty) ...[
              Text(_specialist!.description!,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
            ],

            // Цена
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attach_money,
                      color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'от ${_specialist!.price.toInt()}₽/час',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildStatColumn(String value, String label) => Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      );

  Widget _buildStoriesSection() => Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _stories.length + 1, // +1 для кнопки добавления
          itemBuilder: (context, index) {
            if (index == _stories.length) {
              // Кнопка добавления сторис
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    _buildStoryCircle(
                      _stories.isNotEmpty
                          ? _stories.first
                          : Story.create(
                              id: '', specialistId: '', mediaUrl: ''),
                      isAddButton: true,
                    ),
                    const SizedBox(height: 4),
                    const Text('Добавить',
                        style: TextStyle(fontSize: 10),
                        textAlign: TextAlign.center),
                  ],
                ),
              );
            }

            final story = _stories[index];
            return Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  _buildStoryCircle(story),
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
      );

  Widget _buildTabBar() => Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(icon: Icon(Icons.grid_on), text: 'Публикации'),
            Tab(icon: Icon(Icons.list_alt), text: 'Услуги'),
          ],
        ),
      );

  Widget _buildTabContent() => SizedBox(
        height: 400,
        child: TabBarView(
          controller: _tabController,
          children: [_buildPostGrid(), _buildServicesList()],
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
                  const chatId = 'temp_chat_id';
                  context.go(
                      '/chat/$chatId?specialistName=${widget.specialistId}');
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

  String _getReviewCount() {
    final baseCount = (_specialist!.rating * 20).round();
    return (baseCount + (DateTime.now().millisecond % 50)).toString();
  }
}
