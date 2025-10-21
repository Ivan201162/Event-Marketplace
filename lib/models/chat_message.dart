import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Message type enum
enum MessageType {
  text,
  image,
  video,
  audio,
  document,
  location,
  attachment,
}

/// Message status enum
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Chat message model
class ChatMessage extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String? text;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;
  final String? replyToMessageId;
  final List<String>? readBy;
  final String? senderName;
  final String? senderAvatarUrl;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text,
    required this.type,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.thumbnailUrl,
    this.metadata,
    this.replyToMessageId,
    this.readBy,
    this.senderName,
    this.senderAvatarUrl,
  });

  /// Create ChatMessage from Firestore document
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'],
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      mediaUrl: data['mediaUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      thumbnailUrl: data['thumbnailUrl'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      replyToMessageId: data['replyToMessageId'],
      readBy: data['readBy'] != null ? List<String>.from(data['readBy']) : null,
      senderName: data['senderName'],
      senderAvatarUrl: data['senderAvatarUrl'],
    );
  }

  /// Convert ChatMessage to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
      'metadata': metadata,
      'replyToMessageId': replyToMessageId,
      'readBy': readBy,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
    };
  }

  /// Create a copy with updated fields
  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    List<String>? readBy,
    String? senderName,
    String? senderAvatarUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      readBy: readBy ?? this.readBy,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
    );
  }

  /// Check if message is read by user
  bool isReadBy(String userId) {
    return readBy?.contains(userId) ?? false;
  }

  /// Check if message has media
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize!} B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

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

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        text,
        type,
        status,
        createdAt,
        updatedAt,
        mediaUrl,
        fileName,
        fileSize,
        thumbnailUrl,
        metadata,
        replyToMessageId,
        readBy,
        senderName,
        senderAvatarUrl,
      ];

  @override
  String toString() {
    return 'ChatMessage(id: $id, chatId: $chatId, senderId: $senderId, text: ${text?.substring(0, text!.length > 50 ? 50 : text!.length)}...)';
  }
}
