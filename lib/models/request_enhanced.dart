import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Статусы заявки
enum RequestStatus {
  open('open', 'Открыта', '🟡'),
  inProgress('in_progress', 'В работе', '🟢'),
  completed('completed', 'Завершена', '🔵'),
  cancelled('cancelled', 'Отменена', '🔴');

  const RequestStatus(this.value, this.label, this.emoji);
  final String value;
  final String label;
  final String emoji;
}

/// Приоритет заявки
enum RequestPriority {
  low('low', 'Низкий'),
  medium('medium', 'Средний'),
  high('high', 'Высокий'),
  urgent('urgent', 'Срочный');

  const RequestPriority(this.value, this.label);
  final String value;
  final String label;
}

/// Расширенная модель заявки с полным функционалом
class RequestEnhanced extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String subcategory;
  final String location;
  final String city;
  final double latitude;
  final double longitude;
  final double budget;
  final DateTime deadline;
  final RequestStatus status;
  final RequestPriority priority;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final List<String> attachments;
  final List<String> tags;
  final List<String> requiredSkills;
  final String language;
  final bool isRemote;
  final int maxApplicants;
  final List<String> applicants;
  final String? selectedApplicantId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;
  final List<RequestTimeline> timeline;
  final Map<String, dynamic> aiRecommendations;
  final bool isVerified;
  final double rating;
  final int views;
  final int likes;
  final bool isPinned;
  final DateTime? pinnedUntil;
  final List<String> sharedWith;
  final Map<String, dynamic> analytics;

  const RequestEnhanced({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.location,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.budget,
    required this.deadline,
    required this.status,
    required this.priority,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.attachments,
    required this.tags,
    required this.requiredSkills,
    required this.language,
    required this.isRemote,
    required this.maxApplicants,
    required this.applicants,
    this.selectedApplicantId,
    required this.createdAt,
    required this.updatedAt,
    required this.metadata,
    required this.timeline,
    required this.aiRecommendations,
    required this.isVerified,
    required this.rating,
    required this.views,
    required this.likes,
    required this.isPinned,
    this.pinnedUntil,
    required this.sharedWith,
    required this.analytics,
  });

  /// Создание из Firestore документа
  factory RequestEnhanced.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RequestEnhanced(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'] ?? '',
      location: data['location'] ?? '',
      city: data['city'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      budget: (data['budget'] ?? 0.0).toDouble(),
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: RequestStatus.values.firstWhere(
        (e) => e.value == data['status'],
        orElse: () => RequestStatus.open,
      ),
      priority: RequestPriority.values.firstWhere(
        (e) => e.value == data['priority'],
        orElse: () => RequestPriority.medium,
      ),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'] ?? '',
      attachments: List<String>.from(data['attachments'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      requiredSkills: List<String>.from(data['requiredSkills'] ?? []),
      language: data['language'] ?? 'ru',
      isRemote: data['isRemote'] ?? false,
      maxApplicants: data['maxApplicants'] ?? 10,
      applicants: List<String>.from(data['applicants'] ?? []),
      selectedApplicantId: data['selectedApplicantId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      timeline: (data['timeline'] as List<dynamic>?)
              ?.map((e) => RequestTimeline.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      aiRecommendations:
          Map<String, dynamic>.from(data['aiRecommendations'] ?? {}),
      isVerified: data['isVerified'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      isPinned: data['isPinned'] ?? false,
      pinnedUntil: (data['pinnedUntil'] as Timestamp?)?.toDate(),
      sharedWith: List<String>.from(data['sharedWith'] ?? []),
      analytics: Map<String, dynamic>.from(data['analytics'] ?? {}),
    );
  }

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'location': location,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'budget': budget,
      'deadline': Timestamp.fromDate(deadline),
      'status': status.value,
      'priority': priority.value,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'attachments': attachments,
      'tags': tags,
      'requiredSkills': requiredSkills,
      'language': language,
      'isRemote': isRemote,
      'maxApplicants': maxApplicants,
      'applicants': applicants,
      'selectedApplicantId': selectedApplicantId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
      'timeline': timeline.map((e) => e.toMap()).toList(),
      'aiRecommendations': aiRecommendations,
      'isVerified': isVerified,
      'rating': rating,
      'views': views,
      'likes': likes,
      'isPinned': isPinned,
      'pinnedUntil':
          pinnedUntil != null ? Timestamp.fromDate(pinnedUntil!) : null,
      'sharedWith': sharedWith,
      'analytics': analytics,
    };
  }

  /// Создание копии с изменениями
  RequestEnhanced copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? subcategory,
    String? location,
    String? city,
    double? latitude,
    double? longitude,
    double? budget,
    DateTime? deadline,
    RequestStatus? status,
    RequestPriority? priority,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    List<String>? attachments,
    List<String>? tags,
    List<String>? requiredSkills,
    String? language,
    bool? isRemote,
    int? maxApplicants,
    List<String>? applicants,
    String? selectedApplicantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<RequestTimeline>? timeline,
    Map<String, dynamic>? aiRecommendations,
    bool? isVerified,
    double? rating,
    int? views,
    int? likes,
    bool? isPinned,
    DateTime? pinnedUntil,
    List<String>? sharedWith,
    Map<String, dynamic>? analytics,
  }) {
    return RequestEnhanced(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      location: location ?? this.location,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      budget: budget ?? this.budget,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      attachments: attachments ?? this.attachments,
      tags: tags ?? this.tags,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      language: language ?? this.language,
      isRemote: isRemote ?? this.isRemote,
      maxApplicants: maxApplicants ?? this.maxApplicants,
      applicants: applicants ?? this.applicants,
      selectedApplicantId: selectedApplicantId ?? this.selectedApplicantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      timeline: timeline ?? this.timeline,
      aiRecommendations: aiRecommendations ?? this.aiRecommendations,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      isPinned: isPinned ?? this.isPinned,
      pinnedUntil: pinnedUntil ?? this.pinnedUntil,
      sharedWith: sharedWith ?? this.sharedWith,
      analytics: analytics ?? this.analytics,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        subcategory,
        location,
        city,
        latitude,
        longitude,
        budget,
        deadline,
        status,
        priority,
        authorId,
        authorName,
        authorAvatar,
        attachments,
        tags,
        requiredSkills,
        language,
        isRemote,
        maxApplicants,
        applicants,
        selectedApplicantId,
        createdAt,
        updatedAt,
        metadata,
        timeline,
        aiRecommendations,
        isVerified,
        rating,
        views,
        likes,
        isPinned,
        pinnedUntil,
        sharedWith,
        analytics,
      ];
}

/// Таймлайн заявки
class RequestTimeline extends Equatable {
  final String id;
  final String action;
  final String description;
  final String userId;
  final String userName;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const RequestTimeline({
    required this.id,
    required this.action,
    required this.description,
    required this.userId,
    required this.userName,
    required this.timestamp,
    required this.metadata,
  });

  factory RequestTimeline.fromMap(Map<String, dynamic> map) {
    return RequestTimeline(
      id: map['id'] ?? '',
      action: map['action'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'description': description,
      'userId': userId,
      'userName': userName,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        action,
        description,
        userId,
        userName,
        timestamp,
        metadata,
      ];
}

/// Фильтры для заявок
class RequestFilters extends Equatable {
  final String? category;
  final String? subcategory;
  final String? city;
  final double? minBudget;
  final double? maxBudget;
  final DateTime? startDate;
  final DateTime? endDate;
  final RequestStatus? status;
  final RequestPriority? priority;
  final bool? isRemote;
  final String? language;
  final List<String>? tags;
  final List<String>? requiredSkills;
  final String? searchQuery;
  final double? latitude;
  final double? longitude;
  final double? radius;

  const RequestFilters({
    this.category,
    this.subcategory,
    this.city,
    this.minBudget,
    this.maxBudget,
    this.startDate,
    this.endDate,
    this.status,
    this.priority,
    this.isRemote,
    this.language,
    this.tags,
    this.requiredSkills,
    this.searchQuery,
    this.latitude,
    this.longitude,
    this.radius,
  });

  @override
  List<Object?> get props => [
        category,
        subcategory,
        city,
        minBudget,
        maxBudget,
        startDate,
        endDate,
        status,
        priority,
        isRemote,
        language,
        tags,
        requiredSkills,
        searchQuery,
        latitude,
        longitude,
        radius,
      ];
}
