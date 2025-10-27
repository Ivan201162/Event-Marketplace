import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

import '../models/chat_enhanced.dart';

/// Расширенный сервис для работы с чатами
class ChatServiceEnhanced {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Создание личного чата
  static Future<String> createPersonalChat(String otherUserId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // Проверяем, не существует ли уже чат между этими пользователями
      final existingChat =
          await _findExistingPersonalChat(user.uid, otherUserId);
      if (existingChat != null) return existingChat;

      final chatId = _firestore.collection('chats').doc().id;
      final now = DateTime.now();

      // Получаем данные пользователей
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final otherUserDoc =
          await _firestore.collection('users').doc(otherUserId).get();

      final userData = userDoc.data() ?? {};
      final otherUserData = otherUserDoc.data() ?? {};

      final chat = ChatEnhanced(
        id: chatId,
        name:
            '${userData['name'] ?? 'Пользователь'} & ${otherUserData['name'] ?? 'Пользователь'}',
        description: 'Личный чат',
        avatar: '',
        type: ChatType.personal,
        participants: [user.uid, otherUserId],
        admins: [user.uid],
        unreadCount: 0,
        isMuted: false,
        isPinned: false,
        isArchived: false,
        metadata: {
          'createdBy': user.uid,
          'isPersonal': true,
        },
        createdAt: now,
        updatedAt: now,
        tags: [],
        settings: {
          'allowFileSharing': true,
          'allowVoiceMessages': true,
          'allowStickers': true,
          'allowGifs': true,
        },
        sharedFiles: [],
        analytics: {
          'messageCount': 0,
          'lastActivity': now.toIso8601String(),
        },
      );

      await _firestore.collection('chats').doc(chatId).set(chat.toFirestore());

      // Создаем уведомление для другого пользователя
      await _createNotification(
        userId: otherUserId,
        title: 'Новый чат',
        body: '${userData['name'] ?? 'Пользователь'} начал с вами чат',
        data: {'chatId': chatId, 'type': 'chat_created'},
      );

      return chatId;
    } catch (e) {
      throw Exception('Ошибка создания чата: $e');
    }
  }

  /// Создание группового чата
  static Future<String> createGroupChat({
    required String name,
    required String description,
    required List<String> participants,
    String? avatar,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final chatId = _firestore.collection('chats').doc().id;
      final now = DateTime.now();

      final chat = ChatEnhanced(
        id: chatId,
        name: name,
        description: description,
        avatar: avatar ?? '',
        type: ChatType.group,
        participants: [user.uid, ...participants],
        admins: [user.uid],
        unreadCount: 0,
        isMuted: false,
        isPinned: false,
        isArchived: false,
        metadata: {
          'createdBy': user.uid,
          'isGroup': true,
          'participantCount': participants.length + 1,
        },
        createdAt: now,
        updatedAt: now,
        tags: [],
        settings: {
          'allowFileSharing': true,
          'allowVoiceMessages': true,
          'allowStickers': true,
          'allowGifs': true,
          'allowInvites': true,
        },
        sharedFiles: [],
        analytics: {
          'messageCount': 0,
          'lastActivity': now.toIso8601String(),
        },
      );

      await _firestore.collection('chats').doc(chatId).set(chat.toFirestore());

      // Создаем уведомления для всех участников
      for (final participantId in participants) {
        await _createNotification(
          userId: participantId,
          title: 'Приглашение в группу',
          body: 'Вас пригласили в группу "$name"',
          data: {'chatId': chatId, 'type': 'group_invite'},
        );
      }

      return chatId;
    } catch (e) {
      throw Exception('Ошибка создания группового чата: $e');
    }
  }

  /// Создание чата для заявки
  static Future<String> createRequestChat(String requestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // Получаем данные заявки
      final requestDoc =
          await _firestore.collection('requests').doc(requestId).get();
      if (!requestDoc.exists) throw Exception('Заявка не найдена');

      final requestData = requestDoc.data()!;
      final authorId = requestData['authorId'] as String;

      // Проверяем, не существует ли уже чат для этой заявки
      final existingChat = await _findExistingRequestChat(requestId);
      if (existingChat != null) return existingChat;

      final chatId = _firestore.collection('chats').doc().id;
      final now = DateTime.now();

      final chat = ChatEnhanced(
        id: chatId,
        name: 'Чат по заявке: ${requestData['title']}',
        description: 'Обсуждение заявки',
        avatar: '',
        type: ChatType.request,
        participants: [authorId, user.uid],
        admins: [authorId],
        unreadCount: 0,
        isMuted: false,
        isPinned: false,
        isArchived: false,
        metadata: {
          'requestId': requestId,
          'isRequestChat': true,
        },
        createdAt: now,
        updatedAt: now,
        tags: ['заявка', requestData['category']],
        requestId: requestId,
        settings: {
          'allowFileSharing': true,
          'allowVoiceMessages': true,
          'allowStickers': false,
          'allowGifs': false,
        },
        sharedFiles: [],
        analytics: {
          'messageCount': 0,
          'lastActivity': now.toIso8601String(),
        },
      );

      await _firestore.collection('chats').doc(chatId).set(chat.toFirestore());

      // Создаем уведомление для автора заявки
      await _createNotification(
        userId: authorId,
        title: 'Новый чат по заявке',
        body: 'Кто-то начал обсуждение вашей заявки',
        data: {'chatId': chatId, 'type': 'request_chat'},
      );

      return chatId;
    } catch (e) {
      throw Exception('Ошибка создания чата для заявки: $e');
    }
  }

  /// Получение чатов пользователя
  static Future<List<ChatEnhanced>> getUserChats({
    ChatFilters? filters,
    int limit = 50,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      Query query = _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid);

      // Применяем фильтры
      if (filters != null) {
        if (filters.type != null) {
          query = query.where('type', isEqualTo: filters.type!.value);
        }
        if (filters.isMuted != null) {
          query = query.where('isMuted', isEqualTo: filters.isMuted);
        }
        if (filters.isPinned != null) {
          query = query.where('isPinned', isEqualTo: filters.isPinned);
        }
        if (filters.isArchived != null) {
          query = query.where('isArchived', isEqualTo: filters.isArchived);
        }
        if (filters.requestId != null) {
          query = query.where('requestId', isEqualTo: filters.requestId);
        }
        if (filters.groupId != null) {
          query = query.where('groupId', isEqualTo: filters.groupId);
        }
      }

      // Сортировка
      query = query.orderBy('updatedAt', descending: true);
      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ChatEnhanced.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения чатов: $e');
    }
  }

  /// Получение чата по ID
  static Future<ChatEnhanced?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (doc.exists) {
        return ChatEnhanced.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения чата: $e');
    }
  }

  /// Отправка текстового сообщения
  static Future<String> sendTextMessage({
    required String chatId,
    required String content,
    String? replyToMessageId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final messageId = _firestore.collection('messages').doc().id;
      final now = DateTime.now();

      // Получаем данные пользователя
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Получаем данные чата
      final chat = await getChatById(chatId);
      if (chat == null) throw Exception('Чат не найден');

      // Проверяем, является ли пользователь участником чата
      if (!chat.participants.contains(user.uid)) {
        throw Exception('Нет доступа к чату');
      }

      final message = ChatMessageEnhanced(
        id: messageId,
        chatId: chatId,
        authorId: user.uid,
        authorName: userData['name'] ?? user.displayName ?? 'Пользователь',
        authorAvatar: userData['avatar'] ?? user.photoURL ?? '',
        content: content,
        type: MessageType.text,
        status: MessageStatus.sending,
        createdAt: now,
        attachments: [],
        metadata: {
          'isText': true,
          'wordCount': content.split(' ').length,
          'charCount': content.length,
        },
        reactions: [],
        readBy: [user.uid],
        forwardedTo: [],
        isEdited: false,
        isDeleted: false,
        analytics: {
          'sentAt': now.toIso8601String(),
          'authorId': user.uid,
        },
      );

      // Сохраняем сообщение
      await _firestore
          .collection('messages')
          .doc(messageId)
          .set(message.toFirestore());

      // Обновляем чат
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageId': messageId,
        'lastMessageText': content,
        'lastMessageAuthorId': user.uid,
        'lastMessageTime': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Отправляем уведомления другим участникам
      for (final participantId in chat.participants) {
        if (participantId != user.uid) {
          await _createNotification(
            userId: participantId,
            title: chat.name,
            body: content,
            data: {'chatId': chatId, 'messageId': messageId, 'type': 'message'},
          );
        }
      }

      // Обновляем статус сообщения
      await _firestore.collection('messages').doc(messageId).update({
        'status': MessageStatus.sent.value,
      });

      return messageId;
    } catch (e) {
      throw Exception('Ошибка отправки сообщения: $e');
    }
  }

  /// Отправка изображения
  static Future<String> sendImageMessage({
    required String chatId,
    required String imagePath,
    String? caption,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // Загружаем изображение в Firebase Storage
      final imageUrl = await _uploadFile(imagePath, 'images');

      final messageId = _firestore.collection('messages').doc().id;
      final now = DateTime.now();

      // Получаем данные пользователя
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final message = ChatMessageEnhanced(
        id: messageId,
        chatId: chatId,
        authorId: user.uid,
        authorName: userData['name'] ?? user.displayName ?? 'Пользователь',
        authorAvatar: userData['avatar'] ?? user.photoURL ?? '',
        content: caption ?? '📷 Изображение',
        type: MessageType.image,
        status: MessageStatus.sent,
        createdAt: now,
        attachments: [imageUrl],
        metadata: {
          'isImage': true,
          'imageUrl': imageUrl,
          'caption': caption,
        },
        reactions: [],
        readBy: [user.uid],
        forwardedTo: [],
        isEdited: false,
        isDeleted: false,
        analytics: {
          'sentAt': now.toIso8601String(),
          'authorId': user.uid,
        },
      );

      await _firestore
          .collection('messages')
          .doc(messageId)
          .set(message.toFirestore());

      // Обновляем чат
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageId': messageId,
        'lastMessageText': '📷 Изображение',
        'lastMessageAuthorId': user.uid,
        'lastMessageTime': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      return messageId;
    } catch (e) {
      throw Exception('Ошибка отправки изображения: $e');
    }
  }

  /// Отправка файла
  static Future<String> sendFileMessage({
    required String chatId,
    required String filePath,
    String? caption,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // Загружаем файл в Firebase Storage
      final fileUrl = await _uploadFile(filePath, 'files');

      final messageId = _firestore.collection('messages').doc().id;
      final now = DateTime.now();

      // Получаем данные пользователя
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final fileName = filePath.split('/').last;
      final fileType = _getFileType(fileName);

      final message = ChatMessageEnhanced(
        id: messageId,
        chatId: chatId,
        authorId: user.uid,
        authorName: userData['name'] ?? user.displayName ?? 'Пользователь',
        authorAvatar: userData['avatar'] ?? user.photoURL ?? '',
        content: caption ?? '📎 $fileName',
        type: fileType,
        status: MessageStatus.sent,
        createdAt: now,
        attachments: [fileUrl],
        metadata: {
          'isFile': true,
          'fileUrl': fileUrl,
          'fileName': fileName,
          'fileSize': await _getFileSize(filePath),
          'caption': caption,
        },
        reactions: [],
        readBy: [user.uid],
        forwardedTo: [],
        isEdited: false,
        isDeleted: false,
        analytics: {
          'sentAt': now.toIso8601String(),
          'authorId': user.uid,
        },
      );

      await _firestore
          .collection('messages')
          .doc(messageId)
          .set(message.toFirestore());

      // Обновляем чат
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageId': messageId,
        'lastMessageText': '📎 $fileName',
        'lastMessageAuthorId': user.uid,
        'lastMessageTime': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      return messageId;
    } catch (e) {
      throw Exception('Ошибка отправки файла: $e');
    }
  }

  /// Отправка локации
  static Future<String> sendLocationMessage({
    required String chatId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final messageId = _firestore.collection('messages').doc().id;
      final now = DateTime.now();

      // Получаем данные пользователя
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final message = ChatMessageEnhanced(
        id: messageId,
        chatId: chatId,
        authorId: user.uid,
        authorName: userData['name'] ?? user.displayName ?? 'Пользователь',
        authorAvatar: userData['avatar'] ?? user.photoURL ?? '',
        content: address ?? '📍 Локация',
        type: MessageType.location,
        status: MessageStatus.sent,
        createdAt: now,
        attachments: [],
        metadata: {
          'isLocation': true,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        },
        reactions: [],
        readBy: [user.uid],
        forwardedTo: [],
        isEdited: false,
        isDeleted: false,
        analytics: {
          'sentAt': now.toIso8601String(),
          'authorId': user.uid,
        },
      );

      await _firestore
          .collection('messages')
          .doc(messageId)
          .set(message.toFirestore());

      // Обновляем чат
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageId': messageId,
        'lastMessageText': '📍 Локация',
        'lastMessageAuthorId': user.uid,
        'lastMessageTime': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      return messageId;
    } catch (e) {
      throw Exception('Ошибка отправки локации: $e');
    }
  }

  /// Получение сообщений чата
  static Future<List<ChatMessageEnhanced>> getChatMessages({
    required String chatId,
    MessageFilters? filters,
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('isDeleted', isEqualTo: false);

      // Применяем фильтры
      if (filters != null) {
        if (filters.type != null) {
          query = query.where('type', isEqualTo: filters.type!.value);
        }
        if (filters.authorId != null) {
          query = query.where('authorId', isEqualTo: filters.authorId);
        }
        if (filters.hasAttachments != null) {
          if (filters.hasAttachments!) {
            query = query.where('attachments', isNotEqualTo: []);
          }
        }
        if (filters.hasReactions != null) {
          if (filters.hasReactions!) {
            query = query.where('reactions', isNotEqualTo: []);
          }
        }
        if (filters.isEdited != null) {
          query = query.where('isEdited', isEqualTo: filters.isEdited);
        }
      }

      // Сортировка
      query = query.orderBy('createdAt', descending: true);

      // Пагинация
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ChatMessageEnhanced.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения сообщений: $e');
    }
  }

  /// Добавление реакции к сообщению
  static Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final reaction = MessageReaction(
        id: '${messageId}_${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        userName: userData['name'] ?? 'Пользователь',
        emoji: emoji,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('messages').doc(messageId).update({
        'reactions': FieldValue.arrayUnion([reaction.toMap()]),
      });
    } catch (e) {
      throw Exception('Ошибка добавления реакции: $e');
    }
  }

  /// Удаление реакции
  static Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // Получаем сообщение
      final messageDoc =
          await _firestore.collection('messages').doc(messageId).get();
      if (!messageDoc.exists) throw Exception('Сообщение не найдено');

      final messageData = messageDoc.data()!;
      final reactions = (messageData['reactions'] as List<dynamic>?)
              ?.map((e) => MessageReaction.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [];

      // Находим реакцию пользователя с этим эмодзи
      final userReaction = reactions.firstWhere(
        (r) => r.userId == user.uid && r.emoji == emoji,
        orElse: () => throw Exception('Реакция не найдена'),
      );

      await _firestore.collection('messages').doc(messageId).update({
        'reactions': FieldValue.arrayRemove([userReaction.toMap()]),
      });
    } catch (e) {
      throw Exception('Ошибка удаления реакции: $e');
    }
  }

  /// Отметка сообщений как прочитанных
  static Future<void> markMessagesAsRead(String chatId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // Получаем непрочитанные сообщения
      final messagesQuery = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('authorId', isNotEqualTo: user.uid)
          .where('readBy', arrayContains: user.uid)
          .get();

      // Обновляем статус сообщений
      for (final doc in messagesQuery.docs) {
        await _firestore.collection('messages').doc(doc.id).update({
          'readBy': FieldValue.arrayUnion([user.uid]),
          'readAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      // Обновляем счетчик непрочитанных в чате
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      throw Exception('Ошибка отметки сообщений как прочитанных: $e');
    }
  }

  /// Поиск сообщений
  static Future<List<ChatMessageEnhanced>> searchMessages({
    required String chatId,
    required String query,
    MessageFilters? filters,
  }) async {
    try {
      // Firestore не поддерживает полнотекстовый поиск
      // Получаем все сообщения и фильтруем локально
      final allMessages = await getChatMessages(chatId: chatId, limit: 1000);

      return allMessages.where((message) {
        if (filters != null) {
          if (filters.type != null && message.type != filters.type)
            return false;
          if (filters.authorId != null && message.authorId != filters.authorId)
            return false;
          if (filters.hasAttachments != null) {
            if (filters.hasAttachments! && message.attachments.isEmpty)
              return false;
            if (!filters.hasAttachments! && message.attachments.isNotEmpty)
              return false;
          }
          if (filters.hasReactions != null) {
            if (filters.hasReactions! && message.reactions.isEmpty)
              return false;
            if (!filters.hasReactions! && message.reactions.isNotEmpty)
              return false;
          }
          if (filters.isEdited != null && message.isEdited != filters.isEdited)
            return false;
        }

        return message.content.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      throw Exception('Ошибка поиска сообщений: $e');
    }
  }

  /// Вспомогательные методы
  static Future<ChatEnhanced?> _findExistingPersonalChat(
      String userId1, String userId2) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('type', isEqualTo: ChatType.personal.value)
          .where('participants', arrayContains: userId1)
          .get();

      for (final doc in snapshot.docs) {
        final chat = ChatEnhanced.fromFirestore(doc);
        if (chat.participants.contains(userId2)) {
          return chat;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<ChatEnhanced?> _findExistingRequestChat(
      String requestId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('requestId', isEqualTo: requestId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ChatEnhanced.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String> _uploadFile(String filePath, String folder) async {
    // Здесь должна быть реализация загрузки файла в Firebase Storage
    // Пока возвращаем путь к файлу
    return filePath;
  }

  static MessageType _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return MessageType.image;
    } else if (['mp4', 'avi', 'mov', 'wmv'].contains(extension)) {
      return MessageType.video;
    } else if (['mp3', 'wav', 'aac', 'ogg'].contains(extension)) {
      return MessageType.audio;
    } else {
      return MessageType.file;
    }
  }

  static Future<int> _getFileSize(String filePath) async {
    final file = File(filePath);
    return await file.length();
  }

  static Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка создания уведомления: $e');
    }
  }
}
