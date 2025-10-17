import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_extended.dart';

/// Сервис для работы с реакциями на сообщения
class MessageReactionService {
  factory MessageReactionService() => _instance;
  MessageReactionService._internal();
  static final MessageReactionService _instance = MessageReactionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Добавить реакцию к сообщению
  Future<bool> addReaction({
    required String messageId,
    required String userId,
    required String userName,
    required String emoji,
  }) async {
    try {
      final messageRef = _firestore.collection('chat_messages').doc(messageId);

      // Проверяем, есть ли уже реакция от этого пользователя с этим эмодзи
      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) return false;

      final messageData = messageDoc.data();
      final reactions = (messageData['reactions'] as List<dynamic>?)
              ?.map((e) => MessageReaction.fromMap(e))
              .toList() ??
          [];

      // Удаляем существующую реакцию от этого пользователя с этим эмодзи
      reactions.removeWhere(
        (reaction) => reaction.userId == userId && reaction.emoji == emoji,
      );

      // Добавляем новую реакцию
      final newReaction = MessageReaction(
        id: '${userId}_${emoji}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userName: userName,
        emoji: emoji,
        timestamp: DateTime.now(),
      );

      reactions.add(newReaction);

      // Обновляем сообщение
      await messageRef.update({
        'reactions': reactions.map((e) => e.toMap()).toList(),
      });

      return true;
    } catch (e) {
      print('Ошибка добавления реакции: $e');
      return false;
    }
  }

  /// Удалить реакцию с сообщения
  Future<bool> removeReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      final messageRef = _firestore.collection('chat_messages').doc(messageId);

      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) return false;

      final messageData = messageDoc.data();
      final reactions = (messageData['reactions'] as List<dynamic>?)
              ?.map((e) => MessageReaction.fromMap(e))
              .toList() ??
          [];

      // Удаляем реакцию
      reactions.removeWhere(
        (reaction) => reaction.userId == userId && reaction.emoji == emoji,
      );

      // Обновляем сообщение
      await messageRef.update({
        'reactions': reactions.map((e) => e.toMap()).toList(),
      });

      return true;
    } catch (e) {
      print('Ошибка удаления реакции: $e');
      return false;
    }
  }

  /// Переключить реакцию (добавить, если нет, или удалить, если есть)
  Future<bool> toggleReaction({
    required String messageId,
    required String userId,
    required String userName,
    required String emoji,
  }) async {
    try {
      final messageRef = _firestore.collection('chat_messages').doc(messageId);

      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) return false;

      final messageData = messageDoc.data();
      final reactions = (messageData['reactions'] as List<dynamic>?)
              ?.map((e) => MessageReaction.fromMap(e))
              .toList() ??
          [];

      // Проверяем, есть ли уже реакция от этого пользователя с этим эмодзи
      final existingReactionIndex = reactions.indexWhere(
        (reaction) => reaction.userId == userId && reaction.emoji == emoji,
      );

      if (existingReactionIndex != -1) {
        // Удаляем существующую реакцию
        reactions.removeAt(existingReactionIndex);
      } else {
        // Добавляем новую реакцию
        final newReaction = MessageReaction(
          id: '${userId}_${emoji}_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          userName: userName,
          emoji: emoji,
          timestamp: DateTime.now(),
        );
        reactions.add(newReaction);
      }

      // Обновляем сообщение
      await messageRef.update({
        'reactions': reactions.map((e) => e.toMap()).toList(),
      });

      return true;
    } catch (e) {
      print('Ошибка переключения реакции: $e');
      return false;
    }
  }

  /// Получить все реакции сообщения
  Future<List<MessageReaction>> getMessageReactions(String messageId) async {
    try {
      final messageDoc = await _firestore.collection('chat_messages').doc(messageId).get();
      if (!messageDoc.exists) return [];

      final messageData = messageDoc.data();
      final reactions = (messageData['reactions'] as List<dynamic>?)
              ?.map((e) => MessageReaction.fromMap(e))
              .toList() ??
          [];

      return reactions;
    } catch (e) {
      print('Ошибка получения реакций: $e');
      return [];
    }
  }

  /// Получить статистику реакций для чата
  Future<Map<String, int>> getChatReactionStats(String chatId) async {
    try {
      final messagesQuery =
          await _firestore.collection('chat_messages').where('chatId', isEqualTo: chatId).get();

      final reactionStats = <String, int>{};

      for (final doc in messagesQuery.docs) {
        final messageData = doc.data();
        final reactions = (messageData['reactions'] as List<dynamic>?)
                ?.map((e) => MessageReaction.fromMap(e))
                .toList() ??
            [];

        for (final reaction in reactions) {
          reactionStats[reaction.emoji] = (reactionStats[reaction.emoji] ?? 0) + 1;
        }
      }

      return reactionStats;
    } catch (e) {
      print('Ошибка получения статистики реакций: $e');
      return {};
    }
  }

  /// Получить топ эмодзи для пользователя
  Future<Map<String, int>> getUserReactionStats(String userId) async {
    try {
      final messagesQuery = await _firestore.collection('chat_messages').get();

      final userReactionStats = <String, int>{};

      for (final doc in messagesQuery.docs) {
        final messageData = doc.data();
        final reactions = (messageData['reactions'] as List<dynamic>?)
                ?.map((e) => MessageReaction.fromMap(e))
                .toList() ??
            [];

        for (final reaction in reactions) {
          if (reaction.userId == userId) {
            userReactionStats[reaction.emoji] = (userReactionStats[reaction.emoji] ?? 0) + 1;
          }
        }
      }

      return userReactionStats;
    } catch (e) {
      print('Ошибка получения статистики пользователя: $e');
      return {};
    }
  }

  /// Получить популярные эмодзи
  List<String> getPopularEmojis() => [
        '👍',
        '👎',
        '❤️',
        '😂',
        '😮',
        '😢',
        '😡',
        '🎉',
        '👏',
        '🔥',
        '💯',
        '✨',
        '🎯',
        '🚀',
        '💪',
        '🙌',
        '😍',
        '🤔',
        '😴',
        '🤯',
        '🥳',
        '😎',
        '🤝',
        '💡',
      ];

  /// Получить эмодзи по категориям
  Map<String, List<String>> getEmojisByCategory() => {
        'Позитивные': [
          '👍',
          '❤️',
          '😂',
          '🎉',
          '👏',
          '🔥',
          '💯',
          '✨',
          '🎯',
          '🚀',
          '💪',
          '🙌',
          '😍',
          '🥳',
          '😎',
          '🤝',
          '💡',
        ],
        'Негативные': ['👎', '😢', '😡', '😴'],
        'Удивление': ['😮', '🤔', '🤯'],
        'Другие': [
          '🎊',
          '🎈',
          '🎁',
          '🏆',
          '⭐',
          '🌟',
          '💫',
          '🌈',
          '🦄',
          '🐱',
          '🐶',
          '🦋',
          '🌸',
          '🌺',
          '🌻',
          '🌹',
        ],
      };
}
