import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event.dart';
import '../models/group_chat.dart';

/// Сервис для работы с групповыми чатами
class GroupChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать групповой чат для мероприятия
  Future<String> createGroupChatForEvent(Event event) async {
    try {
      // Проверяем, не существует ли уже чат для этого мероприятия
      final existingChat = await _firestore
          .collection('group_chats')
          .where('eventId', isEqualTo: event.id)
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) {
        return existingChat.docs.first.id;
      }

      // Создаем новый групповой чат
      final chatData = {
        'eventId': event.id,
        'eventTitle': event.title,
        'organizerId': event.organizerId,
        'organizerName': event.organizerName,
        'participants': [
          {
            'userId': event.organizerId,
            'userName': event.organizerName,
            'type': GroupChatParticipantType.organizer.name,
            'joinedAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'canSendMessages': true,
            'canUploadFiles': true,
          },
        ],
        'lastActivityAt': FieldValue.serverTimestamp(),
        'unreadCount': 0,
        'isActive': true,
        'allowGuestUploads': true,
        'allowGuestMessages': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'settings': {
          'maxParticipants': 50,
          'allowFileUploads': true,
          'allowImageUploads': true,
          'allowVideoUploads': true,
          'maxFileSize': 10 * 1024 * 1024, // 10MB
        },
      };

      final docRef = await _firestore.collection('group_chats').add(chatData);

      debugPrint('Created group chat for event: ${event.title}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating group chat: $e');
      throw Exception('Ошибка создания группового чата: $e');
    }
  }

  /// Добавить участника в групповой чат
  Future<void> addParticipantToChat(
      String chatId, GroupChatParticipant participant) async {
    try {
      await _firestore.collection('group_chats').doc(chatId).update({
        'participants': FieldValue.arrayUnion([participant.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Added participant ${participant.userName} to chat $chatId');
    } catch (e) {
      debugPrint('Error adding participant to chat: $e');
      throw Exception('Ошибка добавления участника в чат: $e');
    }
  }

  /// Удалить участника из группового чата
  Future<void> removeParticipantFromChat(String chatId, String userId) async {
    try {
      final chatDoc =
          await _firestore.collection('group_chats').doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Чат не найден');
      }

      final chat = GroupChat.fromMap(chatDoc.data()!);
      final participant = chat.participants.firstWhere(
        (p) => p.userId == userId,
        orElse: () => throw Exception('Участник не найден'),
      );

      await _firestore.collection('group_chats').doc(chatId).update({
        'participants': FieldValue.arrayRemove([participant.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Removed participant $userId from chat $chatId');
    } catch (e) {
      debugPrint('Error removing participant from chat: $e');
      throw Exception('Ошибка удаления участника из чата: $e');
    }
  }

  /// Отправить сообщение в групповой чат
  Future<String> sendMessage(String chatId, GroupChatMessage message) async {
    try {
      // Добавляем сообщение в коллекцию сообщений
      final messageRef = await _firestore
          .collection('group_chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // Обновляем информацию о последнем сообщении в чате
      await _firestore.collection('group_chats').doc(chatId).update({
        'lastMessage': message.toMap(),
        'lastActivityAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Sent message to chat $chatId');
      return messageRef.id;
    } catch (e) {
      debugPrint('Error sending message: $e');
      throw Exception('Ошибка отправки сообщения: $e');
    }
  }

  /// Получить сообщения группового чата
  Stream<List<GroupChatMessage>> getChatMessages(String chatId) => _firestore
      .collection('group_chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) =>
                GroupChatMessage.fromMap({'id': doc.id, ...doc.data()}))
            .toList(),
      );

  /// Получить групповой чат по ID
  Future<GroupChat?> getGroupChat(String chatId) async {
    try {
      final doc = await _firestore.collection('group_chats').doc(chatId).get();
      if (!doc.exists) {
        return null;
      }

      return GroupChat.fromMap({'id': doc.id, ...doc.data()!});
    } catch (e) {
      debugPrint('Error getting group chat: $e');
      return null;
    }
  }

  /// Получить групповой чат по ID мероприятия
  Future<GroupChat?> getGroupChatByEventId(String eventId) async {
    try {
      final query = await _firestore
          .collection('group_chats')
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;
      return GroupChat.fromMap({'id': doc.id, ...doc.data()});
    } catch (e) {
      debugPrint('Error getting group chat by event ID: $e');
      return null;
    }
  }

  /// Получить все групповые чаты пользователя
  Stream<List<GroupChat>> getUserGroupChats(String userId) => _firestore
      .collection('group_chats')
      .where('participants',
          arrayContains: {'userId': userId, 'isActive': true})
      .orderBy('lastActivityAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => GroupChat.fromMap({'id': doc.id, ...doc.data()}))
            .toList(),
      );

  /// Добавить гостя в чат по ссылке
  Future<void> addGuestToChat(
      String chatId, String guestName, String? guestPhoto) async {
    try {
      final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final guest = GroupChatParticipant(
        userId: guestId,
        userName: guestName,
        userPhoto: guestPhoto,
        type: GroupChatParticipantType.guest,
        joinedAt: DateTime.now(),
      );

      await addParticipantToChat(chatId, guest);
      debugPrint('Added guest $guestName to chat $chatId');
    } catch (e) {
      debugPrint('Error adding guest to chat: $e');
      throw Exception('Ошибка добавления гостя в чат: $e');
    }
  }

  /// Загрузить файл в чат
  Future<String> uploadFileToChat(
    String chatId,
    String fileName,
    String fileUrl,
    String uploadedBy,
    GroupChatMessageType fileType,
  ) async {
    try {
      final message = GroupChatMessage(
        id: '',
        chatId: chatId,
        senderId: uploadedBy,
        senderName: 'Гость', // TODO(developer): Получить реальное имя
        content: fileName,
        type: fileType,
        createdAt: DateTime.now(),
        metadata: {
          'fileName': fileName,
          'fileUrl': fileUrl,
          'fileSize': 0, // TODO(developer): Получить реальный размер
        },
      );

      return await sendMessage(chatId, message);
    } catch (e) {
      debugPrint('Error uploading file to chat: $e');
      throw Exception('Ошибка загрузки файла в чат: $e');
    }
  }

  /// Отправить поздравление от гостя
  Future<String> sendGuestGreeting(
    String chatId,
    String guestName,
    String greetingText,
    String? imageUrl,
  ) async {
    try {
      final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final message = GroupChatMessage(
        id: '',
        chatId: chatId,
        senderId: guestId,
        senderName: guestName,
        content: greetingText,
        type: GroupChatMessageType.greeting,
        createdAt: DateTime.now(),
        metadata: imageUrl != null ? {'imageUrl': imageUrl} : null,
      );

      return await sendMessage(chatId, message);
    } catch (e) {
      debugPrint('Error sending guest greeting: $e');
      throw Exception('Ошибка отправки поздравления: $e');
    }
  }

  /// Обновить настройки чата
  Future<void> updateChatSettings(
      String chatId, Map<String, dynamic> settings) async {
    try {
      await _firestore.collection('group_chats').doc(chatId).update({
        'settings': settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Updated chat settings for $chatId');
    } catch (e) {
      debugPrint('Error updating chat settings: $e');
      throw Exception('Ошибка обновления настроек чата: $e');
    }
  }

  /// Закрыть групповой чат
  Future<void> closeGroupChat(String chatId) async {
    try {
      await _firestore.collection('group_chats').doc(chatId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Closed group chat $chatId');
    } catch (e) {
      debugPrint('Error closing group chat: $e');
      throw Exception('Ошибка закрытия группового чата: $e');
    }
  }

  /// Получить статистику чата
  Future<Map<String, dynamic>> getChatStats(String chatId) async {
    try {
      final messagesQuery = await _firestore
          .collection('group_chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final messages = messagesQuery.docs;
      final totalMessages = messages.length;

      final messageTypes = <String, int>{};
      final participants = <String>{};

      for (final doc in messages) {
        final data = doc.data();
        final type = data['type'] as String;
        final senderId = data['senderId'] as String;

        messageTypes[type] = (messageTypes[type] ?? 0) + 1;
        participants.add(senderId);
      }

      return {
        'totalMessages': totalMessages,
        'uniqueParticipants': participants.length,
        'messageTypes': messageTypes,
        'lastActivity':
            messages.isNotEmpty ? messages.first.data()['createdAt'] : null,
      };
    } catch (e) {
      debugPrint('Error getting chat stats: $e');
      return {};
    }
  }
}
