import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип сообщения
enum MessageType {
  text,
  image,
  video,
  audio,
  document,
  file,
  location,
  system,
}

/// Статус сообщения
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Модель сообщения чата
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.status,
    this.replyTo,
    this.mediaUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.duration,
    this.location,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory ChatMessage.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      content: data['content'] as String? ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (data['type'] as String?),
        orElse: () => MessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String?),
        orElse: () => MessageStatus.sent,
      ),
      replyTo: data['replyTo'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      fileName: data['fileName'] as String?,
      fileSize: data['fileSize'] as int?,
      duration: data['duration'] as int?,
      location: data['location'] != null ? Map<String, double>.from(data['location']) : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? replyTo;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final int? duration; // в секундах для аудио/видео
  final Map<String, double>? location; // {lat: 0.0, lng: 0.0}
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'type': type.name,
        'timestamp': Timestamp.fromDate(timestamp),
        'status': status.name,
        'replyTo': replyTo,
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'duration': duration,
        'location': location,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    String? replyTo,
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    int? duration,
    Map<String, double>? location,
    Map<String, dynamic>? metadata,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        chatId: chatId ?? this.chatId,
        senderId: senderId ?? this.senderId,
        senderName: senderName ?? this.senderName,
        content: content ?? this.content,
        type: type ?? this.type,
        timestamp: timestamp ?? this.timestamp,
        status: status ?? this.status,
        replyTo: replyTo ?? this.replyTo,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        fileName: fileName ?? this.fileName,
        fileSize: fileSize ?? this.fileSize,
        duration: duration ?? this.duration,
        location: location ?? this.location,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, является ли сообщение медиа
  bool get isMedia =>
      type == MessageType.image ||
      type == MessageType.video ||
      type == MessageType.audio ||
      type == MessageType.document ||
      type == MessageType.file;

  /// Проверить, является ли сообщение текстовым
  bool get isText => type == MessageType.text;

  /// Проверить, является ли сообщение системным
  bool get isSystem => type == MessageType.system;

  /// Получить размер файла в читаемом формате
  String get formattedFileSize {
    if (fileSize == null) return '';

    const units = ['B', 'KB', 'MB', 'GB'];
    var size = fileSize!;
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size ~/= 1024;
      unitIndex++;
    }

    return '$size ${units[unitIndex]}';
  }

  /// Получить длительность в читаемом формате
  String get formattedDuration {
    if (duration == null) return '';

    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ChatMessage(id: $id, senderId: $senderId, content: $content, type: $type, status: $status)';
}
