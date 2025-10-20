import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Request status
enum RequestStatus {
  pending,
  accepted,
  rejected,
  completed,
  cancelled,
}

/// Request model for event requests
class Request extends Equatable {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String city;
  final DateTime date;
  final int budget;
  final String category;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? fromUserName;
  final String? fromUserAvatarUrl;
  final String? toUserName;
  final String? toUserAvatarUrl;
  final String? eventType;
  final int? guestCount;
  final String? location;
  final List<String> requirements;
  final String? notes;
  final DateTime? responseDate;

  const Request({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.city,
    required this.date,
    required this.budget,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.fromUserName,
    this.fromUserAvatarUrl,
    this.toUserName,
    this.toUserAvatarUrl,
    this.eventType,
    this.guestCount,
    this.location,
    this.requirements = const [],
    this.notes,
    this.responseDate,
  });

  /// Create Request from Firestore document
  factory Request.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Request(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      city: data['city'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      budget: data['budget'] ?? 0,
      category: data['category'] ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      description: data['description'],
      fromUserName: data['fromUserName'],
      fromUserAvatarUrl: data['fromUserAvatarUrl'],
      toUserName: data['toUserName'],
      toUserAvatarUrl: data['toUserAvatarUrl'],
      eventType: data['eventType'],
      guestCount: data['guestCount'],
      location: data['location'],
      requirements: List<String>.from(data['requirements'] ?? []),
      notes: data['notes'],
      responseDate:
          data['responseDate'] != null ? (data['responseDate'] as Timestamp).toDate() : null,
    );
  }

  /// Convert Request to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'city': city,
      'date': Timestamp.fromDate(date),
      'budget': budget,
      'category': category,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'description': description,
      'fromUserName': fromUserName,
      'fromUserAvatarUrl': fromUserAvatarUrl,
      'toUserName': toUserName,
      'toUserAvatarUrl': toUserAvatarUrl,
      'eventType': eventType,
      'guestCount': guestCount,
      'location': location,
      'requirements': requirements,
      'notes': notes,
      'responseDate': responseDate != null ? Timestamp.fromDate(responseDate!) : null,
    };
  }

  /// Create a copy with updated fields
  Request copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? city,
    DateTime? date,
    int? budget,
    String? category,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? fromUserName,
    String? fromUserAvatarUrl,
    String? toUserName,
    String? toUserAvatarUrl,
    String? eventType,
    int? guestCount,
    String? location,
    List<String>? requirements,
    String? notes,
    DateTime? responseDate,
  }) {
    return Request(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      city: city ?? this.city,
      date: date ?? this.date,
      budget: budget ?? this.budget,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserAvatarUrl: fromUserAvatarUrl ?? this.fromUserAvatarUrl,
      toUserName: toUserName ?? this.toUserName,
      toUserAvatarUrl: toUserAvatarUrl ?? this.toUserAvatarUrl,
      eventType: eventType ?? this.eventType,
      guestCount: guestCount ?? this.guestCount,
      location: location ?? this.location,
      requirements: requirements ?? this.requirements,
      notes: notes ?? this.notes,
      responseDate: responseDate ?? this.responseDate,
    );
  }

  /// Get formatted budget string
  String get formattedBudget => '$budget ₽';

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return 'через ${difference.inDays}д';
    } else if (difference.inDays == 0) {
      return 'сегодня';
    } else {
      return '${-difference.inDays}д назад';
    }
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case RequestStatus.pending:
        return 'orange';
      case RequestStatus.accepted:
        return 'green';
      case RequestStatus.rejected:
        return 'red';
      case RequestStatus.completed:
        return 'blue';
      case RequestStatus.cancelled:
        return 'grey';
    }
  }

  /// Get status text
  String get statusText {
    switch (status) {
      case RequestStatus.pending:
        return 'Ожидает';
      case RequestStatus.accepted:
        return 'Принято';
      case RequestStatus.rejected:
        return 'Отклонено';
      case RequestStatus.completed:
        return 'Завершено';
      case RequestStatus.cancelled:
        return 'Отменено';
    }
  }

  /// Get status icon
  String get statusIcon {
    switch (status) {
      case RequestStatus.pending:
        return '⏳';
      case RequestStatus.accepted:
        return '✅';
      case RequestStatus.rejected:
        return '❌';
      case RequestStatus.completed:
        return '🎉';
      case RequestStatus.cancelled:
        return '🚫';
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

  /// Get category icon
  String get categoryIcon {
    switch (category.toLowerCase()) {
      case 'ведущий':
      case 'ведущие':
        return '🎤';
      case 'фотограф':
      case 'фотографы':
        return '📸';
      case 'dj':
        return '🎧';
      case 'видеограф':
      case 'видеографы':
        return '🎥';
      case 'декоратор':
      case 'декораторы':
        return '🎨';
      case 'аниматор':
      case 'аниматоры':
        return '🎭';
      case 'музыкант':
      case 'музыканты':
        return '🎵';
      case 'танцор':
      case 'танцоры':
        return '💃';
      case 'кейтеринг':
        return '🍽️';
      default:
        return '🎪';
    }
  }

  /// Check if request is active (pending or accepted)
  bool get isActive => status == RequestStatus.pending || status == RequestStatus.accepted;

  /// Check if request can be responded to
  bool get canRespond => status == RequestStatus.pending;

  @override
  List<Object?> get props => [
        id,
        fromUserId,
        toUserId,
        city,
        date,
        budget,
        category,
        status,
        createdAt,
        updatedAt,
        description,
        fromUserName,
        fromUserAvatarUrl,
        toUserName,
        toUserAvatarUrl,
        eventType,
        guestCount,
        location,
        requirements,
        notes,
        responseDate,
      ];

  @override
  String toString() {
    return 'Request(id: $id, fromUserId: $fromUserId, toUserId: $toUserId, status: $status)';
  }
}
