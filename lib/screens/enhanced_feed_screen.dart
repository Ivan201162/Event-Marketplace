import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enhanced_feed_post.dart';
import '../providers/auth_providers.dart';
import '../providers/enhanced_feed_providers.dart';
import '../widgets/create_post_widget.dart';
import '../widgets/feed_post_widget.dart';

/// Расширенный экран ленты
class EnhancedFeedScreen extends ConsumerStatefulWidget {
  const EnhancedFeedScreen({super.key});

  @override
  ConsumerState<EnhancedFeedScreen> createState() => _EnhancedFeedScreenState();
}

class _EnhancedFeedScreenState extends ConsumerState<EnhancedFeedScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  FeedPostType? _selectedType;
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Внутренний TabBar для категорий ленты
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Все', icon: Icon(Icons.home)),
              Tab(text: 'Подписки', icon: Icon(Icons.people)),
              Tab(text: 'Сохранённые', icon: Icon(Icons.bookmark)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllPostsTab(),
                _buildFollowingTab(),
                _buildSavedTab(),
              ],
            ),
          ),
        ],
      );

  Widget _buildAllPostsTab() => Consumer(
        builder: (context, ref, child) {
          final feedAsync = ref.watch(feedProvider);

          return feedAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(feedProvider);
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return FeedPostWidget(
                      post: post,
                      onUserTap: () => _showUserProfile(post.authorId),
                      onLike: () => _handleLike(post),
                      onComment: () => _showComments(post),
                      onShare: () => _sharePost(post),
                      onSave: () => _handleSave(post),
                      onMore: () => _showPostOptions(post),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error.toString()),
          );
        },
      );

  Widget _buildFollowingTab() => const Center(
        child: Text(
          'Посты подписок\n(функция в разработке)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );

  Widget _buildSavedTab() => Consumer(
        builder: (context, ref, child) {
          final currentUser = ref.watch(currentUserProvider);

          return currentUser.when(
            data: (user) {
              if (user == null) {
                return _buildLoginPrompt();
              }

              final savedPostsAsync = ref.watch(savedPostsProvider(user.uid));

              return savedPostsAsync.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return _buildEmptySavedState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(savedPostsProvider(user.uid));
                    },
                    child: ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return FeedPostWidget(
                          post: post,
                          onUserTap: () => _showUserProfile(post.authorId),
                          onLike: () => _handleLike(post),
                          onComment: () => _showComments(post),
                          onShare: () => _sharePost(post),
                          onSave: () => _handleSave(post),
                          onMore: () => _showPostOptions(post),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(error.toString()),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error.toString()),
          );
        },
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feed_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Лента пуста',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте первый пост или подпишитесь на пользователей',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createPost,
              icon: const Icon(Icons.add),
              label: const Text('Создать пост'),
            ),
          ],
        ),
      );

  Widget _buildEmptySavedState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Нет сохранённых постов',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Сохраняйте интересные посты, нажав на иконку закладки',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );

  Widget _buildLoginPrompt() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Войдите в аккаунт',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Чтобы сохранять посты, необходимо войти в аккаунт',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );

  Widget _buildErrorState(String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(feedProvider);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );

  void _createPost() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      _showLoginDialog();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreatePostWidget(
          authorId: currentUser.uid,
          onPostCreated: () {
            ref.invalidate(feedProvider);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск постов'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Введите запрос для поиска',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performSearch();
            },
            child: const Text('Поиск'),
          ),
        ],
      ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Фильтры'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<FeedPostType?>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип поста',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    child: Text('Все типы'),
                  ),
                  ...FeedPostType.values.map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text('${type.icon} ${type.displayName}'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Теги (через запятую)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedTags = value
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList();
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedType = null;
                  _selectedTags = [];
                });
              },
              child: const Text('Сбросить'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyFilters();
              },
              child: const Text('Применить'),
            ),
          ],
        ),
      ),
    );
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) return;

    // TODO: Реализовать поиск
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Поиск: $_searchQuery'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _applyFilters() {
    // TODO: Реализовать применение фильтров
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Фильтры применены'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showUserProfile(String userId) {
    // TODO: Переход к профилю пользователя
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Профиль пользователя: $userId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleLike(EnhancedFeedPost post) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      _showLoginDialog();
      return;
    }

    // TODO: Реализовать лайк
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Лайк поставлен'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showComments(EnhancedFeedPost post) {
    // TODO: Показать комментарии
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Открытие комментариев'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _sharePost(EnhancedFeedPost post) {
    // TODO: Реализовать репост
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Пост репостнут'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _handleSave(EnhancedFeedPost post) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      _showLoginDialog();
      return;
    }

    // TODO: Реализовать сохранение
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Пост сохранён'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showPostOptions(EnhancedFeedPost post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Поделиться'),
            onTap: () {
              Navigator.of(context).pop();
              _sharePost(post);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Сохранить'),
            onTap: () {
              Navigator.of(context).pop();
              _handleSave(post);
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Пожаловаться'),
            onTap: () {
              Navigator.of(context).pop();
              _reportPost(post);
            },
          ),
        ],
      ),
    );
  }

  void _reportPost(EnhancedFeedPost post) {
    // TODO: Реализовать жалобу
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Жалоба отправлена'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вход required'),
        content: const Text(
            'Для выполнения этого действия необходимо войти в аккаунт'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Переход к экрану входа
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }
}
