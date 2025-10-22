import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Типы чатов
enum ChatType {
  direct('direct'),
  group('group'),
  support('support');

  const ChatType(this.value);
  final String value;

  static ChatType fromString(String value) {
    return ChatType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ChatType.direct,
    );
  }
}

/// Модель чата
class Chat extends Equatable {
  final String id;
  final String name;
  final String? description;
  final ChatType type;
  final List<String> participants;
  final String? lastMessageId;
  final String? lastMessageContent;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  final bool isActive;
  final Map<String, int> unreadCounts; // userId -> count

  const Chat({
    required this.id,
    required this.name,
    this.description,
    this.type = ChatType.direct,
    required this.participants,
    this.lastMessageId,
    this.lastMessageContent,
    this.lastMessageSenderId,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.isActive = true,
    this.unreadCounts = const {},
  });

  /// Создать Chat из Firestore документа
  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      type: ChatType.fromString(data['type'] ?? 'direct'),
      participants: List<String>.from(data['participants'] ?? []),
      lastMessageId: data['lastMessageId'],
      lastMessageContent: data['lastMessageContent'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
      isActive: data['isActive'] ?? true,
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
    );
  }

  /// Конвертировать Chat в Firestore документ
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.value,
      'participants': participants,
      'lastMessageId': lastMessageId,
      'lastMessageContent': lastMessageContent,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
      'isActive': isActive,
      'unreadCounts': unreadCounts,
    };
  }

  /// Создать копию с обновленными полями
  Chat copyWith({
    String? id,
    String? name,
    String? description,
    ChatType? type,
    List<String>? participants,
    String? lastMessageId,
    String? lastMessageContent,
    String? lastMessageSenderId,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    bool? isActive,
    Map<String, int>? unreadCounts,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }

  /// Получить количество непрочитанных сообщений для пользователя
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  /// Проверить, является ли пользователь участником чата
  bool hasParticipant(String userId) {
    return participants.contains(userId);
  }

  /// Получить ID другого участника (для прямых чатов)
  String? getOtherParticipantId(String currentUserId) {
    if (type != ChatType.direct || participants.length != 2) {
      return null;
    }
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Получить отформатированное время последнего сообщения
  String get formattedLastMessageTime {
    if (lastMessageAt == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(lastMessageAt!);

    if (difference.inDays > 0) {
      return '${lastMessageAt!.day}.${lastMessageAt!.month}';
    } else if (difference.inHours > 0) {
      return '${lastMessageAt!.hour}:${lastMessageAt!.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${lastMessageAt!.minute}м назад';
    } else {
      return 'только что';
    }
  }

  /// Проверить, является ли чат прямым
  bool get isDirectChat => type == ChatType.direct;

  /// Проверить, является ли чат групповым
  bool get isGroupChat => type == ChatType.group;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        participants,
        lastMessageId,
        lastMessageContent,
        lastMessageSenderId,
        lastMessageAt,
        createdAt,
        updatedAt,
        metadata,
        isActive,
        unreadCounts,
      ];

  @override
  String toString() {
    return 'Chat(id: $id, name: $name, type: $type, participants: $participants)';
  }
}