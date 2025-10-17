import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Тип сообщения AI
enum AIMessageType {
  user, // Сообщение пользователя
  assistant, // Ответ AI-помощника
  specialist, // Предложение специалиста
  system, // Системное сообщение
}

/// Модель сообщения AI-помощника
@immutable
class AIMessage {
  const AIMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.specialistId,
    this.specialistName,
    this.specialistCategory,
    this.specialistRating,
    this.specialistPrice,
    this.specialistImageUrl,
    this.metadata = const {},
  });

  /// Создать из Map
  factory AIMessage.fromMap(Map<String, dynamic> data) => AIMessage(
        id: data['id'] as String? ?? '',
        type: AIMessageType.values.firstWhere(
          (e) => e.name == (data['type'] as String?),
          orElse: () => AIMessageType.user,
        ),
        content: data['content'] as String? ?? '',
        timestamp:
            data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
        specialistId: data['specialistId'] as String?,
        specialistName: data['specialistName'] as String?,
        specialistCategory: data['specialistCategory'] as String?,
        specialistRating: (data['specialistRating'] as num?)?.toDouble(),
        specialistPrice: (data['specialistPrice'] as num?)?.toDouble(),
        specialistImageUrl: data['specialistImageUrl'] as String?,
        metadata: Map<String, dynamic>.from(
          data['metadata'] as Map<dynamic, dynamic>? ?? {},
        ),
      );

  /// Создать из документа Firestore
  factory AIMessage.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return AIMessage(
      id: doc.id,
      type: AIMessageType.values.firstWhere(
        (e) => e.name == (data['type'] as String?),
        orElse: () => AIMessageType.user,
      ),
      content: data['content'] as String? ?? '',
      timestamp:
          data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
      specialistId: data['specialistId'] as String?,
      specialistName: data['specialistName'] as String?,
      specialistCategory: data['specialistCategory'] as String?,
      specialistRating: (data['specialistRating'] as num?)?.toDouble(),
      specialistPrice: (data['specialistPrice'] as num?)?.toDouble(),
      specialistImageUrl: data['specialistImageUrl'] as String?,
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map<dynamic, dynamic>? ?? {},
      ),
    );
  }

  final String id;
  final AIMessageType type;
  final String content;
  final DateTime timestamp;
  final String? specialistId;
  final String? specialistName;
  final String? specialistCategory;
  final double? specialistRating;
  final double? specialistPrice;
  final String? specialistImageUrl;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'type': type.name,
        'content': content,
        'timestamp': Timestamp.fromDate(timestamp),
        'specialistId': specialistId,
        'specialistName': specialistName,
        'specialistCategory': specialistCategory,
        'specialistRating': specialistRating,
        'specialistPrice': specialistPrice,
        'specialistImageUrl': specialistImageUrl,
        'metadata': metadata,
      };

  /// Копировать с изменениями
  AIMessage copyWith({
    String? id,
    AIMessageType? type,
    String? content,
    DateTime? timestamp,
    String? specialistId,
    String? specialistName,
    String? specialistCategory,
    double? specialistRating,
    double? specialistPrice,
    String? specialistImageUrl,
    Map<String, dynamic>? metadata,
  }) =>
      AIMessage(
        id: id ?? this.id,
        type: type ?? this.type,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        specialistId: specialistId ?? this.specialistId,
        specialistName: specialistName ?? this.specialistName,
        specialistCategory: specialistCategory ?? this.specialistCategory,
        specialistRating: specialistRating ?? this.specialistRating,
        specialistPrice: specialistPrice ?? this.specialistPrice,
        specialistImageUrl: specialistImageUrl ?? this.specialistImageUrl,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, является ли сообщение от пользователя
  bool get isUser => type == AIMessageType.user;

  /// Проверить, является ли сообщение от AI
  bool get isAssistant => type == AIMessageType.assistant;

  /// Проверить, содержит ли сообщение предложение специалиста
  bool get hasSpecialist => specialistId != null;

  /// Получить отображаемое время
  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AIMessage(id: $id, type: $type, content: $content)';
}

/// Расширение для получения названий типов сообщений
extension AIMessageTypeExtension on AIMessageType {
  String get displayName {
    switch (this) {
      case AIMessageType.user:
        return 'Пользователь';
      case AIMessageType.assistant:
        return 'AI-помощник';
      case AIMessageType.specialist:
        return 'Специалист';
      case AIMessageType.system:
        return 'Система';
    }
  }

  String get icon {
    switch (this) {
      case AIMessageType.user:
        return '👤';
      case AIMessageType.assistant:
        return '🤖';
      case AIMessageType.specialist:
        return '⭐';
      case AIMessageType.system:
        return '⚙️';
    }
  }
}
