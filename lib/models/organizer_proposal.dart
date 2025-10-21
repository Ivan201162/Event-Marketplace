import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус предложения организатора
enum ProposalStatus {
  pending, // Ожидает рассмотрения
  accepted, // Принято
  rejected, // Отклонено
  cancelled, // Отменено
  completed, // Завершено
}

/// Модель предложения организатора заказчику
class OrganizerProposal {
  const OrganizerProposal({
    required this.id,
    required this.organizerId,
    required this.customerId,
    required this.eventId,
    required this.title,
    required this.description,
    required this.proposedBudget,
    this.teamMembers = const [],
    this.services = const [],
    this.timeline,
    this.terms,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.customerResponse,
    this.customerResponseAt,
    this.notes,
  });

  /// Создать предложение из документа Firestore
  factory OrganizerProposal.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return OrganizerProposal(
      id: doc.id,
      organizerId: data['organizerId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      eventId: data['eventId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      proposedBudget: (data['proposedBudget'] as num?)?.toDouble() ?? 0.0,
      teamMembers: List<String>.from(data['teamMembers'] as List<dynamic>? ?? []),
      services: List<String>.from(data['services'] as List<dynamic>? ?? []),
      timeline: data['timeline'] as Map<String, dynamic>?,
      terms: data['terms'] as Map<String, dynamic>?,
      status: ProposalStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ProposalStatus.pending,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      customerResponse: data['customerResponse'] as String?,
      customerResponseAt: data['customerResponseAt'] != null
          ? (data['customerResponseAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'] as String?,
    );
  }

  final String id;
  final String organizerId;
  final String customerId;
  final String eventId;
  final String title;
  final String description;
  final double proposedBudget;
  final List<String> teamMembers;
  final List<String> services;
  final Map<String, dynamic>? timeline;
  final Map<String, dynamic>? terms;
  final ProposalStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? customerResponse;
  final DateTime? customerResponseAt;
  final String? notes;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'organizerId': organizerId,
    'customerId': customerId,
    'eventId': eventId,
    'title': title,
    'description': description,
    'proposedBudget': proposedBudget,
    'teamMembers': teamMembers,
    'services': services,
    'timeline': timeline,
    'terms': terms,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'customerResponse': customerResponse,
    'customerResponseAt': customerResponseAt != null
        ? Timestamp.fromDate(customerResponseAt!)
        : null,
    'notes': notes,
  };

  /// Создать копию с изменениями
  OrganizerProposal copyWith({
    String? id,
    String? organizerId,
    String? customerId,
    String? eventId,
    String? title,
    String? description,
    double? proposedBudget,
    List<String>? teamMembers,
    List<String>? services,
    Map<String, dynamic>? timeline,
    Map<String, dynamic>? terms,
    ProposalStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerResponse,
    DateTime? customerResponseAt,
    String? notes,
  }) => OrganizerProposal(
    id: id ?? this.id,
    organizerId: organizerId ?? this.organizerId,
    customerId: customerId ?? this.customerId,
    eventId: eventId ?? this.eventId,
    title: title ?? this.title,
    description: description ?? this.description,
    proposedBudget: proposedBudget ?? this.proposedBudget,
    teamMembers: teamMembers ?? this.teamMembers,
    services: services ?? this.services,
    timeline: timeline ?? this.timeline,
    terms: terms ?? this.terms,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    customerResponse: customerResponse ?? this.customerResponse,
    customerResponseAt: customerResponseAt ?? this.customerResponseAt,
    notes: notes ?? this.notes,
  );

  /// Получить отображаемое название статуса
  String get statusDisplayName {
    switch (status) {
      case ProposalStatus.pending:
        return 'Ожидает рассмотрения';
      case ProposalStatus.accepted:
        return 'Принято';
      case ProposalStatus.rejected:
        return 'Отклонено';
      case ProposalStatus.cancelled:
        return 'Отменено';
      case ProposalStatus.completed:
        return 'Завершено';
    }
  }

  /// Получить цвет статуса
  String get statusColor {
    switch (status) {
      case ProposalStatus.pending:
        return 'orange';
      case ProposalStatus.accepted:
        return 'green';
      case ProposalStatus.rejected:
        return 'red';
      case ProposalStatus.cancelled:
        return 'grey';
      case ProposalStatus.completed:
        return 'blue';
    }
  }

  /// Проверить, можно ли отменить предложение
  bool get canCancel => status == ProposalStatus.pending;

  /// Проверить, можно ли принять предложение
  bool get canAccept => status == ProposalStatus.pending;

  /// Проверить, можно ли отклонить предложение
  bool get canReject => status == ProposalStatus.pending;

  /// Получить форматированный бюджет
  String get formattedBudget => '${proposedBudget.toStringAsFixed(0)} ₽';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrganizerProposal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'OrganizerProposal(id: $id, title: $title, status: $status)';
}

/// Расширение для ProposalStatus
extension ProposalStatusExtension on ProposalStatus {
  String get displayName {
    switch (this) {
      case ProposalStatus.pending:
        return 'Ожидает рассмотрения';
      case ProposalStatus.accepted:
        return 'Принято';
      case ProposalStatus.rejected:
        return 'Отклонено';
      case ProposalStatus.cancelled:
        return 'Отменено';
      case ProposalStatus.completed:
        return 'Завершено';
    }
  }

  String get icon {
    switch (this) {
      case ProposalStatus.pending:
        return '⏳';
      case ProposalStatus.accepted:
        return '✅';
      case ProposalStatus.rejected:
        return '❌';
      case ProposalStatus.cancelled:
        return '🚫';
      case ProposalStatus.completed:
        return '🎉';
    }
  }
}
