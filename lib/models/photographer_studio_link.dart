import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель связки фотографа и фотостудии
class PhotographerStudioLink {
  const PhotographerStudioLink({
    required this.id,
    required this.photographerId,
    required this.studioId,
    required this.status,
    required this.createdAt,
    this.photographerName,
    this.photographerAvatar,
    this.studioName,
    this.studioAvatar,
    this.notes,
    this.commissionRate,
    this.isPreferred = false,
    this.updatedAt,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory PhotographerStudioLink.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return PhotographerStudioLink(
      id: doc.id,
      photographerId: data['photographerId']?.toString() ?? '',
      studioId: data['studioId']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      photographerName: data['photographerName']?.toString(),
      photographerAvatar: data['photographerAvatar']?.toString(),
      studioName: data['studioName']?.toString(),
      studioAvatar: data['studioAvatar']?.toString(),
      notes: data['notes']?.toString(),
      commissionRate: (data['commissionRate'] as num?)?.toDouble(),
      isPreferred: data['isPreferred'] == true,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  /// Создать из Map
  factory PhotographerStudioLink.fromMap(Map<String, dynamic> data) =>
      PhotographerStudioLink(
        id: data['id']?.toString() ?? '',
        photographerId: data['photographerId']?.toString() ?? '',
        studioId: data['studioId']?.toString() ?? '',
        status: data['status']?.toString() ?? 'pending',
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        photographerName: data['photographerName']?.toString(),
        photographerAvatar: data['photographerAvatar']?.toString(),
        studioName: data['studioName']?.toString(),
        studioAvatar: data['studioAvatar']?.toString(),
        notes: data['notes']?.toString(),
        commissionRate: (data['commissionRate'] as num?)?.toDouble(),
        isPreferred: data['isPreferred'] == true,
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : null,
        metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      );

  final String id;
  final String photographerId;
  final String studioId;
  final String status;
  final DateTime createdAt;
  final String? photographerName;
  final String? photographerAvatar;
  final String? studioName;
  final String? studioAvatar;
  final String? notes;
  final double? commissionRate;
  final bool isPreferred;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'photographerId': photographerId,
        'studioId': studioId,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'photographerName': photographerName,
        'photographerAvatar': photographerAvatar,
        'studioName': studioName,
        'studioAvatar': studioAvatar,
        'notes': notes,
        'commissionRate': commissionRate,
        'isPreferred': isPreferred,
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  PhotographerStudioLink copyWith({
    String? id,
    String? photographerId,
    String? studioId,
    String? status,
    DateTime? createdAt,
    String? photographerName,
    String? photographerAvatar,
    String? studioName,
    String? studioAvatar,
    String? notes,
    double? commissionRate,
    bool? isPreferred,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) =>
      PhotographerStudioLink(
        id: id ?? this.id,
        photographerId: photographerId ?? this.photographerId,
        studioId: studioId ?? this.studioId,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        photographerName: photographerName ?? this.photographerName,
        photographerAvatar: photographerAvatar ?? this.photographerAvatar,
        studioName: studioName ?? this.studioName,
        studioAvatar: studioAvatar ?? this.studioAvatar,
        notes: notes ?? this.notes,
        commissionRate: commissionRate ?? this.commissionRate,
        isPreferred: isPreferred ?? this.isPreferred,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, является ли связка активной
  bool get isActive => status == 'active';

  /// Проверить, является ли связка ожидающей
  bool get isPending => status == 'pending';

  /// Проверить, является ли связка отклоненной
  bool get isRejected => status == 'rejected';

  /// Проверить, является ли связка приостановленной
  bool get isSuspended => status == 'suspended';

  /// Получить отформатированную комиссию
  String get formattedCommissionRate {
    if (commissionRate == null) return 'Не указана';
    return '${commissionRate!.toStringAsFixed(1)}%';
  }

  /// Получить время в читаемом формате
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}м назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}д назад';
    } else {
      return '${(difference.inDays / 7).floor()}н назад';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhotographerStudioLink && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PhotographerStudioLink(id: $id, photographerId: $photographerId, studioId: $studioId, status: $status)';
}

/// Модель для создания связки фотографа и фотостудии
class CreatePhotographerStudioLink {
  const CreatePhotographerStudioLink({
    required this.photographerId,
    required this.studioId,
    this.photographerName,
    this.photographerAvatar,
    this.studioName,
    this.studioAvatar,
    this.notes,
    this.commissionRate,
    this.metadata = const {},
  });

  final String photographerId;
  final String studioId;
  final String? photographerName;
  final String? photographerAvatar;
  final String? studioName;
  final String? studioAvatar;
  final String? notes;
  final double? commissionRate;
  final Map<String, dynamic> metadata;

  bool get isValid =>
      photographerId.isNotEmpty &&
      studioId.isNotEmpty &&
      photographerId != studioId;

  List<String> get validationErrors {
    final errors = <String>[];
    if (photographerId.isEmpty) errors.add('ID фотографа обязателен');
    if (studioId.isEmpty) errors.add('ID фотостудии обязателен');
    if (photographerId == studioId) {
      errors.add('Фотограф и фотостудия не могут быть одинаковыми');
    }
    return errors;
  }
}

/// Модель предложения фотостудии для заказа
class StudioSuggestion {
  const StudioSuggestion({
    required this.id,
    required this.bookingId,
    required this.photographerId,
    required this.studioId,
    required this.suggestedAt,
    this.photographerName,
    this.photographerAvatar,
    this.studioName,
    this.studioAvatar,
    this.studioAddress,
    this.studioPhone,
    this.studioEmail,
    this.suggestedPrice,
    this.notes,
    this.isAccepted = false,
    this.isRejected = false,
    this.acceptedAt,
    this.rejectedAt,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory StudioSuggestion.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return StudioSuggestion(
      id: doc.id,
      bookingId: data['bookingId']?.toString() ?? '',
      photographerId: data['photographerId']?.toString() ?? '',
      studioId: data['studioId']?.toString() ?? '',
      suggestedAt: (data['suggestedAt'] as Timestamp).toDate(),
      photographerName: data['photographerName']?.toString(),
      photographerAvatar: data['photographerAvatar']?.toString(),
      studioName: data['studioName']?.toString(),
      studioAvatar: data['studioAvatar']?.toString(),
      studioAddress: data['studioAddress']?.toString(),
      studioPhone: data['studioPhone']?.toString(),
      studioEmail: data['studioEmail']?.toString(),
      suggestedPrice: (data['suggestedPrice'] as num?)?.toDouble(),
      notes: data['notes']?.toString(),
      isAccepted: data['isAccepted'] == true,
      isRejected: data['isRejected'] == true,
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      rejectedAt: data['rejectedAt'] != null
          ? (data['rejectedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  final String id;
  final String bookingId;
  final String photographerId;
  final String studioId;
  final DateTime suggestedAt;
  final String? photographerName;
  final String? photographerAvatar;
  final String? studioName;
  final String? studioAvatar;
  final String? studioAddress;
  final String? studioPhone;
  final String? studioEmail;
  final double? suggestedPrice;
  final String? notes;
  final bool isAccepted;
  final bool isRejected;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'bookingId': bookingId,
        'photographerId': photographerId,
        'studioId': studioId,
        'suggestedAt': Timestamp.fromDate(suggestedAt),
        'photographerName': photographerName,
        'photographerAvatar': photographerAvatar,
        'studioName': studioName,
        'studioAvatar': studioAvatar,
        'studioAddress': studioAddress,
        'studioPhone': studioPhone,
        'studioEmail': studioEmail,
        'suggestedPrice': suggestedPrice,
        'notes': notes,
        'isAccepted': isAccepted,
        'isRejected': isRejected,
        'acceptedAt':
            acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
        'rejectedAt':
            rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
        'metadata': metadata,
      };

  /// Проверить, является ли предложение активным
  bool get isActive => !isAccepted && !isRejected;

  /// Получить отформатированную цену
  String get formattedPrice {
    if (suggestedPrice == null) return 'Цена не указана';
    return '${suggestedPrice!.toStringAsFixed(0)} ₽';
  }

  /// Получить время в читаемом формате
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(suggestedAt);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}м назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}д назад';
    } else {
      return '${(difference.inDays / 7).floor()}н назад';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudioSuggestion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'StudioSuggestion(id: $id, bookingId: $bookingId, studioId: $studioId, isActive: $isActive)';
}
