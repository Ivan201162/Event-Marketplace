import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enhanced_idea.dart';
import '../providers/auth_providers.dart';
import '../providers/enhanced_ideas_providers.dart';
import '../widgets/create_idea_widget.dart';
import '../widgets/idea_card_widget.dart';

/// Расширенный экран идей
class EnhancedIdeasScreen extends ConsumerStatefulWidget {
  const EnhancedIdeasScreen({super.key});

  @override
  ConsumerState<EnhancedIdeasScreen> createState() =>
      _EnhancedIdeasScreenState();
}

class _EnhancedIdeasScreenState extends ConsumerState<EnhancedIdeasScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  IdeaType? _selectedType;
  String? _selectedCategory;
  List<String> _selectedTags = [];
  double? _minBudget;
  double? _maxBudget;

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
  Widget build(BuildContext context) => Column(
        children: [
          // Внутренний TabBar для категорий идей
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Все', icon: Icon(Icons.lightbulb)),
              Tab(text: 'Популярные', icon: Icon(Icons.trending_up)),
              Tab(text: 'Мои идеи', icon: Icon(Icons.person)),
              Tab(text: 'Сохранённые', icon: Icon(Icons.bookmark)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllIdeasTab(),
                _buildPopularIdeasTab(),
                _buildMyIdeasTab(),
                _buildSavedIdeasTab(),
              ],
            ),
          ),
        ],
      );

  Widget _buildAllIdeasTab() => Consumer(
        builder: (context, ref, child) {
          final ideasAsync = ref.watch(ideasProvider);

          return ideasAsync.when(
            data: (ideas) {
              if (ideas.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(ideasProvider);
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: ideas.length,
                  itemBuilder: (context, index) {
                    final idea = ideas[index];
                    return IdeaCardWidget(
                      idea: idea,
                      onUserTap: () => _showUserProfile(idea.authorId),
                      onLike: () => _handleLike(idea),
                      onComment: () => _showComments(idea),
                      onShare: () => _shareIdea(idea),
                      onSave: () => _handleSave(idea),
                      onMore: () => _showIdeaOptions(idea),
                      onTap: () => _showIdeaDetails(idea),
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

  Widget _buildPopularIdeasTab() => Consumer(
        builder: (context, ref, child) {
          final popularIdeasAsync = ref.watch(popularIdeasProvider(null));

          return popularIdeasAsync.when(
            data: (ideas) {
              if (ideas.isEmpty) {
                return _buildEmptyPopularState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(popularIdeasProvider(null));
                },
                child: ListView.builder(
                  itemCount: ideas.length,
                  itemBuilder: (context, index) {
                    final idea = ideas[index];
                    return IdeaCardWidget(
                      idea: idea,
                      onUserTap: () => _showUserProfile(idea.authorId),
                      onLike: () => _handleLike(idea),
                      onComment: () => _showComments(idea),
                      onShare: () => _shareIdea(idea),
                      onSave: () => _handleSave(idea),
                      onMore: () => _showIdeaOptions(idea),
                      onTap: () => _showIdeaDetails(idea),
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

  Widget _buildMyIdeasTab() => Consumer(
        builder: (context, ref, child) {
          final currentUser = ref.watch(currentUserProvider);

          return currentUser.when(
            data: (user) {
              if (user == null) {
                return _buildLoginPrompt();
              }

              final myIdeasAsync = ref.watch(userIdeasProvider(user.uid));

              return myIdeasAsync.when(
                data: (ideas) {
                  if (ideas.isEmpty) {
                    return _buildEmptyMyIdeasState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(userIdeasProvider(user.uid));
                    },
                    child: ListView.builder(
                      itemCount: ideas.length,
                      itemBuilder: (context, index) {
                        final idea = ideas[index];
                        return IdeaCardWidget(
                          idea: idea,
                          onUserTap: () => _showUserProfile(idea.authorId),
                          onLike: () => _handleLike(idea),
                          onComment: () => _showComments(idea),
                          onShare: () => _shareIdea(idea),
                          onSave: () => _handleSave(idea),
                          onMore: () => _showIdeaOptions(idea),
                          onTap: () => _showIdeaDetails(idea),
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

  Widget _buildSavedIdeasTab() => Consumer(
        builder: (context, ref, child) {
          final currentUser = ref.watch(currentUserProvider);

          return currentUser.when(
            data: (user) {
              if (user == null) {
                return _buildLoginPrompt();
              }

              final savedIdeasAsync = ref.watch(savedIdeasProvider(user.uid));

              return savedIdeasAsync.when(
                data: (ideas) {
                  if (ideas.isEmpty) {
                    return _buildEmptySavedState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(savedIdeasProvider(user.uid));
                    },
                    child: ListView.builder(
                      itemCount: ideas.length,
                      itemBuilder: (context, index) {
                        final idea = ideas[index];
                        return IdeaCardWidget(
                          idea: idea,
                          onUserTap: () => _showUserProfile(idea.authorId),
                          onLike: () => _handleLike(idea),
                          onComment: () => _showComments(idea),
                          onShare: () => _shareIdea(idea),
                          onSave: () => _handleSave(idea),
                          onMore: () => _showIdeaOptions(idea),
                          onTap: () => _showIdeaDetails(idea),
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
              Icons.lightbulb_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Нет идей',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте первую идею или подождите, пока другие пользователи поделятся своими',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createIdea,
              icon: const Icon(Icons.add),
              label: const Text('Создать идею'),
            ),
          ],
        ),
      );

  Widget _buildEmptyPopularState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Нет популярных идей',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Популярные идеи появятся здесь, когда пользователи начнут ставить лайки',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyMyIdeasState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'У вас нет идей',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте свою первую идею и поделитесь ею с сообществом',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createIdea,
              icon: const Icon(Icons.add),
              label: const Text('Создать идею'),
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
              'Нет сохранённых идей',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Сохраняйте интересные идеи, нажав на иконку закладки',
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
              'Чтобы создавать и сохранять идеи, необходимо войти в аккаунт',
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
                ref.invalidate(ideasProvider);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );

  void _createIdea() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      _showLoginDialog();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateIdeaWidget(
          authorId: currentUser.uid,
          onIdeaCreated: () {
            ref.invalidate(ideasProvider);
            ref.invalidate(userIdeasProvider(currentUser.uid));
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
        title: const Text('Поиск идей'),
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<IdeaType?>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Тип идеи',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      child: Text('Все типы'),
                    ),
                    ...IdeaType.values.map(
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
                    labelText: 'Категория',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory =
                          value.trim().isNotEmpty ? value.trim() : null;
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Мин. бюджет',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _minBudget = double.tryParse(value);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Макс. бюджет',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _maxBudget = double.tryParse(value);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedType = null;
                  _selectedCategory = null;
                  _selectedTags = [];
                  _minBudget = null;
                  _maxBudget = null;
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

  void _handleLike(EnhancedIdea idea) {
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

  void _showComments(EnhancedIdea idea) {
    // TODO: Показать комментарии
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Открытие комментариев'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareIdea(EnhancedIdea idea) {
    // TODO: Реализовать репост
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Идея репостнута'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _handleSave(EnhancedIdea idea) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      _showLoginDialog();
      return;
    }

    // TODO: Реализовать сохранение
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Идея сохранена'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showIdeaDetails(EnhancedIdea idea) {
    // TODO: Показать детали идеи
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Детали идеи: ${idea.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showIdeaOptions(EnhancedIdea idea) {
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
              _shareIdea(idea);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Сохранить'),
            onTap: () {
              Navigator.of(context).pop();
              _handleSave(idea);
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Пожаловаться'),
            onTap: () {
              Navigator.of(context).pop();
              _reportIdea(idea);
            },
          ),
        ],
      ),
    );
  }

  void _reportIdea(EnhancedIdea idea) {
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
