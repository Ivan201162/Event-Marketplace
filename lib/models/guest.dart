import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель гостя
class Guest {
  final String id;
  final String eventId;
  final String eventTitle;
  final String guestName;
  final String guestEmail;
  final String? guestPhone;
  final String? guestPhotoUrl;
  final GuestStatus status;
  final DateTime? registeredAt;
  final DateTime? confirmedAt;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String? qrCode;
  final String? invitationCode;
  final Map<String, dynamic> metadata;
  final List<GuestGreeting> greetings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Guest({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.guestName,
    required this.guestEmail,
    this.guestPhone,
    this.guestPhotoUrl,
    required this.status,
    this.registeredAt,
    this.confirmedAt,
    this.checkedInAt,
    this.checkedOutAt,
    this.qrCode,
    this.invitationCode,
    this.metadata = const {},
    this.greetings = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Guest.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Guest(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      guestName: data['guestName'] ?? '',
      guestEmail: data['guestEmail'] ?? '',
      guestPhone: data['guestPhone'],
      guestPhotoUrl: data['guestPhotoUrl'],
      status: GuestStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => GuestStatus.invited,
      ),
      registeredAt: (data['registeredAt'] as Timestamp?)?.toDate(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      checkedInAt: (data['checkedInAt'] as Timestamp?)?.toDate(),
      checkedOutAt: (data['checkedOutAt'] as Timestamp?)?.toDate(),
      qrCode: data['qrCode'],
      invitationCode: data['invitationCode'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      greetings: (data['greetings'] as List<dynamic>?)
              ?.map((e) => GuestGreeting.fromMap(e))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'guestName': guestName,
      'guestEmail': guestEmail,
      'guestPhone': guestPhone,
      'guestPhotoUrl': guestPhotoUrl,
      'status': status.name,
      'registeredAt':
          registeredAt != null ? Timestamp.fromDate(registeredAt!) : null,
      'confirmedAt':
          confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'checkedInAt':
          checkedInAt != null ? Timestamp.fromDate(checkedInAt!) : null,
      'checkedOutAt':
          checkedOutAt != null ? Timestamp.fromDate(checkedOutAt!) : null,
      'qrCode': qrCode,
      'invitationCode': invitationCode,
      'metadata': metadata,
      'greetings': greetings.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Guest copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    String? guestName,
    String? guestEmail,
    String? guestPhone,
    String? guestPhotoUrl,
    GuestStatus? status,
    DateTime? registeredAt,
    DateTime? confirmedAt,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
    String? qrCode,
    String? invitationCode,
    Map<String, dynamic>? metadata,
    List<GuestGreeting>? greetings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Guest(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      guestName: guestName ?? this.guestName,
      guestEmail: guestEmail ?? this.guestEmail,
      guestPhone: guestPhone ?? this.guestPhone,
      guestPhotoUrl: guestPhotoUrl ?? this.guestPhotoUrl,
      status: status ?? this.status,
      registeredAt: registeredAt ?? this.registeredAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      qrCode: qrCode ?? this.qrCode,
      invitationCode: invitationCode ?? this.invitationCode,
      metadata: metadata ?? this.metadata,
      greetings: greetings ?? this.greetings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Проверить, зарегистрирован ли гость
  bool get isRegistered => registeredAt != null;

  /// Проверить, подтвердил ли гость участие
  bool get isConfirmed => confirmedAt != null;

  /// Проверить, зарегистрировался ли гость на мероприятие
  bool get isCheckedIn => checkedInAt != null;

  /// Проверить, покинул ли гость мероприятие
  bool get isCheckedOut => checkedOutAt != null;

  /// Получить количество поздравлений
  int get greetingsCount => greetings.length;

  /// Получить цвет статуса
  Color get statusColor {
    switch (status) {
      case GuestStatus.invited:
        return Colors.blue;
      case GuestStatus.registered:
        return Colors.orange;
      case GuestStatus.confirmed:
        return Colors.green;
      case GuestStatus.checkedIn:
        return Colors.purple;
      case GuestStatus.checkedOut:
        return Colors.grey;
      case GuestStatus.cancelled:
        return Colors.red;
    }
  }

  /// Получить текст статуса
  String get statusText {
    switch (status) {
      case GuestStatus.invited:
        return 'Приглашен';
      case GuestStatus.registered:
        return 'Зарегистрирован';
      case GuestStatus.confirmed:
        return 'Подтвержден';
      case GuestStatus.checkedIn:
        return 'На мероприятии';
      case GuestStatus.checkedOut:
        return 'Покинул мероприятие';
      case GuestStatus.cancelled:
        return 'Отменил участие';
    }
  }
}

/// Статус гостя
enum GuestStatus {
  invited,
  registered,
  confirmed,
  checkedIn,
  checkedOut,
  cancelled,
}

/// Поздравление от гостя
class GuestGreeting {
  final String id;
  final String guestId;
  final String guestName;
  final String message;
  final String? photoUrl;
  final String? videoUrl;
  final GreetingType type;
  final bool isPublic;
  final DateTime createdAt;

  const GuestGreeting({
    required this.id,
    required this.guestId,
    required this.guestName,
    required this.message,
    this.photoUrl,
    this.videoUrl,
    required this.type,
    this.isPublic = true,
    required this.createdAt,
  });

  factory GuestGreeting.fromMap(Map<String, dynamic> map) {
    return GuestGreeting(
      id: map['id'] ?? '',
      guestId: map['guestId'] ?? '',
      guestName: map['guestName'] ?? '',
      message: map['message'] ?? '',
      photoUrl: map['photoUrl'],
      videoUrl: map['videoUrl'],
      type: GreetingType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => GreetingType.text,
      ),
      isPublic: map['isPublic'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guestId': guestId,
      'guestName': guestName,
      'message': message,
      'photoUrl': photoUrl,
      'videoUrl': videoUrl,
      'type': type.name,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  GuestGreeting copyWith({
    String? id,
    String? guestId,
    String? guestName,
    String? message,
    String? photoUrl,
    String? videoUrl,
    GreetingType? type,
    bool? isPublic,
    DateTime? createdAt,
  }) {
    return GuestGreeting(
      id: id ?? this.id,
      guestId: guestId ?? this.guestId,
      guestName: guestName ?? this.guestName,
      message: message ?? this.message,
      photoUrl: photoUrl ?? this.photoUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      type: type ?? this.type,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Тип поздравления
enum GreetingType {
  text,
  photo,
  video,
  audio,
}

/// Событие для гостей
class GuestEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String organizerId;
  final String organizerName;
  final String? organizerPhotoUrl;
  final String? eventPhotoUrl;
  final int maxGuests;
  final int currentGuests;
  final bool isPublic;
  final bool allowGreetings;
  final String? invitationLink;
  final String? qrCode;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GuestEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.organizerId,
    required this.organizerName,
    this.organizerPhotoUrl,
    this.eventPhotoUrl,
    required this.maxGuests,
    required this.currentGuests,
    this.isPublic = true,
    this.allowGreetings = true,
    this.invitationLink,
    this.qrCode,
    this.settings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory GuestEvent.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GuestEvent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] ?? '',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      organizerPhotoUrl: data['organizerPhotoUrl'],
      eventPhotoUrl: data['eventPhotoUrl'],
      maxGuests: data['maxGuests'] ?? 0,
      currentGuests: data['currentGuests'] ?? 0,
      isPublic: data['isPublic'] ?? true,
      allowGreetings: data['allowGreetings'] ?? true,
      invitationLink: data['invitationLink'],
      qrCode: data['qrCode'],
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerPhotoUrl': organizerPhotoUrl,
      'eventPhotoUrl': eventPhotoUrl,
      'maxGuests': maxGuests,
      'currentGuests': currentGuests,
      'isPublic': isPublic,
      'allowGreetings': allowGreetings,
      'invitationLink': invitationLink,
      'qrCode': qrCode,
      'settings': settings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  GuestEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? organizerId,
    String? organizerName,
    String? organizerPhotoUrl,
    String? eventPhotoUrl,
    int? maxGuests,
    int? currentGuests,
    bool? isPublic,
    bool? allowGreetings,
    String? invitationLink,
    String? qrCode,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GuestEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      organizerPhotoUrl: organizerPhotoUrl ?? this.organizerPhotoUrl,
      eventPhotoUrl: eventPhotoUrl ?? this.eventPhotoUrl,
      maxGuests: maxGuests ?? this.maxGuests,
      currentGuests: currentGuests ?? this.currentGuests,
      isPublic: isPublic ?? this.isPublic,
      allowGreetings: allowGreetings ?? this.allowGreetings,
      invitationLink: invitationLink ?? this.invitationLink,
      qrCode: qrCode ?? this.qrCode,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Проверить, есть ли свободные места
  bool get hasAvailableSpots => currentGuests < maxGuests;

  /// Получить количество свободных мест
  int get availableSpots => maxGuests - currentGuests;

  /// Проверить, является ли событие сегодняшним
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(startTime.year, startTime.month, startTime.day);
    return today == eventDate;
  }

  /// Проверить, является ли событие завтрашним
  bool get isTomorrow {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final eventDate = DateTime(startTime.year, startTime.month, startTime.day);
    return tomorrow == eventDate;
  }

  /// Проверить, является ли событие прошедшим
  bool get isPast => endTime.isBefore(DateTime.now());

  /// Проверить, является ли событие текущим
  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Проверить, является ли событие будущим
  bool get isFuture => startTime.isAfter(DateTime.now());
}

/// Фильтр для гостей
class GuestFilter {
  final List<GuestStatus>? statuses;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? hasGreetings;
  final bool? isCheckedIn;
  final bool? isCheckedOut;

  const GuestFilter({
    this.statuses,
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.hasGreetings,
    this.isCheckedIn,
    this.isCheckedOut,
  });

  GuestFilter copyWith({
    List<GuestStatus>? statuses,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    bool? hasGreetings,
    bool? isCheckedIn,
    bool? isCheckedOut,
  }) {
    return GuestFilter(
      statuses: statuses ?? this.statuses,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      hasGreetings: hasGreetings ?? this.hasGreetings,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      isCheckedOut: isCheckedOut ?? this.isCheckedOut,
    );
  }
}

/// Статистика гостей
class GuestStats {
  final int totalGuests;
  final int invitedGuests;
  final int registeredGuests;
  final int confirmedGuests;
  final int checkedInGuests;
  final int checkedOutGuests;
  final int cancelledGuests;
  final int totalGreetings;
  final double attendanceRate;
  final double confirmationRate;

  const GuestStats({
    required this.totalGuests,
    required this.invitedGuests,
    required this.registeredGuests,
    required this.confirmedGuests,
    required this.checkedInGuests,
    required this.checkedOutGuests,
    required this.cancelledGuests,
    required this.totalGreetings,
    required this.attendanceRate,
    required this.confirmationRate,
  });

  factory GuestStats.empty() {
    return const GuestStats(
      totalGuests: 0,
      invitedGuests: 0,
      registeredGuests: 0,
      confirmedGuests: 0,
      checkedInGuests: 0,
      checkedOutGuests: 0,
      cancelledGuests: 0,
      totalGreetings: 0,
      attendanceRate: 0.0,
      confirmationRate: 0.0,
    );
  }
}
