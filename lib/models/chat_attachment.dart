import 'package:cloud_firestore/cloud_firestore.dart';

enum AttachmentType { image, video, document, audio, other }

class ChatAttachment {
  ChatAttachment({
    required this.id,
    required this.messageId,
    required this.fileName,
    required this.originalFileName,
    required this.fileUrl,
    this.thumbnailUrl,
    required this.type,
    required this.fileSize,
    required this.mimeType,
    required this.uploadedAt,
    required this.uploadedBy,
    this.metadata,
  });

  factory ChatAttachment.fromMap(Map<String, dynamic> map, String id) =>
      ChatAttachment(
        id: id,
        messageId: map['messageId'] as String,
        fileName: map['fileName'] as String,
        originalFileName: map['originalFileName'] as String,
        fileUrl: map['fileUrl'] as String,
        thumbnailUrl: map['thumbnailUrl'] as String?,
        type: AttachmentType.values.firstWhere(
          (e) => e.toString() == 'AttachmentType.${map['type']}',
          orElse: () => AttachmentType.other,
        ),
        fileSize: map['fileSize'] as int,
        mimeType: map['mimeType'] as String,
        uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
        uploadedBy: map['uploadedBy'] as String,
        metadata: map['metadata'] as Map<String, dynamic>?,
      );
  final String id;
  final String messageId;
  final String fileName;
  final String originalFileName;
  final String fileUrl;
  final String? thumbnailUrl;
  final AttachmentType type;
  final int fileSize;
  final String mimeType;
  final DateTime uploadedAt;
  final String uploadedBy;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
        'messageId': messageId,
        'fileName': fileName,
        'originalFileName': originalFileName,
        'fileUrl': fileUrl,
        'thumbnailUrl': thumbnailUrl,
        'type': type.toString().split('.').last,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'uploadedBy': uploadedBy,
        'metadata': metadata,
      };

  /// Получить иконку для типа файла
  String getFileIcon() {
    switch (type) {
      case AttachmentType.image:
        return '🖼️';
      case AttachmentType.video:
        return '🎥';
      case AttachmentType.document:
        return '📄';
      case AttachmentType.audio:
        return '🎵';
      case AttachmentType.other:
        return '📎';
    }
  }

  /// Проверить, является ли файл изображением
  bool get isImage => type == AttachmentType.image;

  /// Проверить, является ли файл видео
  bool get isVideo => type == AttachmentType.video;

  /// Проверить, является ли файл аудио
  bool get isAudio => type == AttachmentType.audio;

  /// Проверить, является ли файл документом
  bool get isDocument => type == AttachmentType.document;

  /// Получить размер файла в читаемом формате
  String getFormattedFileSize() {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Получить расширение файла
  String getFileExtension() {
    final parts = originalFileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}
