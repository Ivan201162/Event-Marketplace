import 'package:equatable/equatable.dart';

/// Media upload result model
class MediaUploadResult extends Equatable {
  final String id;
  final String url;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;
  final DateTime uploadedAt;
  final bool isSuccess;
  final String? error;

  const MediaUploadResult({
    required this.id,
    required this.url,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    this.thumbnailUrl,
    this.metadata,
    required this.uploadedAt,
    this.isSuccess = true,
    this.error,
  });

  /// Create MediaUploadResult from Map
  factory MediaUploadResult.fromMap(Map<String, dynamic> data) {
    return MediaUploadResult(
      id: data['id'] ?? '',
      url: data['url'] ?? '',
      fileName: data['fileName'] ?? '',
      fileType: data['fileType'] ?? '',
      fileSize: data['fileSize'] ?? 0,
      thumbnailUrl: data['thumbnailUrl'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      uploadedAt: DateTime.parse(data['uploadedAt']),
      isSuccess: data['isSuccess'] ?? true,
      error: data['error'],
    );
  }

  /// Convert MediaUploadResult to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
      'metadata': metadata,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isSuccess': isSuccess,
      'error': error,
    };
  }

  /// Create a copy with updated fields
  MediaUploadResult copyWith({
    String? id,
    String? url,
    String? fileName,
    String? fileType,
    int? fileSize,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    DateTime? uploadedAt,
    bool? isSuccess,
    String? error,
  }) {
    return MediaUploadResult(
      id: id ?? this.id,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
    );
  }

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Check if file is image
  bool get isImage {
    return fileType.startsWith('image/');
  }

  /// Check if file is video
  bool get isVideo {
    return fileType.startsWith('video/');
  }

  /// Check if file is audio
  bool get isAudio {
    return fileType.startsWith('audio/');
  }

  /// Check if file is document
  bool get isDocument {
    return fileType.startsWith('application/') || fileType == 'text/plain';
  }

  @override
  List<Object?> get props => [
    id,
    url,
    fileName,
    fileType,
    fileSize,
    thumbnailUrl,
    metadata,
    uploadedAt,
    isSuccess,
    error,
  ];

  @override
  String toString() {
    return 'MediaUploadResult(id: $id, fileName: $fileName, isSuccess: $isSuccess)';
  }
}
