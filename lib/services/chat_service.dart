import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/chat.dart';

/// Service for managing chats and messages
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage? _storage = kIsWeb ? null : FirebaseStorage.instance;
  static const String _chatsCollection = 'chats';
  static const String _messagesCollection = 'messages';

  /// Get user's chats
  Future<List<Chat>> getUserChats(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_chatsCollection)
          .where('members', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user chats: $e');
      return [];
    }
  }

  /// Get or create direct chat between two users
  Future<String?> getOrCreateDirectChat(String userId1, String userId2) async {
    try {
      // Check if chat already exists
      final existingChats = await _firestore
          .collection(_chatsCollection)
          .where('members', arrayContains: userId1)
          .get();

      for (final doc in existingChats.docs) {
        final chat = Chat.fromFirestore(doc);
        if (chat.members.contains(userId2) && !chat.isGroup) {
          return doc.id;
        }
      }

      // Create new chat
      final chat = Chat(
        id: '', // Will be set by Firestore
        members: [userId1, userId2],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: userId1,
      );

      final docRef = await _firestore.collection(_chatsCollection).add(chat.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error getting or creating direct chat: $e');
      return null;
    }
  }

  /// Create group chat
  Future<String?> createGroupChat({
    required String createdBy,
    required List<String> members,
    required String name,
    String? imageUrl,
  }) async {
    try {
      final chat = Chat(
        id: '', // Will be set by Firestore
        members: members,
        name: name,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isGroup: true,
        createdBy: createdBy,
      );

      final docRef = await _firestore.collection(_chatsCollection).add(chat.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating group chat: $e');
      return null;
    }
  }

  /// Get chat by ID
  Future<Chat?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection(_chatsCollection).doc(chatId).get();
      if (doc.exists) {
        return Chat.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting chat by ID: $e');
      return null;
    }
  }

  /// Get messages for a chat
  Future<List<Message>> getChatMessages(String chatId, {int limit = 50, DocumentSnapshot? lastDocument}) async {
    try {
      Query query = _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
      return [];
    }
  }

  /// Send text message
  Future<String?> sendTextMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? senderName,
    String? senderAvatarUrl,
    String? replyToMessageId,
    String? replyToMessageText,
  }) async {
    try {
      final message = Message(
        id: '', // Will be set by Firestore
        chatId: chatId,
        senderId: senderId,
        text: text,
        type: MessageType.text,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        replyToMessageId: replyToMessageId,
        replyToMessageText: replyToMessageText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection(_messagesCollection).add(message.toFirestore());
      
      // Update chat with last message info
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': DateTime.now(),
        'lastMessageSenderId': senderId,
        'updatedAt': DateTime.now(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error sending text message: $e');
      return null;
    }
  }

  /// Send media message
  Future<String?> sendMediaMessage({
    required String chatId,
    required String senderId,
    required String mediaUrl,
    required MessageType type,
    String? text,
    String? senderName,
    String? senderAvatarUrl,
    String? fileName,
    int? fileSize,
  }) async {
    try {
      final message = Message(
        id: '', // Will be set by Firestore
        chatId: chatId,
        senderId: senderId,
        text: text,
        mediaUrl: mediaUrl,
        type: type,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        fileName: fileName,
        fileSize: fileSize,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection(_messagesCollection).add(message.toFirestore());
      
      // Update chat with last message info
      final lastMessageText = text ?? _getMediaMessageText(type);
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'lastMessage': lastMessageText,
        'lastMessageTime': DateTime.now(),
        'lastMessageSenderId': senderId,
        'updatedAt': DateTime.now(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error sending media message: $e');
      return null;
    }
  }

  /// Mark message as read
  Future<bool> markMessageAsRead(String messageId, String userId) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).update({
        'readBy': FieldValue.arrayUnion([userId]),
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error marking message as read: $e');
      return false;
    }
  }

  /// Mark all messages in chat as read
  Future<bool> markChatAsRead(String chatId, String userId) async {
    try {
      // Reset unread count for user
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'unreadCounts.$userId': 0,
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error marking chat as read: $e');
      return false;
    }
  }

  /// Delete message
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  /// Update chat info
  Future<bool> updateChat(String chatId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        ...updates,
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating chat: $e');
      return false;
    }
  }

  /// Add member to group chat
  Future<bool> addMemberToChat(String chatId, String userId, String userName, String? userAvatarUrl) async {
    try {
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'members': FieldValue.arrayUnion([userId]),
        'memberNames.$userId': userName,
        'memberAvatars.$userId': userAvatarUrl,
        'unreadCounts.$userId': 0,
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding member to chat: $e');
      return false;
    }
  }

  /// Remove member from group chat
  Future<bool> removeMemberFromChat(String chatId, String userId) async {
    try {
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'members': FieldValue.arrayRemove([userId]),
        'memberNames.$userId': FieldValue.delete(),
        'memberAvatars.$userId': FieldValue.delete(),
        'unreadCounts.$userId': FieldValue.delete(),
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error removing member from chat: $e');
      return false;
    }
  }

  /// Upload media file
  Future<String?> uploadMedia(String filePath, String fileName) async {
    if (_storage == null) {
      debugPrint('Firebase Storage not available on web');
      return null;
    }
    try {
      final ref = _storage.ref().child('chat_media/$fileName');
      final uploadTask = await ref.putFile(filePath as dynamic); // In real app, use File
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading media: $e');
      return null;
    }
  }

  /// Get unread messages count for user
  Future<int> getUnreadMessagesCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_chatsCollection)
          .where('members', arrayContains: userId)
          .get();

      int totalUnread = 0;
      for (final doc in snapshot.docs) {
        final chat = Chat.fromFirestore(doc);
        totalUnread += chat.getUnreadCount(userId);
      }
      
      return totalUnread;
    } catch (e) {
      debugPrint('Error getting unread messages count: $e');
      return 0;
    }
  }

  /// Stream of user's chats
  Stream<List<Chat>> getUserChatsStream(String userId, {int limit = 20}) {
    return _firestore
        .collection(_chatsCollection)
        .where('members', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Chat.fromFirestore(doc))
            .toList());
  }

  /// Stream of chat messages
  Stream<List<Message>> getChatMessagesStream(String chatId, {int limit = 50}) {
    return _firestore
        .collection(_messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .toList());
  }

  /// Stream of unread messages count
  Stream<int> getUnreadMessagesCountStream(String userId) {
    return _firestore
        .collection(_chatsCollection)
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (final doc in snapshot.docs) {
        final chat = Chat.fromFirestore(doc);
        totalUnread += chat.getUnreadCount(userId);
      }
      return totalUnread;
    });
  }

  /// Helper method to get media message text
  String _getMediaMessageText(MessageType type) {
    switch (type) {
      case MessageType.image:
        return '🖼️ Фото';
      case MessageType.video:
        return '🎥 Видео';
      case MessageType.file:
        return '📎 Файл';
      case MessageType.text:
      case MessageType.system:
        return '';
    }
  }
}