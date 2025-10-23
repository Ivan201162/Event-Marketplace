import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enhanced_chat.dart';
import '../models/enhanced_message.dart';

/// Сервис для работы с расширенными чатами
class EnhancedChatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить чаты пользователя
  Future<List<EnhancedChat>> getUserChats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('members', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => EnhancedChat.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения чатов пользователя: $e');
      return [];
    }
  }

  /// Получить сообщения чата
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
            (doc) => EnhancedMessage.fromMap(
                {'id': doc.id, ...(doc.data()! as Map<String, dynamic>)}),
          )
          .toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения сообщений чата: $e');
      return [];
    }
  }

  /// Отправить сообщение
  Future<String> sendMessage(EnhancedMessage message) async {
    try {
      final docRef = await _firestore
          .collection('chats')
          .doc(message.chatId)
          .collection('messages')
          .add(message.toMap());

      // Обновить последнее сообщение в чате
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
      debugPrint('Ошибка отправки сообщения: $e');
      rethrow;
    }
  }

  /// Отправить текстовое сообщение
  Future<String> sendTextMessage(
    String chatId,
    String senderId,
    String text, {
    MessageReply? replyTo,
  }) async {
    final message = EnhancedMessage(
      id: '', // Будет установлен при создании
      chatId: chatId,
      senderId: senderId,
      text: text,
      type: MessageType.text,
      createdAt: DateTime.now(),
      replyTo: replyTo,
    );

    return sendMessage(message);
  }

  /// Отправить медиа сообщение
  Future<String> sendMediaMessage(
    String chatId,
    String senderId,
    List<MessageAttachment> attachments, {
    String? caption,
    MessageReply? replyTo,
  }) async {
    final messageType = _getMessageTypeFromAttachments(attachments);

    final message = EnhancedMessage(
      id: '', // Будет установлен при создании
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

  /// Отправить голосовое сообщение
  Future<String> sendVoiceMessage(
    String chatId,
    String senderId,
    MessageAttachment voiceAttachment, {
    MessageReply? replyTo,
  }) async {
    final message = EnhancedMessage(
      id: '', // Будет установлен при создании
      chatId: chatId,
      senderId: senderId,
      text: '🎤 Голосовое сообщение',
      type: MessageType.audio,
      createdAt: DateTime.now(),
      attachments: [voiceAttachment],
      replyTo: replyTo,
    );

    return sendMessage(message);
  }

  /// Переслать сообщение
  Future<String> forwardMessage(
    String originalMessageId,
    String originalChatId,
    String newChatId,
    String senderId,
  ) async {
    try {
      // Получить оригинальное сообщение
      final originalDoc = await _firestore
          .collection('chats')
          .doc(originalChatId)
          .collection('messages')
          .doc(originalMessageId)
          .get();

      if (!originalDoc.exists) {
        throw Exception('Оригинальное сообщение не найдено');
      }

      final originalMessage = EnhancedMessage.fromMap({
        'id': originalDoc.id,
        ...originalDoc.data()!,
      });

      // Создать пересланное сообщение
      final forwardedMessage = originalMessage.copyWith(
        id: '', // Будет установлен при создании
        chatId: newChatId,
        senderId: senderId,
        text: 'Пересланное сообщение',
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
      debugPrint('Ошибка пересылки сообщения: $e');
      rethrow;
    }
  }

  /// Редактировать сообщение
  Future<void> editMessage(
      String chatId, String messageId, String newText) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update(
        {'text': newText, 'editedAt': FieldValue.serverTimestamp()},
      );
    } on Exception catch (e) {
      debugPrint('Ошибка редактирования сообщения: $e');
      rethrow;
    }
  }

  /// Удалить сообщение
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update(
        {
          'deletedAt': FieldValue.serverTimestamp(),
          'text': 'Сообщение удалено'
        },
      );
    } on Exception catch (e) {
      debugPrint('Ошибка удаления сообщения: $e');
      rethrow;
    }
  }

  /// Добавить реакцию на сообщение
  Future<void> addReaction(
      String chatId, String messageId, String userId, String emoji) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update(
        {
          'reactions.$emoji': FieldValue.arrayUnion([userId]),
        },
      );
    } on Exception catch (e) {
      debugPrint('Ошибка добавления реакции: $e');
      rethrow;
    }
  }

  /// Удалить реакцию с сообщения
  Future<void> removeReaction(
      String chatId, String messageId, String userId, String emoji) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update(
        {
          'reactions.$emoji': FieldValue.arrayRemove([userId]),
        },
      );
    } on Exception catch (e) {
      debugPrint('Ошибка удаления реакции: $e');
      rethrow;
    }
  }

  /// Отметить сообщения как прочитанные
  Future<void> markMessagesAsRead(
      String chatId, String userId, List<String> messageIds) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final messageId in messageIds) {
        final messageRef = _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId);

        batch
            .update(messageRef, {'readBy.$userId': now.millisecondsSinceEpoch});
      }

      await batch.commit();
    } on Exception catch (e) {
      debugPrint('Ошибка отметки сообщений как прочитанных: $e');
      rethrow;
    }
  }

  /// Создать новый чат
  Future<String> createChat(EnhancedChat chat) async {
    try {
      final docRef = await _firestore.collection('chats').add(chat.toMap());
      return docRef.id;
    } on Exception catch (e) {
      debugPrint('Ошибка создания чата: $e');
      rethrow;
    }
  }

  /// Создать личный чат
  Future<String> createDirectChat(String userId1, String userId2) async {
    try {
      // Проверить, существует ли уже чат между этими пользователями
      final existingChats = await _firestore
          .collection('chats')
          .where('type', isEqualTo: ChatType.direct.value)
          .where('members', arrayContains: userId1)
          .get();

      for (final doc in existingChats.docs) {
        final chat = EnhancedChat.fromMap({'id': doc.id, ...doc.data()});

        if (chat.members.any((member) => member.userId == userId2)) {
          return doc.id; // Чат уже существует
        }
      }

      // Создать новый чат
      final chat = EnhancedChat(
        id: '', // Будет установлен при создании
        type: ChatType.direct,
        members: [
          ChatMember(
              userId: userId1,
              role: ChatMemberRole.member,
              joinedAt: DateTime.now()),
          ChatMember(
              userId: userId2,
              role: ChatMemberRole.member,
              joinedAt: DateTime.now()),
        ],
        createdAt: DateTime.now(),
      );

      return await createChat(chat);
    } on Exception catch (e) {
      debugPrint('Ошибка создания личного чата: $e');
      rethrow;
    }
  }

  /// Создать групповой чат
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
            joinedAt: DateTime.now()),
        ...memberIds.map(
          (userId) => ChatMember(
              userId: userId,
              role: ChatMemberRole.member,
              joinedAt: DateTime.now()),
        ),
      ];

      final chat = EnhancedChat(
        id: '', // Будет установлен при создании
        type: ChatType.group,
        members: members,
        createdAt: DateTime.now(),
        name: name,
        description: description,
        avatarUrl: avatarUrl,
      );

      return await createChat(chat);
    } on Exception catch (e) {
      debugPrint('Ошибка создания группового чата: $e');
      rethrow;
    }
  }

  /// Закрепить чат
  Future<void> pinChat(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isPinned': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка закрепления чата: $e');
      rethrow;
    }
  }

  /// Открепить чат
  Future<void> unpinChat(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isPinned': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка открепления чата: $e');
      rethrow;
    }
  }

  /// Заглушить чат
  Future<void> muteChat(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isMuted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка заглушения чата: $e');
      rethrow;
    }
  }

  /// Разглушить чат
  Future<void> unmuteChat(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isMuted': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка разглушения чата: $e');
      rethrow;
    }
  }

  /// Архивировать чат
  Future<void> archiveChat(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isArchived': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка архивирования чата: $e');
      rethrow;
    }
  }

  /// Разархивировать чат
  Future<void> unarchiveChat(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isArchived': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка разархивирования чата: $e');
      rethrow;
    }
  }

  /// Поиск по чатам
  Future<List<EnhancedChat>> searchChats(String userId, String query) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('members', arrayContains: userId)
          .get();

      final chats = snapshot.docs
          .map((doc) => EnhancedChat.fromMap({'id': doc.id, ...doc.data()}))
          .toList();

      // Фильтрация по названию и последнему сообщению
      return chats.where((chat) {
        final nameMatch =
            chat.name?.toLowerCase().contains(query.toLowerCase()) ?? false;
        final lastMessageMatch = chat.lastMessage?.text
                .toLowerCase()
                .contains(query.toLowerCase()) ??
            false;
        return nameMatch || lastMessageMatch;
      }).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка поиска по чатам: $e');
      return [];
    }
  }

  /// Поиск по сообщениям в чате
  Future<List<EnhancedMessage>> searchMessages(
      String chatId, String query) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('text', isGreaterThanOrEqualTo: query)
          .where('text', isLessThan: '${query}z')
          .get();

      return snapshot.docs
          .map((doc) => EnhancedMessage.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } on Exception catch (e) {
      debugPrint('Ошибка поиска по сообщениям: $e');
      return [];
    }
  }

  /// Получить тип сообщения на основе вложений
  MessageType _getMessageTypeFromAttachments(
      List<MessageAttachment> attachments) {
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
