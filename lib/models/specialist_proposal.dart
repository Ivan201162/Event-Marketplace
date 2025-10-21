import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель предложения специалистов от организатора
class SpecialistProposal {
  const SpecialistProposal({
    required this.id,
    required this.organizerId,
    required this.customerId,
    required this.specialistIds,
    required this.title,
    required this.description,
    required this.createdAt,
    this.organizerName,
    this.organizerAvatar,
    this.customerName,
    this.customerAvatar,
    this.isAccepted = false,
    this.isRejected = false,
    this.acceptedSpecialistId,
    this.rejectedAt,
    this.acceptedAt,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory SpecialistProposal.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistProposal(
      id: doc.id,
      organizerId: data['organizerId']?.toString() ?? '',
      customerId: data['customerId']?.toString() ?? '',
      specialistIds:
          (data['specialistIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      organizerName: data['organizerName']?.toString(),
      organizerAvatar: data['organizerAvatar']?.toString(),
      customerName: data['customerName']?.toString(),
      customerAvatar: data['customerAvatar']?.toString(),
      isAccepted: data['isAccepted'] == true,
      isRejected: data['isRejected'] == true,
      acceptedSpecialistId: data['acceptedSpecialistId']?.toString(),
      rejectedAt: data['rejectedAt'] != null ? (data['rejectedAt'] as Timestamp).toDate() : null,
      acceptedAt: data['acceptedAt'] != null ? (data['acceptedAt'] as Timestamp).toDate() : null,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  /// Создать из Map
  factory SpecialistProposal.fromMap(Map<String, dynamic> data) => SpecialistProposal(
    id: data['id']?.toString() ?? '',
    organizerId: data['organizerId']?.toString() ?? '',
    customerId: data['customerId']?.toString() ?? '',
    specialistIds:
        (data['specialistIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    title: data['title']?.toString() ?? '',
    description: data['description']?.toString() ?? '',
    createdAt: data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
    organizerName: data['organizerName']?.toString(),
    organizerAvatar: data['organizerAvatar']?.toString(),
    customerName: data['customerName']?.toString(),
    customerAvatar: data['customerAvatar']?.toString(),
    isAccepted: data['isAccepted'] == true,
    isRejected: data['isRejected'] == true,
    acceptedSpecialistId: data['acceptedSpecialistId']?.toString(),
    rejectedAt: data['rejectedAt'] != null ? (data['rejectedAt'] as Timestamp).toDate() : null,
    acceptedAt: data['acceptedAt'] != null ? (data['acceptedAt'] as Timestamp).toDate() : null,
    metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
  );

  final String id;
  final String organizerId;
  final String customerId;
  final List<String> specialistIds;
  final String title;
  final String description;
  final DateTime createdAt;
  final String? organizerName;
  final String? organizerAvatar;
  final String? customerName;
  final String? customerAvatar;
  final bool isAccepted;
  final bool isRejected;
  final String? acceptedSpecialistId;
  final DateTime? rejectedAt;
  final DateTime? acceptedAt;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'organizerId': organizerId,
    'customerId': customerId,
    'specialistIds': specialistIds,
    'title': title,
    'description': description,
    'createdAt': Timestamp.fromDate(createdAt),
    'organizerName': organizerName,
    'organizerAvatar': organizerAvatar,
    'customerName': customerName,
    'customerAvatar': customerAvatar,
    'isAccepted': isAccepted,
    'isRejected': isRejected,
    'acceptedSpecialistId': acceptedSpecialistId,
    'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
    'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
    'metadata': metadata,
  };

  /// Создать копию с изменениями
  SpecialistProposal copyWith({
    String? id,
    String? organizerId,
    String? customerId,
    List<String>? specialistIds,
    String? title,
    String? description,
    DateTime? createdAt,
    String? organizerName,
    String? organizerAvatar,
    String? customerName,
    String? customerAvatar,
    bool? isAccepted,
    bool? isRejected,
    String? acceptedSpecialistId,
    DateTime? rejectedAt,
    DateTime? acceptedAt,
    Map<String, dynamic>? metadata,
  }) => SpecialistProposal(
    id: id ?? this.id,
    organizerId: organizerId ?? this.organizerId,
    customerId: customerId ?? this.customerId,
    specialistIds: specialistIds ?? this.specialistIds,
    title: title ?? this.title,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    organizerName: organizerName ?? this.organizerName,
    organizerAvatar: organizerAvatar ?? this.organizerAvatar,
    customerName: customerName ?? this.customerName,
    customerAvatar: customerAvatar ?? this.customerAvatar,
    isAccepted: isAccepted ?? this.isAccepted,
    isRejected: isRejected ?? this.isRejected,
    acceptedSpecialistId: acceptedSpecialistId ?? this.acceptedSpecialistId,
    rejectedAt: rejectedAt ?? this.rejectedAt,
    acceptedAt: acceptedAt ?? this.acceptedAt,
    metadata: metadata ?? this.metadata,
  );

  /// Проверить, есть ли специалисты в предложении
  bool get hasSpecialists => specialistIds.isNotEmpty;

  /// Получить количество специалистов
  int get specialistCount => specialistIds.length;

  /// Проверить, является ли предложение активным
  bool get isActive => !isAccepted && !isRejected;

  /// Проверить, является ли предложение завершенным
  bool get isCompleted => isAccepted || isRejected;

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
    return other is SpecialistProposal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SpecialistProposal(id: $id, title: $title, specialistCount: $specialistCount, isActive: $isActive)';
}

/// Модель для создания предложения специалистов
class CreateSpecialistProposal {
  const CreateSpecialistProposal({
    required this.organizerId,
    required this.customerId,
    required this.specialistIds,
    required this.title,
    required this.description,
    this.organizerName,
    this.organizerAvatar,
    this.customerName,
    this.customerAvatar,
    this.metadata = const {},
  });

  final String organizerId;
  final String customerId;
  final List<String> specialistIds;
  final String title;
  final String description;
  final String? organizerName;
  final String? organizerAvatar;
  final String? customerName;
  final String? customerAvatar;
  final Map<String, dynamic> metadata;

  bool get isValid =>
      organizerId.isNotEmpty &&
      customerId.isNotEmpty &&
      specialistIds.isNotEmpty &&
      title.isNotEmpty &&
      description.isNotEmpty;

  List<String> get validationErrors {
    final errors = <String>[];
    if (organizerId.isEmpty) errors.add('ID организатора обязателен');
    if (customerId.isEmpty) errors.add('ID клиента обязателен');
    if (specialistIds.isEmpty) {
      errors.add('Необходимо выбрать хотя бы одного специалиста');
    }
    if (title.isEmpty) errors.add('Заголовок обязателен');
    if (description.isEmpty) errors.add('Описание обязательно');
    return errors;
  }
}
