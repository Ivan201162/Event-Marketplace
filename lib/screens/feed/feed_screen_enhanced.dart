import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../services/storage_service.dart';
import '../../widgets/animated_skeleton.dart';

/// Улучшенный экран ленты с исправленными Firestore rules
class FeedScreenEnhanced extends ConsumerStatefulWidget {
  const FeedScreenEnhanced({super.key});

  @override
  ConsumerState<FeedScreenEnhanced> createState() => _FeedScreenEnhancedState();
}

class _FeedScreenEnhancedState extends ConsumerState<FeedScreenEnhanced>
    with TickerProviderStateMixin {
  final _postController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isCreatingPost = false;
  File? _selectedImage;
  String _selectedFilter = 'Все';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _filters = ['Все', 'Популярные', 'Недавние', 'Мои посты'];

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
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _postController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty && _selectedImage == null) {
      _showError('Добавьте текст или изображение');
      return;
    }

    setState(() => _isCreatingPost = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Пользователь не авторизован');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final storageService = ref.read(storageServiceProvider);

      String? imageUrl;

      // Загружаем изображение, если выбрано
      if (_selectedImage != null) {
        final postId = firestore.collection('posts').doc().id;
        imageUrl =
            await storageService.uploadPostImage(postId, _selectedImage!);
      }

      // Создаем пост
      await firestore.collection('posts').add({
        'authorId': user.uid, // Исправлено: было userId, стало authorId
        'text': _postController.text.trim(),
        'imageUrl': imageUrl,
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'isPinned': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Очищаем форму
      _postController.clear();
      setState(() {
        _selectedImage = null;
      });

      _showSuccess('Пост опубликован!');
    } catch (e) {
      String errorMessage = 'Ошибка при создании поста';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Нет прав для создания поста. Проверьте авторизацию.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Ошибка сети. Проверьте подключение к интернету.';
      }
      _showError(errorMessage);
    } finally {
      setState(() => _isCreatingPost = false);
    }
  }

  Future<void> _likePost(String postId, bool isLiked) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final firestore = FirebaseFirestore.instance;
      final postRef = firestore.collection('posts').doc(postId);

      if (isLiked) {
        // Убираем лайк
        await postRef.update({
          'likes': FieldValue.increment(-1),
          'updatedAt': Timestamp.now(),
        });
      } else {
        // Добавляем лайк
        await postRef.update({
          'likes': FieldValue.increment(1),
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      _showError('Ошибка при лайке: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);

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

  /// Заголовок ленты
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(
            Icons.dynamic_feed,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Лента',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // Открыть фильтры
              _showFilterDialog();
            },
            icon: const Icon(
              Icons.filter_list,
              color: Colors.white,
              size: 24,
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
        // Создание поста
        _buildCreatePostSection(),

        // Фильтры
        _buildFiltersSection(),

        // Лента постов
        Expanded(
          child: _buildPostsList(),
        ),
      ],
    );
  }

  /// Секция создания поста
  Widget _buildCreatePostSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
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
                child: TextField(
                  controller: _postController,
                  decoration: const InputDecoration(
                    hintText: 'Что у вас нового?',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  maxLines: null,
                ),
              ),
            ],
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _pickImage,
                icon: const Icon(Icons.image, color: Color(0xFF1E3A8A)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isCreatingPost ? null : _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isCreatingPost
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Опубликовать'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Секция фильтров
  Widget _buildFiltersSection() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF1E3A8A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border:
                      isSelected ? null : Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Список постов
  Widget _buildPostsList() {
    // Проверяем авторизацию
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildAuthRequiredState();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
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
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildPostCard(doc.id, data);
          },
        );
      },
    );
  }

  /// Карточка поста
  Widget _buildPostCard(String postId, Map<String, dynamic> data) {
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
          // Заголовок поста
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
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
                        'Пользователь', // TODO: Получить имя из users коллекции
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                    // Показать меню поста
                  },
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Текст поста
          if (data['text'] != null && data['text'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                data['text'],
                style: const TextStyle(fontSize: 16),
              ),
            ),

          // Изображение поста
          if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: data['imageUrl'],
                  fit: BoxFit.cover,
                  width: double.infinity,
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

          // Действия
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.favorite_border,
                  label: '${data['likes'] ?? 0}',
                  onTap: () => _likePost(postId, false),
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: '${data['comments'] ?? 0}',
                  onTap: () {
                    // Перейти к комментариям
                  },
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: '${data['shares'] ?? 0}',
                  onTap: () {
                    // Поделиться постом
                  },
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
              ShimmerBox(width: double.infinity, height: 100, borderRadius: 8),
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
            Icons.dynamic_feed_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Лента пуста',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Станьте первым, кто поделится новостью!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Диалог фильтров
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _filters.map((filter) {
            return ListTile(
              title: Text(filter),
              leading: Radio<String>(
                value: filter,
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            );
          }).toList(),
        ),
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

  /// Состояние когда требуется авторизация
  Widget _buildAuthRequiredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Для просмотра ленты',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'необходимо войти в аккаунт',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.go('/auth');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }
}
