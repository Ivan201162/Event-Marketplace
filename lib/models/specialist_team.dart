import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус команды специалистов
enum TeamStatus {
  draft, // Черновик
  confirmed, // Подтверждена
  rejected, // Отклонена
  active, // Активна
  completed, // Завершена
}

/// Модель команды специалистов
class SpecialistTeam {
  const SpecialistTeam({
    required this.id,
    required this.organizerId,
    required this.eventId,
    required this.specialists,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.eventTitle,
    this.eventDate,
    this.eventLocation,
    this.totalPrice,
    this.notes,
    this.confirmedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.teamName,
    this.description,
    this.specialistRoles = const {}, // Роли специалистов в команде
    this.paymentSplit = const {}, // Разделение оплаты между участниками
  });

  /// Создать из документа Firestore
  factory SpecialistTeam.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return SpecialistTeam(
      id: doc.id,
      organizerId: data['organizerId'] as String? ?? '',
      eventId: data['eventId'] as String? ?? '',
      specialists:
          List<String>.from(data['specialists'] as List<dynamic>? ?? []),
      status: TeamStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TeamStatus.draft,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      eventTitle: data['eventTitle'] as String?,
      eventDate: data['eventDate'] != null
          ? (data['eventDate'] as Timestamp).toDate()
          : null,
      eventLocation: data['eventLocation'] as String?,
      totalPrice: (data['totalPrice'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
      rejectedAt: data['rejectedAt'] != null
          ? (data['rejectedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: data['rejectionReason'] as String?,
      teamName: data['teamName'] as String?,
      description: data['description'] as String?,
      specialistRoles: Map<String, String>.from(
        data['specialistRoles'] as Map<dynamic, dynamic>? ?? {},
      ),
      paymentSplit: Map<String, double>.from(
          data['paymentSplit'] as Map<dynamic, dynamic>? ?? {}),
    );
  }

  final String id;
  final String organizerId;
  final String eventId;
  final List<String> specialists;
  final TeamStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? eventTitle;
  final DateTime? eventDate;
  final String? eventLocation;
  final double? totalPrice;
  final String? notes;
  final DateTime? confirmedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String? teamName;
  final String? description;
  final Map<String, String> specialistRoles; // specialistId -> role
  final Map<String, double> paymentSplit; // specialistId -> amount

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'organizerId': organizerId,
        'eventId': eventId,
        'specialists': specialists,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'eventTitle': eventTitle,
        'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
        'eventLocation': eventLocation,
        'totalPrice': totalPrice,
        'notes': notes,
        'confirmedAt':
            confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
        'rejectedAt':
            rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
        'rejectionReason': rejectionReason,
        'teamName': teamName,
        'description': description,
        'specialistRoles': specialistRoles,
        'paymentSplit': paymentSplit,
      };

  /// Создать копию с изменениями
  SpecialistTeam copyWith({
    String? id,
    String? organizerId,
    String? eventId,
    List<String>? specialists,
    TeamStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? eventTitle,
    DateTime? eventDate,
    String? eventLocation,
    double? totalPrice,
    String? notes,
    DateTime? confirmedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    String? teamName,
    String? description,
    Map<String, String>? specialistRoles,
    Map<String, double>? paymentSplit,
  }) =>
      SpecialistTeam(
        id: id ?? this.id,
        organizerId: organizerId ?? this.organizerId,
        eventId: eventId ?? this.eventId,
        specialists: specialists ?? this.specialists,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        eventTitle: eventTitle ?? this.eventTitle,
        eventDate: eventDate ?? this.eventDate,
        eventLocation: eventLocation ?? this.eventLocation,
        totalPrice: totalPrice ?? this.totalPrice,
        notes: notes ?? this.notes,
        confirmedAt: confirmedAt ?? this.confirmedAt,
        rejectedAt: rejectedAt ?? this.rejectedAt,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        teamName: teamName ?? this.teamName,
        description: description ?? this.description,
        specialistRoles: specialistRoles ?? this.specialistRoles,
        paymentSplit: paymentSplit ?? this.paymentSplit,
      );

  /// Проверить, является ли команда активной
  bool get isActive => status == TeamStatus.active;

  /// Проверить, подтверждена ли команда
  bool get isConfirmed => status == TeamStatus.confirmed;

  /// Проверить, отклонена ли команда
  bool get isRejected => status == TeamStatus.rejected;

  /// Проверить, является ли команда черновиком
  bool get isDraft => status == TeamStatus.draft;

  /// Получить количество специалистов в команде
  int get specialistCount => specialists.length;

  /// Проверить, содержит ли команда специалиста
  bool containsSpecialist(String specialistId) =>
      specialists.contains(specialistId);

  /// Получить роль специалиста в команде
  String? getSpecialistRole(String specialistId) =>
      specialistRoles[specialistId];

  /// Получить долю оплаты специалиста
  double getSpecialistPayment(String specialistId) =>
      paymentSplit[specialistId] ?? 0.0;

  /// Получить общую сумму оплаты
  double get totalPaymentAmount =>
      paymentSplit.values.fold(0, (sum, amount) => sum + amount);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialistTeam && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SpecialistTeam(id: $id, eventId: $eventId, specialists: ${specialists.length}, status: $status)';
}

/// Расширение для получения названий статусов
extension TeamStatusExtension on TeamStatus {
  String get displayName {
    switch (this) {
      case TeamStatus.draft:
        return 'Черновик';
      case TeamStatus.confirmed:
        return 'Подтверждена';
      case TeamStatus.rejected:
        return 'Отклонена';
      case TeamStatus.active:
        return 'Активна';
      case TeamStatus.completed:
        return 'Завершена';
    }
  }

  String get description {
    switch (this) {
      case TeamStatus.draft:
        return 'Команда находится в процессе формирования';
      case TeamStatus.confirmed:
        return 'Команда подтверждена и готова к работе';
      case TeamStatus.rejected:
        return 'Команда отклонена заказчиком';
      case TeamStatus.active:
        return 'Команда активно работает над мероприятием';
      case TeamStatus.completed:
        return 'Работа команды завершена';
    }
  }
}
