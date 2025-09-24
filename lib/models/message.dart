import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
  file,
  bot,
  system,
  location,
  contact,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? text;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final MessageType type;
  final MessageStatus status;
  final Map<String, dynamic> metadata; // Additional message data
  final String? replyToMessageId; // For message replies
  final List<String> forwardedTo; // Chat IDs where this message was forwarded
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
    required this.type,
    this.status = MessageStatus.sent,
    this.metadata = const {},
    this.replyToMessageId,
    this.forwardedTo = const [],
    this.isEdited = false,
    this.editedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'metadata': metadata,
      'replyToMessageId': replyToMessageId,
      'forwardedTo': forwardedTo,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      chatId: map['chatId'] as String,
      senderId: map['senderId'] as String,
      text: map['text'] as String?,
      fileUrl: map['fileUrl'] as String?,
      fileName: map['fileName'] as String?,
      fileType: map['fileType'] as String?,
      fileSize: map['fileSize'] as int?,
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'] as String,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'] as String,
        orElse: () => MessageStatus.sent,
      ),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map<String, dynamic>? ?? {}),
      replyToMessageId: map['replyToMessageId'] as String?,
      forwardedTo: List<String>.from(map['forwardedTo'] as List<dynamic>? ?? []),
      isEdited: map['isEdited'] as bool? ?? false,
      editedAt: (map['editedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory Message.fromDocument(DocumentSnapshot doc) {
    return Message.fromMap(doc.data() as Map<String, dynamic>);
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    String? fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
    MessageType? type,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    List<String>? forwardedTo,
    bool? isEdited,
    DateTime? editedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      type: type ?? this.type,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      forwardedTo: forwardedTo ?? this.forwardedTo,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if message is from bot
  bool get isFromBot => type == MessageType.bot;

  /// Check if message is system message
  bool get isSystemMessage => type == MessageType.system;

  /// Check if message has file attachment
  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;

  /// Check if message is media (image or video)
  bool get isMedia => type == MessageType.image || type == MessageType.video;

  /// Get file size in human readable format
  String get fileSizeFormatted {
    if (fileSize == null) return '';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    int size = fileSize!;
    int unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size ~/= 1024;
      unitIndex++;
    }
    
    return '$size ${units[unitIndex]}';
  }

  /// Get message preview text
  String get previewText {
    switch (type) {
      case MessageType.text:
        return text ?? '';
      case MessageType.image:
        return '📷 Фото';
      case MessageType.video:
        return '🎥 Видео';
      case MessageType.file:
        return '📄 ${fileName ?? 'Файл'}';
      case MessageType.bot:
        return '🤖 ${text ?? 'Сообщение от бота'}';
      case MessageType.system:
        return 'ℹ️ ${text ?? 'Системное сообщение'}';
      case MessageType.location:
        return '📍 Местоположение';
      case MessageType.contact:
        return '👤 Контакт';
    }
  }
}
