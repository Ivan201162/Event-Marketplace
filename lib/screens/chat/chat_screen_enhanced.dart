import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/services/message_reaction_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

/// Улучшенный экран чата с полным функционалом
class ChatScreenEnhanced extends ConsumerStatefulWidget {

  const ChatScreenEnhanced({
    required this.chatId, super.key,
    this.recipientName,
    this.recipientAvatar,
  });
  final String chatId;
  final String? recipientName;
  final String? recipientAvatar;

  @override
  ConsumerState<ChatScreenEnhanced> createState() => _ChatScreenEnhancedState();
}

class _ChatScreenEnhancedState extends ConsumerState<ChatScreenEnhanced>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final MessageReactionService _reactionService = MessageReactionService();
  Timer? _typingTimer;
  bool _isTyping = false;
  Map<String, dynamic>? _replyTo; // Сообщение, на которое отвечаем

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    debugLog("CHAT_OPENED:${widget.chatId}");
    
    // Firebase Analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'open_chat',
      parameters: {'chat_id': widget.chatId},
    ).catchError((e) => debugPrint('Analytics error: $e'));
    
    _initializeAnimations();
    _scrollToBottom();
    _markMessagesAsRead();
    _setupTypingIndicator();
  }

  void _setupTypingIndicator() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty && !_isTyping) {
        _isTyping = true;
        _updateTypingStatus(true);
      }
      
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (_isTyping) {
          _isTyping = false;
          _updateTypingStatus(false);
        }
      });
    });
  }

  void _updateTypingStatus(bool isTyping) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'typing': {
        user.uid: isTyping ? FieldValue.serverTimestamp() : FieldValue.delete(),
      },
    });
  }

  void _markMessagesAsRead() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get()
        .then((snapshot) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      batch.commit();
      
      // Обновляем счётчик непрочитанных
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({'unreadCount': 0});
    });
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
    _typingTimer?.cancel();
    _updateTypingStatus(false);
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Пользователь не авторизован');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final messageText = _messageController.text.trim();

      // Создаем сообщение
      final messageData = <String, dynamic>{
        'senderId': user.uid,
        'text': messageText,
        'type': 'text',
        'createdAt': Timestamp.now(),
        'isRead': false,
        'deleted': false,
        'attachments': [],
      };
      
      // Добавляем replyTo если есть
      if (_replyTo != null) {
        messageData['replyTo'] = {
          'messageId': _replyTo!['messageId'],
          'senderId': _replyTo!['senderId'],
          'text': _replyTo!['text'],
        };
        debugLog("CHAT_REPLY_SENT:${widget.chatId}:${_replyTo!['messageId']}");
      }
      
      final messageRef = await firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add(messageData);
      
      // Очищаем replyTo после отправки
      setState(() {
        _replyTo = null;
      });

      debugLog("MSG_SENT:text:${messageRef.id}");
      
      // Firebase Analytics
      try {
        await FirebaseAnalytics.instance.logEvent(
          name: 'send_message',
          parameters: {'chat_id': widget.chatId, 'message_id': messageRef.id},
        );
      } catch (e) {
        debugPrint('Analytics error: $e');
      }
      
      // Обновляем статус печатания
      _isTyping = false;
      _updateTypingStatus(false);

      // Обновляем время последнего сообщения в чате
      await firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': messageText,
        'lastMessageAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      debugLog("MSG_SEND_ERR:$e");
      _showError('Ошибка отправки: $e');
    } finally {
      setState(() => _isSending = false);
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
              // Заголовок чата
              _buildChatHeader(),

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
                    child: _buildChatContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Заголовок чата
  Widget _buildChatHeader() {
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

          // Аватар получателя
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: widget.recipientAvatar != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.recipientAvatar!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
          ),

          const SizedBox(width: 12),

          // Информация о получателе
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientName ?? 'Пользователь',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'В сети',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Действия
          IconButton(
            onPressed: _showChatOptions,
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Основной контент чата
  Widget _buildChatContent() {
    return Column(
      children: [
        // Список сообщений
        Expanded(
          child: _buildMessagesList(),
        ),
        
        // Индикатор "печатает..."
        _buildTypingIndicator(),

        // Поле ввода сообщения
        _buildMessageInput(),
      ],
    );
  }

  /// Список сообщений
  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
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

        // Автоматически прокручиваем к последнему сообщению
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data()! as Map<String, dynamic>;

            return _buildMessageBubble(doc.id, data);
          },
        );
      },
    );
  }

  /// Пузырек сообщения
  Widget _buildMessageBubble(String messageId, Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;
    final isMe = user?.uid == data['senderId'];
    final isPinned = data['isPinned'] == true;
    final attachments = (data['attachments'] as List?)?.cast<String>() ?? [];
    final replyTo = data['replyTo'] as Map<String, dynamic>?;

    return GestureDetector(
      onLongPress: () => _showMessageOptions(messageId, data, isMe),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF1E3A8A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomLeft: isMe
                        ? const Radius.circular(20)
                        : const Radius.circular(4),
                    bottomRight: isMe
                        ? const Radius.circular(4)
                        : const Radius.circular(20),
                  ),
                  border: isPinned
                      ? Border.all(color: Colors.amber, width: 2)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPinned) ...[
                      Row(
                        children: const [
                          Icon(Icons.push_pin, size: 12, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            'Закреплено',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Reply to сообщение
                    if (replyTo != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isMe 
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isMe ? Colors.white : Colors.blue,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              replyTo['senderId'] == user?.uid ? 'Вы' : 'Сообщение',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white70 : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              replyTo['text'] as String? ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: isMe ? Colors.white70 : Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (attachments.isNotEmpty) ...[
                      ...attachments.map((url) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Image.network(url, fit: BoxFit.cover),
                      )),
                    ],
                    if (data['deleted'] == true)
                      Text(
                        'Сообщение удалено',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else if (data['text'] != null && (data['text'] as String).isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['text'] ?? '',
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          if (data['editedAt'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '(изменено)',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    // Реакции из подколлекции
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .doc(widget.chatId)
                          .collection('messages')
                          .doc(messageId)
                          .collection('messageReactions')
                          .snapshots(),
                      builder: (context, reactionSnapshot) {
                        if (!reactionSnapshot.hasData || reactionSnapshot.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        // Группируем реакции по эмодзи
                        final reactionsByEmoji = <String, int>{};
                        for (final doc in reactionSnapshot.data!.docs) {
                          final emoji = doc.data()['emoji'] as String? ?? '';
                          reactionsByEmoji[emoji] = (reactionsByEmoji[emoji] ?? 0) + 1;
                        }
                        
                        if (reactionsByEmoji.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 4,
                            children: reactionsByEmoji.entries.map((entry) {
                              return GestureDetector(
                                onTap: () => _toggleReaction(messageId, entry.key),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(entry.key, style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${entry.value}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMessageTime(data['createdAt']),
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (isMe && data['isRead'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.done_all, size: 14, color: Colors.blue),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF1E3A8A),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final typing = snapshot.data!.data()?['typing'] as Map<String, dynamic>?;
        if (typing == null || typing.isEmpty) return const SizedBox.shrink();
        
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return const SizedBox.shrink();
        
        // Проверяем, печатает ли другой пользователь
        final otherUserTyping = typing.entries
            .where((entry) => entry.key != user.uid)
            .isNotEmpty;
        
        if (!otherUserTyping) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 48),
              Text(
                '${widget.recipientName ?? "Пользователь"} печатает...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessageOptions(String messageId, Map<String, dynamic> data, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Редактировать'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(messageId, data['text'] as String? ?? '');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Удалить'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(messageId);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: Text(data['isPinned'] == true ? 'Открепить' : 'Закрепить'),
              onTap: () {
                Navigator.pop(context);
                _togglePinMessage(messageId, data['isPinned'] != true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_reaction),
              title: const Text('Добавить реакцию'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(messageId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Ответить'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyTo = {
                    'messageId': messageId,
                    'senderId': data['senderId'],
                    'text': data['text'] as String? ?? '',
                  };
                });
                debugLog("CHAT_REPLY_START:${widget.chatId}:$messageId");
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Переслать'),
              onTap: () {
                Navigator.pop(context);
                _forwardMessage(messageId, data);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleReaction(String messageId, String emoji) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Проверяем, есть ли уже реакция от этого пользователя
      final reactionRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .collection('messageReactions')
          .doc(user.uid);
      
      final reactionDoc = await reactionRef.get();
      
      if (reactionDoc.exists && reactionDoc.data()?['emoji'] == emoji) {
        // Удаляем реакцию
        await reactionRef.delete();
        debugLog("CHAT_REACT_REMOVE:${widget.chatId}:$messageId:$emoji");
      } else {
        // Добавляем/обновляем реакцию
        await reactionRef.set({
          'emoji': emoji,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugLog("CHAT_REACT_ADD:${widget.chatId}:$messageId:$emoji");
      }
    } catch (e) {
      debugPrint('Error toggling reaction: $e');
    }
  }

  void _showReactionPicker(String messageId) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '👎', '⭐', '🔥'];
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: emojis.map((emoji) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _toggleReaction(messageId, emoji);
                },
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _togglePinMessage(String messageId, bool pin) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isPinned': pin});
  }

  void _editMessage(String messageId, String currentText) {
    final controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать сообщение'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Введите новый текст',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Текст не может быть пустым')),
                );
                return;
              }
              
              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .doc(messageId)
                  .update({
                'text': newText,
                'editedAt': FieldValue.serverTimestamp(),
              });
              
              debugLog("CHAT_MSG_EDIT:${widget.chatId}:$messageId");
              
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deleted': true,
      'text': '', // Очищаем текст
    });
    
    debugLog("CHAT_MSG_DELETE:${widget.chatId}:$messageId");
  }

  void _forwardMessage(String messageId, Map<String, dynamic> data) {
    // Показываем диалог выбора чата для пересылки
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переслать сообщение'),
        content: const Text('Выберите чат для пересылки'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Реализовать выбор чата и пересылку
              debugLog("CHAT_MSG_FORWARD:${widget.chatId}:$messageId");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Пересылка будет реализована в следующей версии')),
              );
            },
            child: const Text('Переслать'),
          ),
        ],
      ),
    );
  }

  /// Поле ввода сообщения
  Widget _buildMessageInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Показываем replyTo если есть
        if (_replyTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(
                left: BorderSide(color: Colors.blue, width: 3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ответ на сообщение',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _replyTo!['text'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _replyTo = null;
                    });
                  },
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              // Кнопка прикрепления
              IconButton(
            onPressed: _showAttachmentOptions,
            icon: const Icon(
              Icons.attach_file,
              color: Color(0xFF1E3A8A),
            ),
          ),

          // Поле ввода
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Введите сообщение...',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Кнопка отправки
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isSending ? Colors.grey[300] : const Color(0xFF1E3A8A),
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
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
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: index % 2 == 0
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (index % 2 != 0) ...[
                ShimmerBox(width: 32, height: 32, borderRadius: 16),
                const SizedBox(width: 8),
              ],
              ShimmerBox(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 60,
                borderRadius: 20,
              ),
              if (index % 2 == 0) ...[
                const SizedBox(width: 8),
                ShimmerBox(width: 32, height: 32, borderRadius: 16),
              ],
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
            'Начните общение',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Отправьте первое сообщение',
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

  /// Показать опции чата
  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Информация о чате'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Показать информацию о чате
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Отключить уведомления'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Отключить уведомления
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Заблокировать',
                  style: TextStyle(color: Colors.red),),
              onTap: () {
                Navigator.pop(context);
                // TODO: Заблокировать пользователя
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Показать опции прикрепления
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Фото'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Выбрать фото
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Видео'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Выбрать видео
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Файл'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Выбрать файл
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Форматирование времени сообщения
  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';

    final date = timestamp is Timestamp
        ? timestamp.toDate()
        : DateTime.parse(timestamp.toString());

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${date.day}.${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${date.minute}м назад';
    } else {
      return 'Только что';
    }
  }
}
