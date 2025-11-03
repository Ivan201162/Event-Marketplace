import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/enhanced_chat.dart';
import 'package:event_marketplace_app/models/enhanced_message.dart';
import 'package:flutter/foundation.dart';

/// Оптимизированный сервис для работы с чатами
class OptimizedChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Кэш для чатов
  List<EnhancedChat> _cachedChats = [];
  DateTime? _chatsCacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 10);

  /// Получить чаты пользователя с реальным временем
  Stream<List<EnhancedChat>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _parseChatFromFirestore(doc.id, data);
      }).toList();
    });
  }

  /// Получить чаты пользователя (одноразово)
  Future<List<EnhancedChat>> getUserChats(String userId,
      {bool forceRefresh = false,}) async {
    try {
      // Проверяем кэш
      if (!forceRefresh &&
          _cachedChats.isNotEmpty &&
          _chatsCacheTime != null &&
          DateTime.now().difference(_chatsCacheTime!) < _cacheExpiry) {
        return _cachedChats;
      }

      debugPrint('💬 Загрузка чатов пользователя: $userId');

      final snapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      final chats = snapshot.docs.map((doc) {
        final data = doc.data();
        return _parseChatFromFirestore(doc.id, data);
      }).toList();

      // Обновляем кэш
      _cachedChats = chats;
      _chatsCacheTime = DateTime.now();

      debugPrint('✅ Загружено ${chats.length} чатов');
      return chats;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки чатов: $e');
      return _cachedChats;
    }
  }

  /// Получить сообщения чата с реальным временем
  Stream<List<EnhancedMessage>> getChatMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _parseMessageFromFirestore(doc.id, data);
      }).toList();
    });
  }

  /// Отправить сообщение
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final messageData = {
        'senderId': senderId,
        'content': content,
        'type': type.name,
        'metadata': metadata ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      // Добавляем сообщение
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Обновляем последнее сообщение в чате
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': content,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Сообщение отправлено в чат: $chatId');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка отправки сообщения: $e');
      return false;
    }
  }

  /// Создать новый чат
  Future<String?> createChat({
    required List<String> memberIds,
    String? name,
    String? description,
    ChatType type = ChatType.direct,
  }) async {
    try {
      final chatData = {
        'type': type.name,
        'name': name,
        'description': description,
        'members': memberIds,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      final docRef = await _firestore.collection('chats').add(chatData);

      debugPrint('✅ Чат создан с ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Ошибка создания чата: $e');
      return null;
    }
  }

  /// Получить информацию о пользователе для чата
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'id': userId,
        'name': data['name'] ?? data['displayName'] ?? 'Неизвестный',
        'avatar': data['avatarUrl'] ?? data['photoURL'],
        'isOnline': data['isOnline'] ?? false,
        'lastSeen': data['lastSeen'],
      };
    } catch (e) {
      debugPrint('❌ Ошибка получения информации о пользователе: $e');
      return null;
    }
  }

  /// Отметить сообщения как прочитанные
  Future<bool> markMessagesAsRead(String chatId, String userId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (messagesSnapshot.docs.isEmpty) return true;

      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      debugPrint('✅ Сообщения отмечены как прочитанные');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка отметки сообщений как прочитанных: $e');
      return false;
    }
  }

  /// Получить количество непрочитанных сообщений
  Future<int> getUnreadMessagesCount(String userId) async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('members', arrayContains: userId)
          .get();

      var totalUnread = 0;

      for (final chatDoc in chatsSnapshot.docs) {
        final unreadSnapshot = await _firestore
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .where('senderId', isNotEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();

        totalUnread += unreadSnapshot.docs.length;
      }

      return totalUnread;
    } catch (e) {
      debugPrint('❌ Ошибка подсчета непрочитанных сообщений: $e');
      return 0;
    }
  }

  /// Парсинг чата из Firestore
  EnhancedChat _parseChatFromFirestore(String id, Map<String, dynamic> data) {
    final members = (data['members'] as List<dynamic>?)
            ?.map((memberId) => ChatMember(
                  userId: memberId.toString(),
                  role: ChatMemberRole.member,
                  joinedAt: DateTime.now(),
                ),)
            .toList() ??
        [];

    return EnhancedChat(
      id: id,
      type: ChatType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => ChatType.direct,
      ),
      members: members,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      name: data['name'],
      description: data['description'],
      avatarUrl: data['avatarUrl'],
      lastMessage: ChatLastMessage(
        id: data['lastMessageId'] ?? '',
        senderId: data['lastMessageSenderId'] ?? '',
        text: data['lastMessage'] ?? '',
        type: MessageType.text,
        createdAt:
            (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ),
      isPinned: data['isPinned'] ?? false,
      isMuted: data['isMuted'] ?? false,
    );
  }

  /// Парсинг сообщения из Firestore
  EnhancedMessage _parseMessageFromFirestore(
      String id, Map<String, dynamic> data,) {
    return EnhancedMessage(
      id: id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => MessageType.text,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Очистить кэш
  void clearCache() {
    _cachedChats.clear();
    _chatsCacheTime = null;
    debugPrint('🧹 Кэш чатов очищен');
  }
}
