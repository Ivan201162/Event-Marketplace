import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип сообщения в чате с организатором
enum OrganizerMessageType {
  text, // Текстовое сообщение
  specialistProposal, // Предложение специалиста
  specialistRejection, // Отклонение специалиста
  bookingRequest, // Запрос на бронирование
  bookingConfirmation, // Подтверждение бронирования
  bookingCancellation, // Отмена бронирования
  file, // Файл
  image, // Изображение
  system, // Системное сообщение
}

/// Статус чата с организатором
enum OrganizerChatStatus {
  active, // Активный
  closed, // Закрыт
  archived, // Архивирован
  pending, // Ожидает ответа
}

/// Модель чата между заказчиком и организатором
class OrganizerChat {
  const OrganizerChat({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.organizerId,
    required this.organizerName,
    required this.eventTitle,
    required this.eventDate, required this.status, required this.messages, required this.createdAt, required this.updatedAt, this.eventDescription,
    this.lastMessageAt,
    this.lastMessageText,
    this.hasUnreadMessages = false,
    this.unreadCount = 0,
  });

  /// Создать из документа Firestore
  factory OrganizerChat.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return OrganizerChat(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      eventDescription: data['eventDescription'],
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      status: OrganizerChatStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrganizerChatStatus.active,
      ),
      messages: (data['messages'] as List<dynamic>?)
              ?.map((msg) => OrganizerMessage.fromMap(msg))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastMessageText: data['lastMessageText'],
      hasUnreadMessages: data['hasUnreadMessages'] as bool? ?? false,
      unreadCount: data['unreadCount'] as int? ?? 0,
    );
  }
  final String id;
  final String customerId;
  final String customerName;
  final String organizerId;
  final String organizerName;
  final String eventTitle;
  final String? eventDescription;
  final DateTime eventDate;
  final OrganizerChatStatus status;
  final List<OrganizerMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final String? lastMessageText;
  final bool hasUnreadMessages;
  final int unreadCount;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'customerName': customerName,
        'organizerId': organizerId,
        'organizerName': organizerName,
        'eventTitle': eventTitle,
        'eventDescription': eventDescription,
        'eventDate': Timestamp.fromDate(eventDate),
        'status': status.name,
        'messages': messages.map((msg) => msg.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'lastMessageAt':
            lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
        'lastMessageText': lastMessageText,
        'hasUnreadMessages': hasUnreadMessages,
        'unreadCount': unreadCount,
      };

  /// Создать копию с изменениями
  OrganizerChat copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? organizerId,
    String? organizerName,
    String? eventTitle,
    String? eventDescription,
    DateTime? eventDate,
    OrganizerChatStatus? status,
    List<OrganizerMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    String? lastMessageText,
    bool? hasUnreadMessages,
    int? unreadCount,
  }) =>
      OrganizerChat(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        organizerId: organizerId ?? this.organizerId,
        organizerName: organizerName ?? this.organizerName,
        eventTitle: eventTitle ?? this.eventTitle,
        eventDescription: eventDescription ?? this.eventDescription,
        eventDate: eventDate ?? this.eventDate,
        status: status ?? this.status,
        messages: messages ?? this.messages,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        lastMessageText: lastMessageText ?? this.lastMessageText,
        hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
        unreadCount: unreadCount ?? this.unreadCount,
      );

  /// Добавить сообщение
  OrganizerChat addMessage(OrganizerMessage message) {
    final updatedMessages = [...messages, message];
    return copyWith(
      messages: updatedMessages,
      lastMessageAt: message.createdAt,
      lastMessageText: message.text,
      updatedAt: DateTime.now(),
    );
  }

  /// Отметить сообщения как прочитанные
  OrganizerChat markAsRead() =>
      copyWith(hasUnreadMessages: false, unreadCount: 0);

  /// Обновить статус чата
  OrganizerChat updateStatus(OrganizerChatStatus newStatus) =>
      copyWith(status: newStatus, updatedAt: DateTime.now());
}

