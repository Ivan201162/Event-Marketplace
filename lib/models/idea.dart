import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Idea model for creative event ideas
class Idea extends Equatable {
  final String id;
  final String title;
  final String shortDesc;
  final String? mediaUrl;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? authorId;
  final String? authorName;
  final int likesCount;
  final int viewsCount;
  final List<String> likedBy;
  final String? category;
  final String? difficulty; // 'easy', 'medium', 'hard'
  final int? estimatedDuration; // in minutes
  final List<String> requiredMaterials;
  final String? detailedDescription;
  final List<String> images;
  final String? description;
  final String? authorPhotoUrl;
  final int savesCount;
  final int commentsCount;

  const Idea({
    required this.id,
    required this.title,
    required this.shortDesc,
    this.mediaUrl,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.authorId,
    this.authorName,
    this.likesCount = 0,
    this.viewsCount = 0,
    this.likedBy = const [],
    this.category,
    this.difficulty,
    this.estimatedDuration,
    this.requiredMaterials = const [],
    this.detailedDescription,
    this.images = const [],
    this.description,
    this.authorPhotoUrl,
    this.savesCount = 0,
    this.commentsCount = 0,
  });

  /// Create Idea from Firestore document
  factory Idea.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Idea(
      id: doc.id,
      title: data['title'] ?? '',
      shortDesc: data['shortDesc'] ?? '',
      mediaUrl: data['mediaUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      authorId: data['authorId'],
      authorName: data['authorName'],
      likesCount: data['likesCount'] ?? 0,
      viewsCount: data['viewsCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      category: data['category'],
      difficulty: data['difficulty'],
      estimatedDuration: data['estimatedDuration'],
      requiredMaterials: List<String>.from(data['requiredMaterials'] ?? []),
      detailedDescription: data['detailedDescription'],
      images: List<String>.from(data['images'] ?? []),
      description: data['description'],
      authorPhotoUrl: data['authorPhotoUrl'],
      savesCount: data['savesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
    );
  }

  /// Convert Idea to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'shortDesc': shortDesc,
      'mediaUrl': mediaUrl,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'authorId': authorId,
      'authorName': authorName,
      'likesCount': likesCount,
      'viewsCount': viewsCount,
      'likedBy': likedBy,
      'category': category,
      'difficulty': difficulty,
      'estimatedDuration': estimatedDuration,
      'requiredMaterials': requiredMaterials,
      'detailedDescription': detailedDescription,
      'images': images,
      'description': description,
      'authorPhotoUrl': authorPhotoUrl,
      'savesCount': savesCount,
      'commentsCount': commentsCount,
    };
  }

  /// Create a copy with updated fields
  Idea copyWith({
    String? id,
    String? title,
    String? shortDesc,
    String? mediaUrl,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorId,
    String? authorName,
    int? likesCount,
    int? viewsCount,
    List<String>? likedBy,
    String? category,
    String? difficulty,
    int? estimatedDuration,
    List<String>? requiredMaterials,
    String? detailedDescription,
    List<String>? images,
    String? description,
    String? authorPhotoUrl,
    int? savesCount,
    int? commentsCount,
  }) {
    return Idea(
      id: id ?? this.id,
      title: title ?? this.title,
      shortDesc: shortDesc ?? this.shortDesc,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      likesCount: likesCount ?? this.likesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      likedBy: likedBy ?? this.likedBy,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      requiredMaterials: requiredMaterials ?? this.requiredMaterials,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      images: images ?? this.images,
      description: description ?? this.description,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      savesCount: savesCount ?? this.savesCount,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }

  /// Check if idea has media
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  /// Check if idea is liked by user
  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// Get category color
  Color get categoryColor {
    switch (category) {
      case 'Свадьба':
        return Colors.pink;
      case 'День рождения':
        return Colors.blue;
      case 'Корпоратив':
        return Colors.green;
      case 'Детский праздник':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get formatted time ago string
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

  /// Get difficulty color
  String get difficultyColor {
    switch (difficulty) {
      case 'easy':
        return 'green';
      case 'medium':
        return 'orange';
      case 'hard':
        return 'red';
      default:
        return 'grey';
    }
  }

  /// Get difficulty text
  String get difficultyText {
    switch (difficulty) {
      case 'easy':
        return 'Легко';
      case 'medium':
        return 'Средне';
      case 'hard':
        return 'Сложно';
      default:
        return 'Не указано';
    }
  }

  /// Get formatted duration
  String get formattedDuration {
    if (estimatedDuration == null) return 'Не указано';

    final hours = estimatedDuration! ~/ 60;
    final minutes = estimatedDuration! % 60;

    if (hours > 0 && minutes > 0) {
      return '$hoursч $minutesм';
    } else if (hours > 0) {
      return '$hoursч';
    } else {
      return '$minutesм';
    }
  }

  /// Get category icon
  String get categoryIcon {
    switch (category?.toLowerCase()) {
      case 'день рождения':
        return '🎂';
      case 'свадьба':
        return '💒';
      case 'корпоратив':
        return '🏢';
      case 'детский праздник':
        return '🎈';
      case 'выпускной':
        return '🎓';
      case 'новый год':
        return '🎄';
      case 'хэллоуин':
        return '🎃';
      case '8 марта':
        return '🌸';
      case '23 февраля':
        return '🎖️';
      default:
        return '💡';
    }
  }

  /// Get author photo URL (already available as field)

  @override
  List<Object?> get props => [
        id,
        title,
        shortDesc,
        mediaUrl,
        tags,
        createdAt,
        updatedAt,
        authorId,
        authorName,
        likesCount,
        viewsCount,
        likedBy,
        category,
        difficulty,
        estimatedDuration,
        requiredMaterials,
        detailedDescription,
        images,
        description,
        authorPhotoUrl,
        savesCount,
        commentsCount,
      ];

  @override
  String toString() {
    return 'Idea(id: $id, title: $title, category: $category)';
  }
}
