import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants;
  final String? lastMessageId;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final Map<String, bool> readStatus; // userId -> hasRead
  final Map<String, DateTime> lastSeen; // userId -> lastSeenAt
  final bool isActive;
  final String? chatType; // 'customer_specialist', 'support', 'group'
  final Map<String, dynamic> metadata; // Additional chat metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessageId,
    this.lastMessageText,
    this.lastMessageAt,
    this.readStatus = const {},
    this.lastSeen = const {},
    this.isActive = true,
    this.chatType,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessageId': lastMessageId,
      'lastMessageText': lastMessageText,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'readStatus': readStatus,
      'lastSeen': lastSeen.map((key, value) => MapEntry(key, Timestamp.fromDate(value))),
      'isActive': isActive,
      'chatType': chatType,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] as String,
      participants: List<String>.from(map['participants'] as List<dynamic>),
      lastMessageId: map['lastMessageId'] as String?,
      lastMessageText: map['lastMessageText'] as String?,
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      readStatus: Map<String, bool>.from(map['readStatus'] as Map<String, dynamic>? ?? {}),
      lastSeen: (map['lastSeen'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, (value as Timestamp).toDate()),
      ),
      isActive: map['isActive'] as bool? ?? true,
      chatType: map['chatType'] as String?,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map<String, dynamic>? ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory Chat.fromDocument(DocumentSnapshot doc) {
    return Chat.fromMap(doc.data() as Map<String, dynamic>);
  }

  Chat copyWith({
    String? id,
    List<String>? participants,
    String? lastMessageId,
    String? lastMessageText,
    DateTime? lastMessageAt,
    Map<String, bool>? readStatus,
    Map<String, DateTime>? lastSeen,
    bool? isActive,
    String? chatType,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      readStatus: readStatus ?? this.readStatus,
      lastSeen: lastSeen ?? this.lastSeen,
      isActive: isActive ?? this.isActive,
      chatType: chatType ?? this.chatType,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the other participant in a two-person chat
  String? getOtherParticipant(String currentUserId) {
    if (participants.length != 2) return null;
    return participants.firstWhere((id) => id != currentUserId);
  }

  /// Check if user has read the last message
  bool hasUserRead(String userId) {
    return readStatus[userId] ?? false;
  }

  /// Get unread message count for user
  int getUnreadCount(String userId) {
    return hasUserRead(userId) ? 0 : 1; // Simplified - in real app, count actual unread messages
  }
}