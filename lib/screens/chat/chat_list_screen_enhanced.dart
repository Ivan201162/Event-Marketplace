import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/chat.dart';
import '../../providers/chat_providers.dart';
import '../../widgets/animated_skeleton.dart';
import 'chat_screen_enhanced.dart';

/// Улучшенный экран списка чатов
class ChatListScreenEnhanced extends ConsumerStatefulWidget {
  const ChatListScreenEnhanced({super.key});

  @override
  ConsumerState<ChatListScreenEnhanced> createState() => _ChatListScreenEnhancedState();
}

class _ChatListScreenEnhancedState extends ConsumerState<ChatListScreenEnhanced>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isSearching = false;

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
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
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

  /// Заголовок экрана
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(
            Icons.chat_bubble,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Чаты',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              _showNewChatOptions();
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
        // Поиск
        _buildSearchSection(),
        
        // Список чатов
        Expanded(
          child: _buildChatsList(),
        ),
      ],
    );
  }

  /// Секция поиска
  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
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
                  hintText: 'Поиск чатов...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            onPressed: () {
              _showFilterOptions();
            },
            icon: const Icon(
              Icons.filter_list,
              color: Color(0xFF1E3A8A),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Список чатов
  Widget _buildChatsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getChatsStream(),
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
            final data = doc.data() as Map<String, dynamic>;
            
            return _buildChatCard(doc.id, data);
          },
        );
      },
    );
  }

  /// Поток чатов
  Stream<QuerySnapshot> _getChatsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(QuerySnapshot.empty());
    }

    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  /// Карточка чата
  Widget _buildChatCard(String chatId, Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUserId = participants.firstWhere(
      (id) => id != user?.uid,
      orElse: () => '',
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _openChat(chatId, data);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Аватар
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    if (data['isOnline'] == true)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // Информация о чате
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data['name'] ?? 'Чат',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatLastMessageTime(data['lastMessageAt']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data['lastMessage'] ?? 'Нет сообщений',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (data['unreadCount'] != null && data['unreadCount'] > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E3A8A),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${data['unreadCount']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Состояние загрузки
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ShimmerBox(width: 56, height: 56, borderRadius: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 150, height: 16, borderRadius: 8),
                    const SizedBox(height: 8),
                    ShimmerBox(width: 200, height: 14, borderRadius: 7),
                  ],
                ),
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
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Чатов пока нет',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Начните общение с другими пользователями',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showNewChatOptions();
            },
            icon: const Icon(Icons.add),
            label: const Text('Начать чат'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Открыть чат
  void _openChat(String chatId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreenEnhanced(
          chatId: chatId,
          recipientName: data['name'],
          recipientAvatar: data['avatarUrl'],
        ),
      ),
    );
  }

  /// Показать опции нового чата
  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Найти пользователя'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Поиск пользователей
                _showSearchUsers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Создать группу'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Создание группы
                _showCreateGroup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Сканировать QR-код'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Сканирование QR-кода
                _showQRScanner();
              },
            ),
          ],
        ),
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
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Все чаты'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Показать все чаты
              },
            ),
            ListTile(
              leading: const Icon(Icons.mark_chat_unread),
              title: const Text('Непрочитанные'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Показать непрочитанные
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Группы'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Показать группы
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Поиск пользователей
  void _showSearchUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Поиск пользователей будет реализован'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Создание группы
  void _showCreateGroup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Создание группы будет реализовано'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Сканирование QR-кода
  void _showQRScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Сканирование QR-кода будет реализовано'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Форматирование времени последнего сообщения
  String _formatLastMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    final date = timestamp is Timestamp 
        ? timestamp.toDate() 
        : DateTime.parse(timestamp.toString());
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${date.day}.${date.month}';
    } else if (difference.inHours > 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м';
    } else {
      return 'Только что';
    }
  }
}
