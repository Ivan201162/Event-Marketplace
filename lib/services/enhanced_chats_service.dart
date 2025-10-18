import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/enhanced_chat.dart';
import 'package:flutter/foundation.dart';
import '../models/enhanced_message.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЂР°Р±РѕС‚С‹ СЃ СЂР°СЃС€РёСЂРµРЅРЅС‹РјРё С‡Р°С‚Р°РјРё
class EnhancedChatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// РџРѕР»СѓС‡РёС‚СЊ С‡Р°С‚С‹ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<List<EnhancedChat>> getUserChats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('members', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => EnhancedChat.fromMap({
              'id': doc.id,
              ...doc.data(),
            }),
          )
          .toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‡Р°С‚РѕРІ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРѕРѕР±С‰РµРЅРёСЏ С‡Р°С‚Р°
  Future<List<EnhancedMessage>> getChatMessages(
    String chatId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map(
            (doc) => EnhancedMessage.fromMap({
              'id': doc.id,
              ...(doc.data()! as Map<String, dynamic>),
            }),
          )
          .toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРѕРѕР±С‰РµРЅРёР№ С‡Р°С‚Р°: $e');
      return [];
    }
  }

  /// РћС‚РїСЂР°РІРёС‚СЊ СЃРѕРѕР±С‰РµРЅРёРµ
  Future<String> sendMessage(EnhancedMessage message) async {
    try {
      final docRef = await _firestore
          .collection('chats')
          .doc(message.chatId)
          .collection('messages')
          .add(message.toMap());

      // РћР±РЅРѕРІРёС‚СЊ РїРѕСЃР»РµРґРЅРµРµ СЃРѕРѕР±С‰РµРЅРёРµ РІ С‡Р°С‚Рµ
      await _firestore.collection('chats').doc(message.chatId).update({
        'lastMessage': {
          'id': docRef.id,
          'senderId': message.senderId,
          'text': message.text,
          'type': message.type.value,
          'createdAt': message.createdAt.millisecondsSinceEpoch,
          'attachments': message.attachments.map((a) => a.toMap()).toList(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РїСЂР°РІРєРё СЃРѕРѕР±С‰РµРЅРёСЏ: $e');
      rethrow;
    }
  }

  /// РћС‚РїСЂР°РІРёС‚СЊ С‚РµРєСЃС‚РѕРІРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ
  Future<String> sendTextMessage(
    String chatId,
    String senderId,
    String text, {
    MessageReply? replyTo,
  }) async {
    final message = EnhancedMessage(
      id: '', // Р‘СѓРґРµС‚ СѓСЃС‚Р°РЅРѕРІР»РµРЅ РїСЂРё СЃРѕР·РґР°РЅРёРё
      chatId: chatId,
      senderId: senderId,
      text: text,
      type: MessageType.text,
      createdAt: DateTime.now(),
      replyTo: replyTo,
    );

    return sendMessage(message);
  }

  /// РћС‚РїСЂР°РІРёС‚СЊ РјРµРґРёР° СЃРѕРѕР±С‰РµРЅРёРµ
  Future<String> sendMediaMessage(
    String chatId,
    String senderId,
    List<MessageAttachment> attachments, {
    String? caption,
    MessageReply? replyTo,
  }) async {
    final messageType = _getMessageTypeFromAttachments(attachments);

    final message = EnhancedMessage(
      id: '', // Р‘СѓРґРµС‚ СѓСЃС‚Р°РЅРѕРІР»РµРЅ РїСЂРё СЃРѕР·РґР°РЅРёРё
      chatId: chatId,
      senderId: senderId,
      text: caption ?? '',
      type: messageType,
      createdAt: DateTime.now(),
      attachments: attachments,
      replyTo: replyTo,
    );

    return sendMessage(message);
  }

  /// РћС‚РїСЂР°РІРёС‚СЊ РіРѕР»РѕСЃРѕРІРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ
  Future<String> sendVoiceMessage(
    String chatId,
    String senderId,
    MessageAttachment voiceAttachment, {
    MessageReply? replyTo,
  }) async {
    final message = EnhancedMessage(
      id: '', // Р‘СѓРґРµС‚ СѓСЃС‚Р°РЅРѕРІР»РµРЅ РїСЂРё СЃРѕР·РґР°РЅРёРё
      chatId: chatId,
      senderId: senderId,
      text: 'рџЋ¤ Р“РѕР»РѕСЃРѕРІРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ',
      type: MessageType.audio,
      createdAt: DateTime.now(),
      attachments: [voiceAttachment],
      replyTo: replyTo,
    );

    return sendMessage(message);
  }

  /// РџРµСЂРµСЃР»Р°С‚СЊ СЃРѕРѕР±С‰РµРЅРёРµ
  Future<String> forwardMessage(
    String originalMessageId,
    String originalChatId,
    String newChatId,
    String senderId,
  ) async {
    try {
      // РџРѕР»СѓС‡РёС‚СЊ РѕСЂРёРіРёРЅР°Р»СЊРЅРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ
      final originalDoc = await _firestore
          .collection('chats')
          .doc(originalChatId)
          .collection('messages')
          .doc(originalMessageId)
          .get();

      if (!originalDoc.exists) {
        throw Exception('РћСЂРёРіРёРЅР°Р»СЊРЅРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ РЅРµ РЅР°Р№РґРµРЅРѕ');
      }

      final originalMessage = EnhancedMessage.fromMap({
        'id': originalDoc.id,
        ...originalDoc.data()!,
      });

      // РЎРѕР·РґР°С‚СЊ РїРµСЂРµСЃР»Р°РЅРЅРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ
      final forwardedMessage = originalMessage.copyWith(
        id: '', // Р‘СѓРґРµС‚ СѓСЃС‚Р°РЅРѕРІР»РµРЅ РїСЂРё СЃРѕР·РґР°РЅРёРё
        chatId: newChatId,
        senderId: senderId,
        text: 'РџРµСЂРµСЃР»Р°РЅРЅРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ',
        forwardedFrom: MessageForward(
          originalMessageId: originalMessageId,
          originalChatId: originalChatId,
          originalSenderId: originalMessage.senderId,
          forwardedAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
      );

      return await sendMessage(forwardedMessage);
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРµСЂРµСЃС‹Р»РєРё СЃРѕРѕР±С‰РµРЅРёСЏ: $e');
      rethrow;
    }
  }

  /// Р РµРґР°РєС‚РёСЂРѕРІР°С‚СЊ СЃРѕРѕР±С‰РµРЅРёРµ
  Future<void> editMessage(
    String chatId,
    String messageId,
    String newText,
  ) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'text': newText,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЂРµРґР°РєС‚РёСЂРѕРІР°РЅРёСЏ СЃРѕРѕР±С‰РµРЅРёСЏ: $e');
      rethrow;
    }
  }

  /// РЈРґР°Р»РёС‚СЊ СЃРѕРѕР±С‰РµРЅРёРµ
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'deletedAt': FieldValue.serverTimestamp(),
        'text': 'РЎРѕРѕР±С‰РµРЅРёРµ СѓРґР°Р»РµРЅРѕ',
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ СЃРѕРѕР±С‰РµРЅРёСЏ: $e');
      rethrow;
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ СЂРµР°РєС†РёСЋ РЅР° СЃРѕРѕР±С‰РµРЅРёРµ
  Future<void> addReaction(
    String chatId,
    String messageId,
    String userId,
    String emoji,
  ) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$emoji': FieldValue.arrayUnion([userId]),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ СЂРµР°РєС†РёРё: $e');
      rethrow;
    }
  }

  /// РЈРґР°Р»РёС‚СЊ СЂРµР°РєС†РёСЋ СЃ СЃРѕРѕР±С‰РµРЅРёСЏ
  Future<void> removeReaction(
    String chatId,
    String messageId,
    String userId,
    String emoji,
  ) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$emoji': FieldValue.arrayRemove([userId]),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ СЂРµР°РєС†РёРё: $e');
      rethrow;
    }
  }

  /// РћС‚РјРµС‚РёС‚СЊ СЃРѕРѕР±С‰РµРЅРёСЏ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅС‹Рµ
  Future<void> markMessagesAsRead(
    String chatId,
    String userId,
    List<String> messageIds,
  ) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final messageId in messageIds) {
        final messageRef =
            _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId);

        batch.update(messageRef, {
          'readBy.$userId': now.millisecondsSinceEpoch,
        });
      }

      await batch.commit();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РјРµС‚РєРё СЃРѕРѕР±С‰РµРЅРёР№ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅС‹С…: $e');
      rethrow;
    }
  }

  /// РЎРѕР·РґР°С‚СЊ РЅРѕРІС‹Р№ С‡Р°С‚
  Future<String> createChat(EnhancedChat chat) async {
    try {
      final docRef = await _firestore.collection('chats').add(chat.toMap());
      return docRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ С‡Р°С‚Р°: $e');
      rethrow;
    }
  }

  /// РЎРѕР·РґР°С‚СЊ Р»РёС‡РЅС‹Р№ С‡Р°С‚
  Future<String> createDirectChat(String userId1, String userId2) async {
    try {
      // РџСЂРѕРІРµСЂРёС‚СЊ, СЃСѓС‰РµСЃС‚РІСѓРµС‚ Р»Рё СѓР¶Рµ С‡Р°С‚ РјРµР¶РґСѓ СЌС‚РёРјРё РїРѕР»СЊР·РѕРІР°С‚РµР»СЏРјРё
      final existingChats = await _firestore
          .collection('chats')
          .where('type', isEqualTo: ChatType.direct.value)
          .where('members', arrayContains: userId1)
          .get();

      for (final doc in existingChats.docs) {
        final chat = EnhancedChat.fromMap({
          'id': doc.id,
          ...doc.data(),
        });

        if (chat.members.any((member) => member.userId == userId2)) {
          return doc.id; // Р§Р°С‚ СѓР¶Рµ СЃСѓС‰РµСЃС‚РІСѓРµС‚
        }
      }

      // РЎРѕР·РґР°С‚СЊ РЅРѕРІС‹Р№ С‡Р°С‚
      final chat = EnhancedChat(
        id: '', // Р‘СѓРґРµС‚ СѓСЃС‚Р°РЅРѕРІР»РµРЅ РїСЂРё СЃРѕР·РґР°РЅРёРё
        type: ChatType.direct,
        members: [
          ChatMember(
            userId: userId1,
            role: ChatMemberRole.member,
            joinedAt: DateTime.now(),
          ),
          ChatMember(
            userId: userId2,
            role: ChatMemberRole.member,
            joinedAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
      );

      return await createChat(chat);
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ Р»РёС‡РЅРѕРіРѕ С‡Р°С‚Р°: $e');
      rethrow;
    }
  }

  /// РЎРѕР·РґР°С‚СЊ РіСЂСѓРїРїРѕРІРѕР№ С‡Р°С‚
  Future<String> createGroupChat(
    String creatorId,
    String name,
    List<String> memberIds, {
    String? description,
    String? avatarUrl,
  }) async {
    try {
      final members = <ChatMember>[
        ChatMember(
          userId: creatorId,
          role: ChatMemberRole.owner,
          joinedAt: DateTime.now(),
        ),
        ...memberIds.map(
          (userId) => ChatMember(
            userId: userId,
            role: ChatMemberRole.member,
            joinedAt: DateTime.now(),
          ),
        ),
      ];

      final chat = EnhancedChat(
        id: '', // Р‘СѓРґРµС‚ СѓСЃС‚Р°РЅРѕРІР»РµРЅ РїСЂРё СЃРѕР·РґР°РЅРёРё
        type: ChatType.group,
        members: members,
        createdAt: DateTime.now(),
        name: name,
        description: description,
        avatarUrl: avatarUrl,
      );

      return await createChat(chat);
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ РіСЂСѓРїРїРѕРІРѕРіРѕ С‡Р°С‚Р°: $e');
      rethrow;
    }
  }

  /// Р—Р°РєСЂРµРїРёС‚СЊ С‡Р°С‚
  Future<void> pinChat(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isPinned': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° Р·Р°РєСЂРµРїР»РµРЅРёСЏ С‡Р°С‚Р°: $e');
      rethrow;
    }
  }

  /// РћС‚РєСЂРµРїРёС‚СЊ С‡Р°С‚
  Future<void> unpinChat(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isPinned': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РєСЂРµРїР»РµРЅРёСЏ С‡Р°С‚Р°: $e');
      rethrow;
    }
  }

  /// Р—Р°РіР»СѓС€РёС‚СЊ С‡Р°С‚
  Future<void> muteChat(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isMuted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° Р·Р°РіР»СѓС€РµРЅРёСЏ С‡Р°С‚Р°: $e');
      rethrow;
    }
  }

  /// Р Р°Р·РіР»СѓС€РёС‚СЊ С‡Р°С‚
  Future<void> unmuteChat(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isMuted': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЂР°Р·РіР»СѓС€РµРЅРёСЏ С‡Р°С‚Р°: $e');
      rethrow;
    }
  }

  /// РђСЂС…РёРІРёСЂРѕРІР°С‚СЊ С‡Р°С‚
  Future<void> archiveChat(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isArchived': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° Р°СЂС…РёРІРёСЂРѕРІР°РЅРёСЏ С‡Р°С‚Р°: $e');
      rethrow;
    }
  }

  /// Р Р°Р·Р°СЂС…РёРІРёСЂРѕРІР°С‚СЊ С‡Р°С‚
  Future<void> unarchiveChat(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isArchived': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЂР°Р·Р°СЂС…РёРІРёСЂРѕРІР°РЅРёСЏ С‡Р°С‚Р°: $e');
      rethrow;
    }
  }

  /// РџРѕРёСЃРє РїРѕ С‡Р°С‚Р°Рј
  Future<List<EnhancedChat>> searchChats(String userId, String query) async {
    try {
      final snapshot =
          await _firestore.collection('chats').where('members', arrayContains: userId).get();

      final chats = snapshot.docs
          .map(
            (doc) => EnhancedChat.fromMap({
              'id': doc.id,
              ...doc.data(),
            }),
          )
          .toList();

      // Р¤РёР»СЊС‚СЂР°С†РёСЏ РїРѕ РЅР°Р·РІР°РЅРёСЋ Рё РїРѕСЃР»РµРґРЅРµРјСѓ СЃРѕРѕР±С‰РµРЅРёСЋ
      return chats.where((chat) {
        final nameMatch = chat.name?.toLowerCase().contains(query.toLowerCase()) ?? false;
        final lastMessageMatch =
            chat.lastMessage?.text.toLowerCase().contains(query.toLowerCase()) ?? false;
        return nameMatch || lastMessageMatch;
      }).toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕРёСЃРєР° РїРѕ С‡Р°С‚Р°Рј: $e');
      return [];
    }
  }

  /// РџРѕРёСЃРє РїРѕ СЃРѕРѕР±С‰РµРЅРёСЏРј РІ С‡Р°С‚Рµ
  Future<List<EnhancedMessage>> searchMessages(
    String chatId,
    String query,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('text', isGreaterThanOrEqualTo: query)
          .where('text', isLessThan: '${query}z')
          .get();

      return snapshot.docs
          .map(
            (doc) => EnhancedMessage.fromMap({
              'id': doc.id,
              ...doc.data(),
            }),
          )
          .toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕРёСЃРєР° РїРѕ СЃРѕРѕР±С‰РµРЅРёСЏРј: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ С‚РёРї СЃРѕРѕР±С‰РµРЅРёСЏ РЅР° РѕСЃРЅРѕРІРµ РІР»РѕР¶РµРЅРёР№
  MessageType _getMessageTypeFromAttachments(
    List<MessageAttachment> attachments,
  ) {
    if (attachments.isEmpty) return MessageType.text;

    final firstAttachment = attachments.first;
    switch (firstAttachment.type) {
      case MessageAttachmentType.image:
        return MessageType.image;
      case MessageAttachmentType.video:
        return MessageType.video;
      case MessageAttachmentType.audio:
      case MessageAttachmentType.voice:
        return MessageType.audio;
      case MessageAttachmentType.document:
        return MessageType.document;
      case MessageAttachmentType.sticker:
        return MessageType.sticker;
    }
  }
}

