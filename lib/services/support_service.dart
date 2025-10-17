import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Сервис системы поддержки
class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Отправить сообщение в чат поддержки
  Future<String> sendMessage({
    required String userId,
    required String message,
    required MessageType type,
    String? attachmentUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final supportMessage = SupportMessage(
        id: '', // Будет сгенерирован Firestore
        userId: userId,
        message: message,
        type: type,
        attachmentUrl: attachmentUrl,
        metadata: metadata ?? {},
        isFromUser: true,
        isRead: false,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('support_messages').add(supportMessage.toMap());

      // Если сообщение от пользователя, генерируем ответ бота
      if (type == MessageType.text && isFromUser) {
        await _generateBotResponse(userId, message, docRef.id);
      }

      return docRef.id;
    } on Exception {
      // Логирование:'Ошибка отправки сообщения в поддержку: $e');
      rethrow;
    }
  }

  /// Получить сообщения чата поддержки
  Stream<List<SupportMessage>> getSupportMessages(String userId) => _firestore
      .collection('support_messages')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(SupportMessage.fromDocument).toList(),
      );

  /// Получить FAQ
  Future<List<FAQItem>> getFAQ() async {
    try {
      final snapshot = await _firestore.collection('faq').orderBy('order').get();

      return snapshot.docs.map(FAQItem.fromDocument).toList();
    } on Exception {
      // Логирование:'Ошибка получения FAQ: $e');
      return [];
    }
  }

  /// Поиск в FAQ
  Future<List<FAQItem>> searchFAQ(String query) async {
    try {
      final snapshot = await _firestore.collection('faq').get();

      final allFAQ = snapshot.docs.map(FAQItem.fromDocument).toList();

      // Простой поиск по заголовку и содержанию
      return allFAQ.where((item) {
        final titleMatch = item.title.toLowerCase().contains(query.toLowerCase());
        final contentMatch = item.content.toLowerCase().contains(query.toLowerCase());
        return titleMatch || contentMatch;
      }).toList();
    } on Exception {
      // Логирование:'Ошибка поиска в FAQ: $e');
      return [];
    }
  }

  /// Передать чат live-оператору
  Future<void> transferToLiveOperator(String userId, String reason) async {
    try {
      await _firestore.collection('support_transfers').add({
        'userId': userId,
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Отправляем уведомление операторам
      await _firestore.collection('support_messages').add({
        'userId': userId,
        'message': 'Запрос на передачу чата live-оператору: $reason',
        'type': 'system',
        'isFromUser': false,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on Exception {
      // Логирование:'Ошибка передачи чата оператору: $e');
      rethrow;
    }
  }

  /// Получить статус передачи чата
  Future<TransferStatus> getTransferStatus(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('support_transfers')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return TransferStatus.notRequested;
      }

      final data = snapshot.docs.first.data();
      final status = data['status'] as String?;

      switch (status) {
        case 'pending':
          return TransferStatus.pending;
        case 'accepted':
          return TransferStatus.accepted;
        case 'rejected':
          return TransferStatus.rejected;
        default:
          return TransferStatus.notRequested;
      }
    } on Exception {
      // Логирование:'Ошибка получения статуса передачи: $e');
      return TransferStatus.notRequested;
    }
  }

  /// Отметить сообщение как прочитанное
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection('support_messages').doc(messageId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } on Exception {
      // Логирование:'Ошибка отметки сообщения как прочитанного: $e');
    }
  }

  /// Получить статистику поддержки
  Future<SupportStats> getSupportStats(String userId) async {
    try {
      final messagesSnapshot =
          await _firestore.collection('support_messages').where('userId', isEqualTo: userId).get();

      final messages = messagesSnapshot.docs.map(SupportMessage.fromDocument).toList();

      final totalMessages = messages.length;
      final unreadMessages = messages.where((m) => !m.isRead && !m.isFromUser).length;
      final lastMessage = messages.isNotEmpty ? messages.last.createdAt : null;

      return SupportStats(
        userId: userId,
        totalMessages: totalMessages,
        unreadMessages: unreadMessages,
        lastMessageAt: lastMessage,
        lastUpdated: DateTime.now(),
      );
    } on Exception {
      // Логирование:'Ошибка получения статистики поддержки: $e');
      return SupportStats.empty();
    }
  }

  // ========== ПРИВАТНЫЕ МЕТОДЫ ==========

  /// Генерировать ответ бота
  Future<void> _generateBotResponse(
    String userId,
    String userMessage,
    String messageId,
  ) async {
    try {
      // Простая логика ответов бота на основе ключевых слов
      final response = _getBotResponse(userMessage);

      if (response != null) {
        await Future.delayed(const Duration(seconds: 2)); // Имитация задержки

        final botMessage = SupportMessage(
          id: '', // Будет сгенерирован Firestore
          userId: userId,
          message: response,
          type: MessageType.text,
          isFromUser: false,
          isRead: false,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('support_messages').add(botMessage.toMap());
      }
    } on Exception {
      // Логирование:'Ошибка генерации ответа бота: $e');
    }
  }

  /// Получить ответ бота на основе сообщения пользователя
  String? _getBotResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    // Простые правила для ответов бота
    if (message.contains('привет') || message.contains('здравствуйте')) {
      return 'Привет! Я бот поддержки Event Marketplace. Чем могу помочь?';
    }

    if (message.contains('заказ') || message.contains('бронирование')) {
      return 'Для вопросов по заказам и бронированию, пожалуйста, укажите номер заказа или опишите проблему подробнее.';
    }

    if (message.contains('оплата') || message.contains('деньги')) {
      return 'Вопросы по оплате решаются в разделе "Мои заказы". Если проблема не решается, передам вас live-оператору.';
    }

    if (message.contains('отмена') || message.contains('возврат')) {
      return 'Для отмены заказа или возврата средств обратитесь к live-оператору. Нажмите кнопку "Передать оператору".';
    }

    if (message.contains('техническая') ||
        message.contains('ошибка') ||
        message.contains('не работает')) {
      return 'Технические проблемы передам разработчикам. Опишите проблему подробнее или передайте чат live-оператору.';
    }

    if (message.contains('спасибо') || message.contains('благодарю')) {
      return 'Пожалуйста! Рад был помочь. Если возникнут еще вопросы, обращайтесь!';
    }

    // Если не найдено подходящего ответа, предлагаем передать оператору
    return 'Я не совсем понял ваш вопрос. Могу передать вас live-оператору для более детальной помощи.';
  }
}

/// Тип сообщения
enum MessageType {
  text,
  image,
  file,
  system,
}

/// Статус передачи чата
enum TransferStatus {
  notRequested,
  pending,
  accepted,
  rejected,
}

/// Модель сообщения поддержки
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.userId,
    required this.message,
    required this.type,
    this.attachmentUrl,
    this.metadata = const {},
    required this.isFromUser,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory SupportMessage.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SupportMessage(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      attachmentUrl: data['attachmentUrl'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      isFromUser: data['isFromUser'] as bool? ?? true,
      isRead: data['isRead'] as bool? ?? false,
      createdAt:
          data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
    );
  }

  final String id;
  final String userId;
  final String message;
  final MessageType type;
  final String? attachmentUrl;
  final Map<String, dynamic> metadata;
  final bool isFromUser;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'message': message,
        'type': type.name,
        'attachmentUrl': attachmentUrl,
        'metadata': metadata,
        'isFromUser': isFromUser,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
        'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      };
}

/// Модель FAQ
class FAQItem {
  const FAQItem({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.order,
    this.tags = const [],
  });

  factory FAQItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return FAQItem(
      id: doc.id,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      category: data['category'] as String? ?? '',
      order: data['order'] as int? ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  final String id;
  final String title;
  final String content;
  final String category;
  final int order;
  final List<String> tags;
}

/// Статистика поддержки
class SupportStats {
  const SupportStats({
    required this.userId,
    required this.totalMessages,
    required this.unreadMessages,
    this.lastMessageAt,
    required this.lastUpdated,
  });

  factory SupportStats.empty() => SupportStats(
        userId: '',
        totalMessages: 0,
        unreadMessages: 0,
        lastUpdated: DateTime.now(),
      );

  final String userId;
  final int totalMessages;
  final int unreadMessages;
  final DateTime? lastMessageAt;
  final DateTime lastUpdated;
}