/// Модель сообщения в чате с организатором
class OrganizerMessage {
  const OrganizerMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.type,
    required this.text,
    required this.createdAt, this.metadata,
    this.isRead = false,
    this.readAt,
  });

  /// Создать из Map
  factory OrganizerMessage.fromMap(Map<String, dynamic> map) =>
      OrganizerMessage(
        id: map['id'] ?? '',
        chatId: map['chatId'] ?? '',
        senderId: map['senderId'] ?? '',
        senderName: map['senderName'] ?? '',
        senderType: map['senderType'] ?? '',
        type: OrganizerMessageType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => OrganizerMessageType.text,
        ),
        text: map['text'] ?? '',
        metadata: map['metadata'],
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        isRead: map['isRead'] ?? false,
        readAt: map['readAt'] != null
            ? (map['readAt'] as Timestamp).toDate()
            : null,
      );
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderType; // 'customer' или 'organizer'
  final OrganizerMessageType type;
  final String text;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'senderType': senderType,
        'type': type.name,
        'text': text,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
        'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      };

  /// Создать копию с изменениями
  OrganizerMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderType,
    OrganizerMessageType? type,
    String? text,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
  }) =>
      OrganizerMessage(
        id: id ?? this.id,
        chatId: chatId ?? this.chatId,
        senderId: senderId ?? this.senderId,
        senderName: senderName ?? this.senderName,
        senderType: senderType ?? this.senderType,
        type: type ?? this.type,
        text: text ?? this.text,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
      );

  /// Отметить как прочитанное
  OrganizerMessage markAsRead() =>
      copyWith(isRead: true, readAt: DateTime.now());

  /// Проверить, является ли отправитель заказчиком
  bool get isFromCustomer => senderType == 'customer';

  /// Проверить, является ли отправитель организатором
  bool get isFromOrganizer => senderType == 'organizer';

  /// Получить тип сообщения для отображения
  String get displayType {
    switch (type) {
      case OrganizerMessageType.text:
        return 'Сообщение';
      case OrganizerMessageType.specialistProposal:
        return 'Предложение специалиста';
      case OrganizerMessageType.specialistRejection:
        return 'Отклонение специалиста';
      case OrganizerMessageType.bookingRequest:
        return 'Запрос на бронирование';
      case OrganizerMessageType.bookingConfirmation:
        return 'Подтверждение бронирования';
      case OrganizerMessageType.bookingCancellation:
        return 'Отмена бронирования';
      case OrganizerMessageType.file:
        return 'Файл';
      case OrganizerMessageType.image:
        return 'Изображение';
      case OrganizerMessageType.system:
        return 'Системное сообщение';
    }
  }
}

/// Предложение специалиста от организатора
class SpecialistProposal {
  const SpecialistProposal({
    required this.specialistId,
    required this.specialistName,
    required this.specialistCategory,
    required this.hourlyRate,
    required this.services, required this.rating, required this.reviewCount, required this.isAvailable, this.specialistPhoto,
    this.description,
  });

  /// Создать из Map
  factory SpecialistProposal.fromMap(Map<String, dynamic> map) =>
      SpecialistProposal(
        specialistId: map['specialistId'] ?? '',
        specialistName: map['specialistName'] ?? '',
        specialistCategory: map['specialistCategory'] ?? '',
        hourlyRate: (map['hourlyRate'] ?? 0.0).toDouble(),
        specialistPhoto: map['specialistPhoto'],
        description: map['description'],
        services: List<String>.from(map['services'] ?? []),
        rating: (map['rating'] ?? 0.0).toDouble(),
        reviewCount: map['reviewCount'] ?? 0,
        isAvailable: map['isAvailable'] ?? false,
      );
  final String specialistId;
  final String specialistName;
  final String specialistCategory;
  final double hourlyRate;
  final String? specialistPhoto;
  final String? description;
  final List<String> services;
  final double rating;
  final int reviewCount;
  final bool isAvailable;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'specialistName': specialistName,
        'specialistCategory': specialistCategory,
        'hourlyRate': hourlyRate,
        'specialistPhoto': specialistPhoto,
        'description': description,
        'services': services,
        'rating': rating,
        'reviewCount': reviewCount,
        'isAvailable': isAvailable,
      };
}
