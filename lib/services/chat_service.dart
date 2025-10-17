import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat.dart';

/// Сервис для работы с чатами
class ChatService {
  factory ChatService() => _instance;
  ChatService._internal();
  static final ChatService _instance = ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final String _messagesCollection = 'messages';
  final String _chatsCollection = 'chats';

  // Кэш для локального хранения
  static const String _cacheKey = 'chat_cache';
  static const int _maxCachedMessages = 20;

  /// Получить сообщения чата
  Stream<List<ChatMessage>> getChatMessages(String chatId) => _firestore
      .collection(_messagesCollection)
      .where('chatId', isEqualTo: chatId)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(ChatMessage.fromDocument).toList());

  /// Отправить текстовое сообщение
  Future<String?> sendTextMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? senderName,
  }) async {
    try {
      final message = ChatMessage(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName ?? 'Пользователь',
        type: MessageType.text,
        content: text,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        isFromCurrentUser: true,
      );

      final docRef = await _firestore.collection(_messagesCollection).add(message.toMap());

      // Обновляем последнее сообщение в чате
      await _updateLastMessage(chatId, message);

      // Отправляем уведомление
      await _sendMessageNotification(chatId, senderId, text);

      // Сохраняем в кэш
      await _saveToCache(chatId, message);

      return docRef.id;
    } on Exception catch (e) {
      debugPrint('Ошибка отправки текстового сообщения: $e');
      return null;
    }
  }

  /// Отправить изображение
  Future<String?> sendImageMessage({
    required String chatId,
    required String senderId,
    String? senderName,
  }) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Загружаем изображение в Storage
      final imageUrl = await _uploadFile(image, 'images');
      if (imageUrl == null) return null;

      final message = ChatMessage(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName ?? 'Пользователь',
        type: MessageType.image,
        content: imageUrl,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        isFromCurrentUser: true,
      );

      final docRef = await _firestore.collection(_messagesCollection).add(message.toMap());
      return docRef.id;
    } on Exception catch (e) {
      debugPrint('Ошибка отправки изображения: $e');
      return null;
    }
  }

  /// Отправить видео
  Future<String?> sendVideoMessage({
    required String chatId,
    required String senderId,
    String? senderName,
  }) async {
    try {
      final video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video == null) return null;

      // Загружаем видео в Storage
      final videoUrl = await _uploadFile(video, 'videos');
      if (videoUrl == null) return null;

      final message = ChatMessage(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName ?? 'Пользователь',
        type: MessageType.video,
        content: videoUrl,
        fileName: video.path.split('/').last,
        fileSize: await File(video.path).length(),
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        isFromCurrentUser: true,
      );

      final docRef = await _firestore.collection(_messagesCollection).add(message.toMap());

      // Обновляем последнее сообщение в чате
      await _updateLastMessage(chatId, message);

      // Отправляем уведомление
      await _sendMessageNotification(chatId, senderId, 'Видео');

      return docRef.id;
    } on Exception catch (e) {
      debugPrint('Ошибка отправки видео: $e');
      return null;
    }
  }

  /// Отправить аудио сообщение
  Future<String?> sendAudioMessage({
    required String chatId,
    required String senderId,
    String? senderName,
    required File audioFile,
    int? duration,
  }) async {
    try {
      // Загружаем аудио в Storage
      final audioUrl = await _uploadFile(audioFile, 'audio');
      if (audioUrl == null) return null;

      final message = ChatMessage(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName ?? 'Пользователь',
        type: MessageType.audio,
        content: audioUrl,
        fileName: audioFile.path.split('/').last,
        fileSize: await audioFile.length(),
        metadata: duration != null ? {'duration': duration} : null,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        isFromCurrentUser: true,
      );

      final docRef = await _firestore.collection(_messagesCollection).add(message.toMap());

      // Обновляем последнее сообщение в чате
      await _updateLastMessage(chatId, message);

      // Отправляем уведомление
      await _sendMessageNotification(chatId, senderId, 'Аудио сообщение');

      return docRef.id;
    } on Exception catch (e) {
      debugPrint('Ошибка отправки аудио: $e');
      return null;
    }
  }

  /// Отправить документ
  Future<String?> sendDocumentMessage({
    required String chatId,
    required String senderId,
    required File file,
    String? senderName,
  }) async {
    try {
      // Загружаем документ в Storage
      final fileUrl = await _uploadFile(file, 'documents');
      if (fileUrl == null) return null;

      final message = ChatMessage(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName ?? 'Пользователь',
        type: MessageType.document,
        content: fileUrl,
        fileName: file.path.split('/').last,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        isFromCurrentUser: true,
      );

      final docRef = await _firestore.collection(_messagesCollection).add(message.toMap());
      return docRef.id;
    } on Exception catch (e) {
      debugPrint('Ошибка отправки документа: $e');
      return null;
    }
  }

  /// Загрузить файл в Storage
  Future<String?> _uploadFile(file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('$folder/$fileName');

      UploadTask uploadTask;
      if (file is XFile) {
        uploadTask = ref.putFile(File(file.path));
      } else if (file is File) {
        uploadTask = ref.putFile(file);
      } else {
        throw Exception('Неподдерживаемый тип файла');
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on Exception catch (e) {
      debugPrint('Ошибка загрузки файла: $e');
      return null;
    }
  }

  /// Создать или получить чат между пользователями
  Future<String?> getOrCreateChat(String userId1, String userId2) async {
    try {
      // Ищем существующий чат
      final existingChat = await _firestore
          .collection(_chatsCollection)
          .where('participants', arrayContains: userId1)
          .get();

      for (final doc in existingChat.docs) {
        final data = doc.data();
        final participantsData = data['participants'] as List<dynamic>? ?? [];
        final participants = List<String>.from(participantsData);
        if (participants.contains(userId2)) {
          return doc.id;
        }
      }

      // Создаем новый чат
      final chatData = {
        'participants': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageAt': null,
      };

      final docRef = await _firestore.collection(_chatsCollection).add(chatData);
      return docRef.id;
    } on Exception catch (e) {
      debugPrint('Ошибка создания/получения чата: $e');
      return null;
    }
  }

  /// Получить список чатов пользователя
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) => _firestore
      .collection(_chatsCollection)
      .where('participants', arrayContains: userId)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList(),
      );

  /// Отметить сообщения как прочитанные
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final batch = _firestore.batch();

      final messages = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in messages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } on Exception catch (e) {
      debugPrint('Ошибка отметки сообщений как прочитанных: $e');
    }
  }

  /// Удалить сообщение
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).delete();
      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка удаления сообщения: $e');
      return false;
    }
  }

  /// Редактировать сообщение
  Future<bool> editMessage(String messageId, String newText) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).update({
        'text': newText,
        'editedAt': FieldValue.serverTimestamp(),
        'isEdited': true,
      });
      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка редактирования сообщения: $e');
      return false;
    }
  }

  /// Получить количество непрочитанных сообщений
  Stream<int> getUnreadMessagesCount(String userId) => _firestore
      .collection(_messagesCollection)
      .where('receiverId', isEqualTo: userId)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);

  /// Поиск сообщений
  Future<List<ChatMessage>> searchMessages(String chatId, String query) async {
    try {
      final snapshot = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThan: '$query\uf8ff')
          .get();

      return snapshot.docs.map(ChatMessage.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка поиска сообщений: $e');
      return [];
    }
  }

  /// Обновить последнее сообщение в чате
  Future<void> _updateLastMessage(String chatId, ChatMessage message) async {
    try {
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'lastMessageContent': message.content,
        'lastMessageType': message.type.name,
        'lastMessageTime': message.timestamp != null
            ? Timestamp.fromDate(message.timestamp!)
            : Timestamp.fromDate(message.createdAt),
        'lastMessageSenderId': message.senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка обновления последнего сообщения: $e');
    }
  }

  /// Отправить уведомление о новом сообщении
  Future<void> _sendMessageNotification(
    String chatId,
    String senderId,
    String messageContent,
  ) async {
    try {
      // Получаем информацию о чате
      final chatDoc = await _firestore.collection(_chatsCollection).doc(chatId).get();
      if (!chatDoc.exists) return;

      final chatData = chatDoc.data()!;
      final participantsData = chatData['participants'] as List<dynamic>? ?? [];
      final participants = List<String>.from(participantsData);

      // Находим получателя (не отправителя)
      final receiverId = participants.firstWhere(
        (id) => id != senderId,
        orElse: () => participants.first,
      );

      // Отправляем уведомление (заглушка)
      debugPrint(
        'Отправка уведомления пользователю $receiverId: Новое сообщение',
      );
    } on Exception catch (e) {
      debugPrint('Ошибка отправки уведомления: $e');
    }
  }

  /// Сохранить сообщение в локальный кэш
  Future<void> _saveToCache(String chatId, ChatMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKey}_$chatId';

      // Получаем существующий кэш
      final cachedData = prefs.getString(cacheKey);
      var messages = <Map<String, dynamic>>[];

      if (cachedData != null) {
        final dynamic decoded = json.decode(cachedData);
        if (decoded is List) {
          messages = decoded.cast<Map<String, dynamic>>();
        }
      }

      // Добавляем новое сообщение
      messages.add(message.toMap());

      // Ограничиваем количество кэшированных сообщений
      if (messages.length > _maxCachedMessages) {
        messages = messages.sublist(messages.length - _maxCachedMessages);
      }

      // Сохраняем обновленный кэш
      await prefs.setString(cacheKey, json.encode(messages));
    } on Exception catch (e) {
      debugPrint('Ошибка сохранения в кэш: $e');
    }
  }

  /// Получить кэшированные сообщения
  Future<List<ChatMessage>> getCachedMessages(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKey}_$chatId';
      final cachedData = prefs.getString(cacheKey);

      if (cachedData == null) return [];

      final dynamic decoded = json.decode(cachedData);
      if (decoded is! List) return [];

      return decoded
          .map(
            (data) => ChatMessage.fromMap(data as Map<String, dynamic>),
          )
          .toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения кэша: $e');
      return [];
    }
  }

  /// Выбрать файл для отправки
  Future<String?> pickAndSendFile({
    required String chatId,
    required String senderId,
    String? senderName,
  }) async {
    try {
      // Запрашиваем разрешение на доступ к файлам
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        debugPrint('Нет разрешения на доступ к файлам');
        return null;
      }

      final result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final fileName = result.files.first.name;
        final fileSize = result.files.first.size;

        // Определяем тип файла
        MessageType messageType;
        if (fileName.toLowerCase().endsWith('.jpg') ||
            fileName.toLowerCase().endsWith('.jpeg') ||
            fileName.toLowerCase().endsWith('.png') ||
            fileName.toLowerCase().endsWith('.gif')) {
          messageType = MessageType.image;
        } else if (fileName.toLowerCase().endsWith('.mp4') ||
            fileName.toLowerCase().endsWith('.avi') ||
            fileName.toLowerCase().endsWith('.mov')) {
          messageType = MessageType.video;
        } else if (fileName.toLowerCase().endsWith('.mp3') ||
            fileName.toLowerCase().endsWith('.wav') ||
            fileName.toLowerCase().endsWith('.aac')) {
          messageType = MessageType.audio;
        } else {
          messageType = MessageType.document;
        }

        // Загружаем файл в Storage
        final fileUrl = await _uploadFile(file, 'documents');
        if (fileUrl == null) return null;

        final message = ChatMessage(
          id: '',
          chatId: chatId,
          senderId: senderId,
          senderName: senderName ?? 'Пользователь',
          type: messageType,
          content: fileUrl,
          fileUrl: fileUrl,
          fileName: fileName,
          fileSize: fileSize,
          status: MessageStatus.sent,
          createdAt: DateTime.now(),
          isFromCurrentUser: true,
        );

        final docRef = await _firestore.collection(_messagesCollection).add(message.toMap());

        // Обновляем последнее сообщение в чате
        await _updateLastMessage(chatId, message);

        // Отправляем уведомление
        await _sendMessageNotification(chatId, senderId, fileName);

        return docRef.id;
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Ошибка выбора и отправки файла: $e');
      return null;
    }
  }

  /// Получить количество непрочитанных сообщений для пользователя
  Stream<int> getUnreadMessagesCountForUser(String userId) => _firestore
          .collection(_messagesCollection)
          .where('senderId', isNotEqualTo: userId)
          .where('readBy', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
        // Подсчитываем сообщения, которые не прочитаны текущим пользователем
        var count = 0;
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final readByData = data['readBy'] as List<dynamic>? ?? [];
          final readBy = List<String>.from(readByData);
          if (!readBy.contains(userId)) {
            count++;
          }
        }
        return count;
      });

  /// Получить чаты пользователя как Stream
  Stream<List<Chat>> getUserChatsStream(String userId) {
    try {
      return _firestore
          .collection(_chatsCollection)
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(Chat.fromDocument).toList());
    } on Exception {
      // Возвращаем тестовые данные в случае ошибки
      return Stream.value([]);
    }
  }

  /// Создать новый чат
  Future<String> createChat({
    required List<String> participants,
    required Map<String, String> participantNames,
    Map<String, String>? participantAvatars,
    String? name,
  }) async {
    try {
      final chat = Chat(
        id: '',
        customerId: participants.first,
        specialistId: participants.length > 1 ? participants[1] : participants.first,
        name: name ?? '',
        participants: participants,
        participantNames: participantNames,
        participantAvatars: participantAvatars ?? {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection(_chatsCollection).add(chat.toMap());
      return docRef.id;
    } on Exception catch (e) {
      throw Exception('Ошибка создания чата: $e');
    }
  }

  /// Обновить чат
  Future<void> updateChat(String chatId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        ...updates,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      throw Exception('Ошибка обновления чата: $e');
    }
  }

  /// Удалить чат
  Future<void> deleteChat(String chatId) async {
    try {
      // Удаляем все сообщения чата
      final messagesSnapshot =
          await _firestore.collection(_messagesCollection).where('chatId', isEqualTo: chatId).get();

      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Удаляем сам чат
      batch.delete(_firestore.collection(_chatsCollection).doc(chatId));
      await batch.commit();
    } on Exception catch (e) {
      throw Exception('Ошибка удаления чата: $e');
    }
  }

  /// Тестовые данные для чатов
  List<Chat> _getTestChats(String userId) {
    final now = DateTime.now();
    return [
      Chat(
        id: '1',
        customerId: userId,
        specialistId: 'user2',
        name: '',
        participants: [userId, 'user2'],
        participantNames: {
          userId: 'Вы',
          'user2': 'Анна Петрова',
        },
        participantAvatars: {
          'user2': 'https://placehold.co/100x100/4CAF50/white?text=AP',
        },
        lastMessageContent: 'Спасибо за отличную работу!',
        lastMessageTime: now.subtract(const Duration(minutes: 30)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      ),
      Chat(
        id: '2',
        customerId: userId,
        specialistId: 'user3',
        name: '',
        participants: [userId, 'user3'],
        participantNames: {
          userId: 'Вы',
          'user3': 'Михаил Соколов',
        },
        participantAvatars: {
          'user3': 'https://placehold.co/100x100/2196F3/white?text=MS',
        },
        lastMessageContent: 'Когда можем встретиться?',
        lastMessageTime: now.subtract(const Duration(hours: 2)),
        unreadCount: 2,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      Chat(
        id: '3',
        customerId: userId,
        specialistId: 'user4',
        name: '',
        participants: [userId, 'user4'],
        participantNames: {
          userId: 'Вы',
          'user4': 'Елена Козлова',
        },
        participantAvatars: {
          'user4': 'https://placehold.co/100x100/FF9800/white?text=EK',
        },
        lastMessageContent: 'Отправлю фото завтра',
        lastMessageTime: now.subtract(const Duration(days: 1)),
        unreadCount: 1,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
