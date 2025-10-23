import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
  file,
  audio,
  location,
  sticker,
  gif,
}

class Message {
  final String id;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;
  final String? repliedToMessageId;
  final List<String> reactions;
  final String? fileUrl;
  final GeoPoint? location;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.readBy = const [],
    this.repliedToMessageId,
    this.reactions = const [],
    this.fileUrl,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'readBy': readBy,
      'repliedToMessageId': repliedToMessageId,
      'reactions': reactions,
      'fileUrl': fileUrl,
      'location': location,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      content: map['content'] as String,
      type: MessageType.values.firstWhere(
          (e) => e.toString().split('.').last == map['type'] as String),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] as bool,
      readBy: List<String>.from(map['readBy'] as List<dynamic>),
      repliedToMessageId: map['repliedToMessageId'] as String?,
      reactions: List<String>.from(map['reactions'] as List<dynamic>),
      fileUrl: map['fileUrl'] as String?,
      location: map['location'] as GeoPoint?,
    );
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    List<String>? readBy,
    String? repliedToMessageId,
    List<String>? reactions,
    String? fileUrl,
    GeoPoint? location,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
      repliedToMessageId: repliedToMessageId ?? this.repliedToMessageId,
      reactions: reactions ?? this.reactions,
      fileUrl: fileUrl ?? this.fileUrl,
      location: location ?? this.location,
    );
  }
}
