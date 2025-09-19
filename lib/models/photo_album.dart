import 'package:flutter/foundation.dart';

/// Модель фотоальбома
@immutable
class PhotoAlbum {
  const PhotoAlbum({
    required this.id,
    required this.title,
    required this.coverImageUrl,
    required this.photoCount,
    this.description,
    this.isPrivate = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String coverImageUrl;
  final int photoCount;
  final String? description;
  final bool isPrivate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PhotoAlbum copyWith({
    String? id,
    String? title,
    String? coverImageUrl,
    int? photoCount,
    String? description,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PhotoAlbum(
        id: id ?? this.id,
        title: title ?? this.title,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        photoCount: photoCount ?? this.photoCount,
        description: description ?? this.description,
        isPrivate: isPrivate ?? this.isPrivate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'coverImageUrl': coverImageUrl,
      'photoCount': photoCount,
      'description': description,
      'isPrivate': isPrivate,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory PhotoAlbum.fromMap(Map<String, dynamic> map) {
    return PhotoAlbum(
      id: map['id'] as String,
      title: map['title'] as String,
      coverImageUrl: map['coverImageUrl'] as String,
      photoCount: map['photoCount'] as int,
      description: map['description'] as String?,
      isPrivate: map['isPrivate'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PhotoAlbum &&
        other.id == id &&
        other.title == title &&
        other.coverImageUrl == coverImageUrl &&
        other.photoCount == photoCount &&
        other.description == description &&
        other.isPrivate == isPrivate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      coverImageUrl.hashCode ^
      photoCount.hashCode ^
      description.hashCode ^
      isPrivate.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'PhotoAlbum(id: $id, title: $title, coverImageUrl: $coverImageUrl, photoCount: $photoCount, description: $description, isPrivate: $isPrivate, createdAt: $createdAt, updatedAt: $updatedAt)';
}
