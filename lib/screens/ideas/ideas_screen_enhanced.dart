import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Улучшенный экран идей с полным функционалом
class IdeasScreenEnhanced extends ConsumerStatefulWidget {
  const IdeasScreenEnhanced({super.key});

  @override
  ConsumerState<IdeasScreenEnhanced> createState() =>
      _IdeasScreenEnhancedState();
}

class _IdeasScreenEnhancedState extends ConsumerState<IdeasScreenEnhanced>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedFilter = 'all';
  String _selectedSort = 'date';
  bool _isSearching = false;

  final List<Map<String, dynamic>> _filters = [
    {'value': 'all', 'label': 'Все', 'icon': Icons.all_inclusive},
    {'value': 'popular', 'label': 'Популярные', 'icon': Icons.trending_up},
    {'value': 'recent', 'label': 'Недавние', 'icon': Icons.schedule},
    {'value': 'my', 'label': 'Мои идеи', 'icon': Icons.person},
  ];

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'date', 'label': 'По дате', 'icon': Icons.calendar_today},
    {'value': 'likes', 'label': 'По лайкам', 'icon': Icons.favorite},
    {'value': 'comments', 'label': 'По комментариям', 'icon': Icons.comment},
    {'value': 'title', 'label': 'По названию', 'icon': Icons.title},
  ];

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
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              // Заголовок
              _buildHeader(),

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
                    child: _buildContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Заголовок экрана
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Идеи',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              context.go('/ideas/create');
            },
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  /// Основной контент
  Widget _buildContent() {
    return Column(
      children: [
        // Поиск и фильтры
        _buildSearchAndFiltersSection(),

        // Список идей
        Expanded(
          child: _buildIdeasList(),
        ),
      ],
    );
  }

  /// Секция поиска и фильтров
  Widget _buildSearchAndFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Поиск
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск идей...',
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear, color: Colors.grey),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12,),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isSearching = value.isNotEmpty;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _showFilterOptions,
                icon: const Icon(
                  Icons.filter_list,
                  color: Color(0xFF1E3A8A),
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Фильтры
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter['value'] == _selectedFilter;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter['value'];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8,),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey[300]!),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF1E3A8A).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            filter['icon'],
                            color: isSelected ? Colors.white : Colors.grey[600],
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            filter['label'],
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[600],
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Список идей
  Widget _buildIdeasList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getIdeasStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data()! as Map<String, dynamic>;

            return _buildIdeaCard(doc.id, data);
          },
        );
      },
    );
  }

  /// Поток идей с фильтрацией
  Stream<QuerySnapshot> _getIdeasStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(QuerySnapshot.empty());
    }

    Query query = FirebaseFirestore.instance.collection('ideas');

    // Применяем фильтр
    switch (_selectedFilter) {
      case 'popular':
        query = query.orderBy('likes', descending: true);
      case 'recent':
        query = query.orderBy('createdAt', descending: true);
      case 'my':
        query = query.where('authorId', isEqualTo: user.uid);
      default:
        query = query.orderBy('createdAt', descending: true);
    }

    // Применяем сортировку
    switch (_selectedSort) {
      case 'date':
        query = query.orderBy('createdAt', descending: true);
      case 'likes':
        query = query.orderBy('likes', descending: true);
      case 'comments':
        query = query.orderBy('comments', descending: true);
      case 'title':
        query = query.orderBy('title');
    }

    return query.snapshots();
  }

  /// Карточка идеи
  Widget _buildIdeaCard(String ideaId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок идеи
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Аватар автора
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['authorName'] ?? 'Пользователь',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(data['createdAt']),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _showIdeaOptions(ideaId, data);
                  },
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Заголовок идеи
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              data['title'] ?? 'Без названия',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Описание идеи
          if (data['description'] != null && data['description'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                data['description'],
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Изображение идеи
          if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: data['imageUrl'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  placeholder: (context, url) => ShimmerBox(
                    width: double.infinity,
                    height: 200,
                    borderRadius: 12,
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.error,
                      color: Colors.grey,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),

          // Теги
          if (data['tags'] != null && (data['tags'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (data['tags'] as List).map<Widget>((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1E3A8A).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      tag.toString(),
                      style: const TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Действия
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.favorite_border,
                  label: '${data['likes'] ?? 0}',
                  onTap: () => _likeIdea(ideaId, data),
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: '${data['comments'] ?? 0}',
                  onTap: () => _showComments(ideaId, data),
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Поделиться',
                  onTap: () => _shareIdea(ideaId, data),
                ),
                const Spacer(),
                _buildActionButton(
                  icon: Icons.bookmark_border,
                  label: 'Сохранить',
                  onTap: () => _saveIdea(ideaId, data),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Кнопка действия
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Состояние загрузки
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerBox(width: 40, height: 40, borderRadius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 120, height: 16, borderRadius: 8),
                        const SizedBox(height: 4),
                        ShimmerBox(width: 80, height: 12, borderRadius: 6),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ShimmerBox(width: double.infinity, height: 20, borderRadius: 10),
              const SizedBox(height: 8),
              ShimmerBox(width: double.infinity, height: 60, borderRadius: 8),
              const SizedBox(height: 16),
              Row(
                children: [
                  ShimmerBox(width: 60, height: 20, borderRadius: 10),
                  const SizedBox(width: 16),
                  ShimmerBox(width: 60, height: 20, borderRadius: 10),
                  const SizedBox(width: 16),
                  ShimmerBox(width: 60, height: 20, borderRadius: 10),
                ],
              ),
            ],
          ),
        );
      },
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

  /// Пустое состояние
  Widget _buildEmptyState() {
    return Center(
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
            'Идей пока нет',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Поделитесь своей креативной идеей!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.go('/ideas/create');
            },
            icon: const Icon(Icons.add),
            label: const Text('Создать идею'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Показать опции фильтра
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Сортировка',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._sortOptions.map((option) {
              return ListTile(
                leading: Icon(option['icon']),
                title: Text(option['label']),
                trailing: _selectedSort == option['value']
                    ? const Icon(Icons.check, color: Color(0xFF1E3A8A))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedSort = option['value'];
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Показать опции идеи
  void _showIdeaOptions(String ideaId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Подробнее'),
              onTap: () {
                Navigator.pop(context);
                _showIdeaDetails(ideaId, data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Редактировать'),
              onTap: () {
                Navigator.pop(context);
                _editIdea(ideaId, data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Поделиться'),
              onTap: () {
                Navigator.pop(context);
                _shareIdea(ideaId, data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Пожаловаться',
                  style: TextStyle(color: Colors.red),),
              onTap: () {
                Navigator.pop(context);
                _reportIdea(ideaId, data);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Лайкнуть идею
  void _likeIdea(String ideaId, Map<String, dynamic> data) {
    // TODO: Реализовать лайк
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Лайк будет реализован'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Показать комментарии
  void _showComments(String ideaId, Map<String, dynamic> data) {
    // TODO: Реализовать комментарии
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Комментарии будут реализованы'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Поделиться идеей
  void _shareIdea(String ideaId, Map<String, dynamic> data) {
    // TODO: Реализовать шаринг
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Шаринг будет реализован'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Сохранить идею
  void _saveIdea(String ideaId, Map<String, dynamic> data) {
    // TODO: Реализовать сохранение
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Сохранение будет реализовано'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Показать детали идеи
  void _showIdeaDetails(String ideaId, Map<String, dynamic> data) {
    // TODO: Реализовать детали
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Детали будут реализованы'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Редактировать идею
  void _editIdea(String ideaId, Map<String, dynamic> data) {
    // TODO: Реализовать редактирование
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Редактирование будет реализовано'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Пожаловаться на идею
  void _reportIdea(String ideaId, Map<String, dynamic> data) {
    // TODO: Реализовать жалобу
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Жалоба будет реализована'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Форматирование даты
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    final date = timestamp is Timestamp
        ? timestamp.toDate()
        : DateTime.parse(timestamp.toString());

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'Только что';
    }
  }
}
