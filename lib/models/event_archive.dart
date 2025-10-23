import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Модель архива мероприятия
@immutable
class EventArchive {
  const EventArchive({
    required this.id,
    required this.bookingId,
    required this.fileUrl,
    required this.uploadedAt,
    this.fileName,
    this.fileSize,
    this.description,
    this.uploadedBy,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory EventArchive.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return EventArchive(
      id: doc.id,
      bookingId: data['bookingId'] as String,
      fileUrl: data['fileUrl'] as String,
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      fileName: data['fileName'] as String?,
      fileSize: data['fileSize'] as int?,
      description: data['description'] as String?,
      uploadedBy: data['uploadedBy'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  /// Создать из Map
  factory EventArchive.fromMap(Map<String, dynamic> data) => EventArchive(
        id: data['id'] as String,
        bookingId: data['bookingId'] as String,
        fileUrl: data['fileUrl'] as String,
        uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
        fileName: data['fileName'] as String?,
        fileSize: data['fileSize'] as int?,
        description: data['description'] as String?,
        uploadedBy: data['uploadedBy'] as String?,
        metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      );

  final String id;
  final String bookingId;
  final String fileUrl;
  final DateTime uploadedAt;
  final String? fileName;
  final int? fileSize;
  final String? description;
  final String? uploadedBy; // ID пользователя, который загрузил архив
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'bookingId': bookingId,
        'fileUrl': fileUrl,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'fileName': fileName,
        'fileSize': fileSize,
        'description': description,
        'uploadedBy': uploadedBy,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  EventArchive copyWith({
    String? id,
    String? bookingId,
    String? fileUrl,
    DateTime? uploadedAt,
    String? fileName,
    int? fileSize,
    String? description,
    String? uploadedBy,
    Map<String, dynamic>? metadata,
  }) =>
      EventArchive(
        id: id ?? this.id,
        bookingId: bookingId ?? this.bookingId,
        fileUrl: fileUrl ?? this.fileUrl,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        fileName: fileName ?? this.fileName,
        fileSize: fileSize ?? this.fileSize,
        description: description ?? this.description,
        uploadedBy: uploadedBy ?? this.uploadedBy,
        metadata: metadata ?? this.metadata,
      );

  /// Получить размер файла в читаемом формате
  String get formattedFileSize {
    if (fileSize == null) {
      return 'Неизвестно';
    }

    final bytes = fileSize!;
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Получить расширение файла
  String get fileExtension {
    if (fileName == null) return '';
    final parts = fileName!.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Проверить, является ли файл изображением
  bool get isImage {
    final ext = fileExtension;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  /// Проверить, является ли файл видео
  bool get isVideo {
    final ext = fileExtension;
    return ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'].contains(ext);
  }

  /// Проверить, является ли файл архивом
  bool get isArchive {
    final ext = fileExtension;
    return ['zip', 'rar', '7z', 'tar', 'gz'].contains(ext);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is EventArchive && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'EventArchive(id: $id, bookingId: $bookingId, fileName: $fileName, uploadedAt: $uploadedAt)';
}
