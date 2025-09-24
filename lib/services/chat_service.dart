import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chat.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Create a new chat between participants
  Future<String> createChat({
    required List<String> participants,
    String? chatType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if chat already exists between these participants
      final existingChat = await _findExistingChat(participants);
      if (existingChat != null) {
        return existingChat.id;
      }

      final chatId = _uuid.v4();
      final now = DateTime.now();

      final chat = Chat(
        id: chatId,
        participants: participants,
        chatType: chatType,
        metadata: metadata ?? {},
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection('chats').doc(chatId).set(chat.toMap());
      
      debugPrint('Chat created: $chatId');
      return chatId;
    } catch (e) {
      debugPrint('Error creating chat: $e');
      throw Exception('Ошибка создания чата: $e');
    }
  }

  /// Find existing chat between participants
  Future<Chat?> _findExistingChat(List<String> participants) async {
    try {
      final query = await _firestore
          .collection('chats')
          .where('participants', arrayContains: participants.first)
          .get();

      for (final doc in query.docs) {
        final chat = Chat.fromDocument(doc);
        if (chat.participants.length == participants.length &&
            chat.participants.every((p) => participants.contains(p))) {
          return chat;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error finding existing chat: $e');
      return null;
    }
  }

  /// Get chat by ID
  Future<Chat?> getChat(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) return null;
      return Chat.fromDocument(doc);
    } catch (e) {
      debugPrint('Error getting chat: $e');
      return null;
    }
  }

  /// Get all chats for a user
  Stream<List<Chat>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Chat.fromDocument(doc)).toList();
    });
  }

  /// Get or create chat between two users
  Future<String> getOrCreateChat(String userId1, String userId2, {String? chatType}) async {
    try {
      final participants = [userId1, userId2];
      final existingChat = await _findExistingChat(participants);
      
      if (existingChat != null) {
        return existingChat.id;
      }

      return await createChat(
        participants: participants,
        chatType: chatType ?? 'customer_specialist',
      );
    } catch (e) {
      debugPrint('Error getting or creating chat: $e');
      throw Exception('Ошибка получения или создания чата: $e');
    }
  }

  /// Update chat last message info
  Future<void> updateChatLastMessage(
    String chatId,
    String messageId,
    String messageText,
    DateTime messageAt,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageId': messageId,
        'lastMessageText': messageText,
        'lastMessageAt': Timestamp.fromDate(messageAt),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error updating chat last message: $e');
    }
  }

  /// Mark chat as read for user
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'readStatus.$userId': true,
        'lastSeen.$userId': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error marking chat as read: $e');
    }
  }

  /// Mark chat as unread for user
  Future<void> markChatAsUnread(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'readStatus.$userId': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error marking chat as unread: $e');
    }
  }

  /// Update user's last seen timestamp
  Future<void> updateLastSeen(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastSeen.$userId': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error updating last seen: $e');
    }
  }

  /// Archive chat (mark as inactive)
  Future<void> archiveChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error archiving chat: $e');
    }
  }

  /// Delete chat permanently
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages in the chat first
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete the chat
      await _firestore.collection('chats').doc(chatId).delete();
      
      debugPrint('Chat deleted: $chatId');
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      throw Exception('Ошибка удаления чата: $e');
    }
  }

  /// Get chat participants info
  Future<List<Map<String, dynamic>>> getChatParticipantsInfo(String chatId) async {
    try {
      final chat = await getChat(chatId);
      if (chat == null) return [];

      final participantsInfo = <Map<String, dynamic>>[];
      
      for (final userId in chat.participants) {
        // Get user info from users collection
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          participantsInfo.add({
            'userId': userId,
            'displayName': userDoc.data()?['displayName'] ?? 'Unknown',
            'avatarUrl': userDoc.data()?['avatarUrl'],
            'isOnline': userDoc.data()?['isOnline'] ?? false,
            'lastSeen': userDoc.data()?['lastSeen'],
          });
        }
      }

      return participantsInfo;
    } catch (e) {
      debugPrint('Error getting chat participants info: $e');
      return [];
    }
  }

  /// Search chats by participant name or message content
  Future<List<Chat>> searchChats(String userId, String query) async {
    try {
      final userChats = await getUserChats(userId).first;
      
      return userChats.where((chat) {
        // Search in chat metadata or last message
        final searchText = '${chat.lastMessageText ?? ''} ${chat.metadata.toString()}'.toLowerCase();
        return searchText.contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      debugPrint('Error searching chats: $e');
      return [];
    }
  }

  /// Get unread chats count for user
  Future<int> getUnreadChatsCount(String userId) async {
    try {
      final userChats = await getUserChats(userId).first;
      return userChats.where((chat) => !chat.hasUserRead(userId)).length;
    } catch (e) {
      debugPrint('Error getting unread chats count: $e');
      return 0;
    }
  }

  /// Get chat statistics
  Future<Map<String, dynamic>> getChatStatistics(String userId) async {
    try {
      final userChats = await getUserChats(userId).first;
      
      return {
        'totalChats': userChats.length,
        'unreadChats': userChats.where((chat) => !chat.hasUserRead(userId)).length,
        'activeChats': userChats.where((chat) => chat.isActive).length,
        'archivedChats': userChats.where((chat) => !chat.isActive).length,
      };
    } catch (e) {
      debugPrint('Error getting chat statistics: $e');
      return {};
    }
  }
}