import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Message type
enum MessageType { text, image, video, file, system }

/// Chat model
class Chat extends Equatable {
  final String id;
  final List<String> members;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? name;
  final String? imageUrl;
  final Map<String, int> unreadCounts;
  final Map<String, String> memberNames;
  final Map<String, String> memberAvatars;
  final bool isGroup;
  final String? createdBy;

  const Chat({
    required this.id,
    required this.members,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    this.imageUrl,
    this.unreadCounts = const {},
    this.memberNames = const {},
    this.memberAvatars = const {},
    this.isGroup = false,
    this.createdBy,
  });

  /// Create Chat from Firestore document
  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      members: List<String>.from(data['members'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: data['lastMessageSenderId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      name: data['name'],
      imageUrl: data['imageUrl'],
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      memberNames: Map<String, String>.from(data['memberNames'] ?? {}),
      memberAvatars: Map<String, String>.from(data['memberAvatars'] ?? {}),
      isGroup: data['isGroup'] ?? false,
      createdBy: data['createdBy'],
    );
  }

  /// Convert Chat to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'members': members,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'lastMessageSenderId': lastMessageSenderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'name': name,
      'imageUrl': imageUrl,
      'unreadCounts': unreadCounts,
      'memberNames': memberNames,
      'memberAvatars': memberAvatars,
      'isGroup': isGroup,
      'createdBy': createdBy,
    };
  }

  /// Create a copy with updated fields
  Chat copyWith({
    String? id,
    List<String>? members,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? imageUrl,
    Map<String, int>? unreadCounts,
    Map<String, String>? memberNames,
    Map<String, String>? memberAvatars,
    bool? isGroup,
    String? createdBy,
  }) {
    return Chat(
      id: id ?? this.id,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      memberNames: memberNames ?? this.memberNames,
      memberAvatars: memberAvatars ?? this.memberAvatars,
      isGroup: isGroup ?? this.isGroup,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Get chat display name
  String getDisplayName(String currentUserId) {
    if (isGroup && name != null) {
      return name!;
    }

    // For direct messages, show the other person's name
    final otherMembers = members.where((id) => id != currentUserId).toList();
    if (otherMembers.isNotEmpty) {
      return memberNames[otherMembers.first] ?? 'Неизвестный пользователь';
    }

    return 'Чат';
  }

  /// Get chat display avatar
  String? getDisplayAvatar(String currentUserId) {
    if (isGroup && imageUrl != null) {
      return imageUrl;
    }

    // For direct messages, show the other person's avatar
    final otherMembers = members.where((id) => id != currentUserId).toList();
    if (otherMembers.isNotEmpty) {
      return memberAvatars[otherMembers.first];
    }

    return null;
  }

  /// Get unread count for user
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  /// Get formatted last message time
  String get formattedLastMessageTime {
    if (lastMessageTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(lastMessageTime!);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'только что';
    }
  }

  /// Check if chat has unread messages for user
  bool hasUnreadMessages(String userId) {
    return getUnreadCount(userId) > 0;
  }

  @override
  List<Object?> get props => [
    id,
    members,
    lastMessage,
    lastMessageTime,
    lastMessageSenderId,
    createdAt,
    updatedAt,
    name,
    imageUrl,
    unreadCounts,
    memberNames,
    memberAvatars,
    isGroup,
    createdBy,
  ];

  @override
  String toString() {
    return 'Chat(id: $id, members: $members, isGroup: $isGroup)';
  }
}

/// Message model
class Message extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String? text;
  final String? mediaUrl;
  final MessageType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> readBy;
  final String? senderName;
  final String? senderAvatarUrl;
  final String? fileName;
  final int? fileSize;
  final String? replyToMessageId;
  final String? replyToMessageText;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text,
    this.mediaUrl,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.readBy = const [],
    this.senderName,
    this.senderAvatarUrl,
    this.fileName,
    this.fileSize,
    this.replyToMessageId,
    this.replyToMessageText,
  });

  /// Create Message from Firestore document
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'],
      mediaUrl: data['mediaUrl'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => MessageType.text,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      readBy: List<String>.from(data['readBy'] ?? []),
      senderName: data['senderName'],
      senderAvatarUrl: data['senderAvatarUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      replyToMessageId: data['replyToMessageId'],
      replyToMessageText: data['replyToMessageText'],
    );
  }

  /// Convert Message to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'mediaUrl': mediaUrl,
      'type': type.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'readBy': readBy,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'replyToMessageId': replyToMessageId,
      'replyToMessageText': replyToMessageText,
    };
  }

  /// Create a copy with updated fields
  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    String? mediaUrl,
    MessageType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? readBy,
    String? senderName,
    String? senderAvatarUrl,
    String? fileName,
    int? fileSize,
    String? replyToMessageId,
    String? replyToMessageText,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readBy: readBy ?? this.readBy,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessageText: replyToMessageText ?? this.replyToMessageText,
    );
  }

  /// Check if message is read by user
  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }

  /// Get formatted time string
  String get formattedTime {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize == null) return '';

    if (fileSize! < 1024) {
      return '${fileSize!} Б';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} КБ';
    } else {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} МБ';
    }
  }

  /// Get message type icon
  String get typeIcon {
    switch (type) {
      case MessageType.text:
        return '💬';
      case MessageType.image:
        return '🖼️';
      case MessageType.video:
        return '🎥';
      case MessageType.file:
        return '📎';
      case MessageType.system:
        return 'ℹ️';
    }
  }

  /// Check if message has media
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  /// Check if message is a reply
  bool get isReply => replyToMessageId != null;

  @override
  List<Object?> get props => [
    id,
    chatId,
    senderId,
    text,
    mediaUrl,
    type,
    createdAt,
    updatedAt,
    readBy,
    senderName,
    senderAvatarUrl,
    fileName,
    fileSize,
    replyToMessageId,
    replyToMessageText,
  ];

  @override
  String toString() {
    return 'Message(id: $id, chatId: $chatId, senderId: $senderId, type: $type)';
  }
}
