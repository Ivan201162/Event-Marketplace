import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Модель сообщения в AI-чате
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.userId,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.messageType,
    this.metadata,
  });

  /// Создание из Firestore документа
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      messageType: data['messageType'],
      metadata: data['metadata'],
    );
  }
  final String id;
  final String userId;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? messageType;
  final Map<String, dynamic>? metadata;

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'content': content,
        'isUser': isUser,
        'timestamp': Timestamp.fromDate(timestamp),
        'messageType': messageType,
        'metadata': metadata,
      };

  /// Копирование с изменениями
  ChatMessage copyWith({
    String? id,
    String? userId,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? messageType,
    Map<String, dynamic>? metadata,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        content: content ?? this.content,
        isUser: isUser ?? this.isUser,
        timestamp: timestamp ?? this.timestamp,
        messageType: messageType ?? this.messageType,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ChatMessage(id: $id, isUser: $isUser, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
}

/// Модель сессии AI-чата
class ChatSession {
  const ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messageIds,
    this.context,
  });

  /// Создание из Firestore документа
  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ChatSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp).toDate(),
      messageIds: List<String>.from(data['messageIds'] ?? []),
      context: data['context'],
    );
  }
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final List<String> messageIds;
  final Map<String, dynamic>? context;

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'title': title,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastMessageAt': Timestamp.fromDate(lastMessageAt),
        'messageIds': messageIds,
        'context': context,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ChatSession(id: $id, title: $title, messages: ${messageIds.length})';
}

/// Типы сообщений
enum MessageType {
  text('text', 'Текст'),
  quickReply('quickReply', 'Быстрый ответ'),
  specialistCard('specialistCard', 'Карточка специалиста'),
  bookingSuggestion('bookingSuggestion', 'Предложение бронирования'),
  question('question', 'Вопрос'),
  greeting('greeting', 'Приветствие');

  const MessageType(this.value, this.displayName);
  final String value;
  final String displayName;
}

/// Модель быстрого ответа
class QuickReply {
  const QuickReply({required this.text, required this.value, this.icon});

  factory QuickReply.fromJson(Map<String, dynamic> json) => QuickReply(
        text: json['text'] ?? '',
        value: json['value'] ?? '',
        icon: json['icon'] != null
            ? IconData(json['icon'], fontFamily: 'MaterialIcons')
            : null,
      );
  final String text;
  final String value;
  final IconData? icon;

  Map<String, dynamic> toJson() =>
      {'text': text, 'value': value, 'icon': icon?.codePoint};
}

/// Модель контекста пользователя для AI
class UserContext {
  const UserContext({
    this.city,
    this.eventType,
    this.eventDate,
    this.budget,
    this.preferences = const [],
    this.viewedSpecialists = const [],
    this.categories = const [],
  });

  factory UserContext.fromJson(Map<String, dynamic> json) => UserContext(
        city: json['city'],
        eventType: json['eventType'],
        eventDate: json['eventDate'] != null
            ? DateTime.parse(json['eventDate'])
            : null,
        budget: json['budget'],
        preferences: List<String>.from(json['preferences'] ?? []),
        viewedSpecialists: List<String>.from(json['viewedSpecialists'] ?? []),
        categories: List<String>.from(json['categories'] ?? []),
      );
  final String? city;
  final String? eventType;
  final DateTime? eventDate;
  final int? budget;
  final List<String> preferences;
  final List<String> viewedSpecialists;
  final List<String> categories;

  Map<String, dynamic> toJson() => {
        'city': city,
        'eventType': eventType,
        'eventDate': eventDate?.toIso8601String(),
        'budget': budget,
        'preferences': preferences,
        'viewedSpecialists': viewedSpecialists,
        'categories': categories,
      };

  UserContext copyWith({
    String? city,
    String? eventType,
    DateTime? eventDate,
    int? budget,
    List<String>? preferences,
    List<String>? viewedSpecialists,
    List<String>? categories,
  }) =>
      UserContext(
        city: city ?? this.city,
        eventType: eventType ?? this.eventType,
        eventDate: eventDate ?? this.eventDate,
        budget: budget ?? this.budget,
        preferences: preferences ?? this.preferences,
        viewedSpecialists: viewedSpecialists ?? this.viewedSpecialists,
        categories: categories ?? this.categories,
      );
}
