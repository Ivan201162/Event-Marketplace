import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Типы договоров
enum ContractType {
  service, // Договор на оказание услуг
  rental, // Договор аренды
  supply, // Договор поставки
}

/// Статусы договоров
enum ContractStatus {
  draft, // Черновик
  pending, // Ожидает подписания
  signed, // Подписан
  active, // Действующий
  completed, // Завершен
  cancelled, // Отменен
  expired, // Истек
}

/// Информация о стороне договора
class PartyInfo {
  const PartyInfo({
    required this.id,
    required this.name,
    required this.type,
    this.inn,
    this.ogrn,
    this.address,
    this.phone,
    this.email,
    this.bankDetails,
  });

  final String id;
  final String name; // ФИО или название организации
  final String type; // физлицо/ИП/самозанятый/госучреждение
  final String? inn;
  final String? ogrn;
  final String? address;
  final String? phone;
  final String? email;
  final Map<String, dynamic>? bankDetails;

  factory PartyInfo.fromMap(Map<String, dynamic> map) => PartyInfo(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        type: map['type'] ?? '',
        inn: map['inn'],
        ogrn: map['ogrn'],
        address: map['address'],
        phone: map['phone'],
        email: map['email'],
        bankDetails: map['bankDetails'] != null
            ? Map<String, dynamic>.from(map['bankDetails'])
            : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'inn': inn,
        'ogrn': ogrn,
        'address': address,
        'phone': phone,
        'email': email,
        'bankDetails': bankDetails,
      };
}

/// Информация об услуге в договоре
class ServiceInfo {
  const ServiceInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
    required this.total,
    this.unit,
  });

  final String id;
  final String name;
  final String description;
  final double quantity;
  final double price;
  final double total;
  final String? unit; // единица измерения

  factory ServiceInfo.fromMap(Map<String, dynamic> map) => ServiceInfo(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        total: (map['total'] as num?)?.toDouble() ?? 0.0,
        unit: map['unit'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'quantity': quantity,
        'price': price,
        'total': total,
        'unit': unit,
      };
}

/// Модель договора
class Contract {
  const Contract({
    required this.id,
    required this.contractNumber,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.type,
    required this.status,
    required this.title,
    required this.content,
    required this.terms,
    required this.createdAt,
    required this.updatedAt,
    this.signedAt,
    required this.expiresAt,
    required this.metadata,
    this.specialistName,
    this.startDate,
    this.endDate,
    this.totalAmount,
    this.currency,
    this.partiesInfo,
    this.servicesList,
  });

  /// Создать из документа Firestore
  factory Contract.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Contract(
      id: doc.id,
      contractNumber: data['contractNumber'] as String? ?? '',
      bookingId: data['bookingId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      type: ContractType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ContractType.service,
      ),
      status: ContractStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ContractStatus.draft,
      ),
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      terms: Map<String, dynamic>.from(
          data['terms'] as Map<dynamic, dynamic>? ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      signedAt: data['signedAt'] != null
          ? (data['signedAt'] as Timestamp).toDate()
          : null,
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(
          data['metadata'] as Map<dynamic, dynamic>? ?? {}),
      specialistName: data['specialistName'] as String?,
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      totalAmount: data['totalAmount'] as double?,
      currency: data['currency'] as String?,
      partiesInfo: data['partiesInfo'] != null
          ? (data['partiesInfo'] as Map<String, dynamic>).map((key, value) =>
              MapEntry(key, PartyInfo.fromMap(value as Map<String, dynamic>)))
          : null,
      servicesList: data['servicesList'] != null
          ? (data['servicesList'] as List<dynamic>)
              .map((item) => ServiceInfo.fromMap(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
  final String id;
  final String contractNumber;
  final String bookingId;
  final String customerId;
  final String specialistId;
  final ContractType type;
  final ContractStatus status;
  final String title;
  final String content;
  final Map<String, dynamic> terms;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? signedAt;
  final DateTime expiresAt;
  final Map<String, dynamic> metadata;
  final String? specialistName;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? totalAmount;
  final String? currency;
  final Map<String, PartyInfo>? partiesInfo;
  final List<ServiceInfo>? servicesList;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'contractNumber': contractNumber,
        'bookingId': bookingId,
        'customerId': customerId,
        'specialistId': specialistId,
        'type': type.name,
        'status': status.name,
        'title': title,
        'content': content,
        'terms': terms,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'signedAt': signedAt != null ? Timestamp.fromDate(signedAt!) : null,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'metadata': metadata,
        'specialistName': specialistName,
        'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'totalAmount': totalAmount,
        'currency': currency,
        'partiesInfo':
            partiesInfo?.map((key, value) => MapEntry(key, value.toMap())),
        'servicesList':
            servicesList?.map((service) => service.toMap()).toList(),
      };

  /// Создать копию с изменениями
  Contract copyWith({
    String? id,
    String? contractNumber,
    String? bookingId,
    String? customerId,
    String? specialistId,
    ContractType? type,
    ContractStatus? status,
    String? title,
    String? content,
    Map<String, dynamic>? terms,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? signedAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
    Map<String, PartyInfo>? partiesInfo,
    List<ServiceInfo>? servicesList,
  }) =>
      Contract(
        id: id ?? this.id,
        contractNumber: contractNumber ?? this.contractNumber,
        bookingId: bookingId ?? this.bookingId,
        customerId: customerId ?? this.customerId,
        specialistId: specialistId ?? this.specialistId,
        type: type ?? this.type,
        status: status ?? this.status,
        title: title ?? this.title,
        content: content ?? this.content,
        terms: terms ?? this.terms,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        signedAt: signedAt ?? this.signedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        metadata: metadata ?? this.metadata,
        specialistName: specialistName ?? this.specialistName,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        totalAmount: totalAmount ?? this.totalAmount,
        currency: currency ?? this.currency,
        partiesInfo: partiesInfo ?? this.partiesInfo,
        servicesList: servicesList ?? this.servicesList,
      );
}

/// Расширение для ContractStatus
extension ContractStatusExtension on ContractStatus {
  Color get statusColor {
    switch (this) {
      case ContractStatus.draft:
        return Colors.grey;
      case ContractStatus.pending:
        return Colors.orange;
      case ContractStatus.signed:
        return Colors.blue;
      case ContractStatus.active:
        return Colors.green;
      case ContractStatus.completed:
        return Colors.purple;
      case ContractStatus.cancelled:
        return Colors.red;
      case ContractStatus.expired:
        return Colors.brown;
    }
  }

  String get statusText {
    switch (this) {
      case ContractStatus.draft:
        return 'Черновик';
      case ContractStatus.pending:
        return 'Ожидает подписания';
      case ContractStatus.signed:
        return 'Подписан';
      case ContractStatus.active:
        return 'Действующий';
      case ContractStatus.completed:
        return 'Завершен';
      case ContractStatus.cancelled:
        return 'Отменен';
      case ContractStatus.expired:
        return 'Истек';
    }
  }
}
