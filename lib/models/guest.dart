import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель гостя мероприятия
class Guest {
  const Guest({
    required this.id,
    required this.eventId,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Создать из Map
  factory Guest.fromMap(Map<String, dynamic> data) => Guest(
        id: data['id'] as String? ?? '',
        eventId: data['eventId'] as String? ?? '',
        name: data['name'] as String? ?? '',
        email: data['email'] as String?,
        phone: data['phone'] as String?,
        avatar: data['avatar'] as String?,
        status: GuestStatus.values.firstWhere(
          (e) => e.name == data['status'] as String?,
          orElse: () => GuestStatus.invited,
        ),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        metadata: Map<String, dynamic>.from(
          (data['metadata'] as Map<dynamic, dynamic>?) ?? {},
        ),
      );
  final String id;
  final String eventId;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final GuestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'eventId': eventId,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar': avatar,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'metadata': metadata,
      };

  /// Геттеры для совместимости с виджетами
  String get guestName => name;
  String? get guestEmail => email;
  String? get guestPhone => phone;
  String? get guestPhotoUrl => avatar;
  int get greetingsCount => metadata['greetingsCount'] as int? ?? 0;
  DateTime? get registeredAt => metadata['registeredAt'] != null
      ? DateTime.parse(metadata['registeredAt'] as String)
      : null;
  DateTime? get confirmedAt => metadata['confirmedAt'] != null
      ? DateTime.parse(metadata['confirmedAt'] as String)
      : null;
  DateTime? get checkedInAt => metadata['checkedInAt'] != null
      ? DateTime.parse(metadata['checkedInAt'] as String)
      : null;
  DateTime? get checkedOutAt => metadata['checkedOutAt'] != null
      ? DateTime.parse(metadata['checkedOutAt'] as String)
      : null;

  /// Цвет статуса
  String get statusColor {
    switch (status) {
      case GuestStatus.invited:
        return 'blue';
      case GuestStatus.confirmed:
        return 'green';
      case GuestStatus.declined:
        return 'red';
      case GuestStatus.attended:
        return 'green';
      case GuestStatus.noShow:
        return 'orange';
      case GuestStatus.registered:
        return 'purple';
      case GuestStatus.checkedIn:
        return 'green';
      case GuestStatus.cancelled:
        return 'red';
    }
  }

  /// Текст статуса
  String get statusText => status.displayName;

  /// Копировать с изменениями
  Guest copyWith({
    String? id,
    String? eventId,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    GuestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) =>
      Guest(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        avatar: avatar ?? this.avatar,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: metadata ?? this.metadata,
      );
}

/// Статус гостя
enum GuestStatus {
  invited,
  confirmed,
  declined,
  attended,
  noShow,
  registered,
  checkedIn,
  cancelled;

  String get displayName {
    switch (this) {
      case GuestStatus.invited:
        return 'Приглашен';
      case GuestStatus.confirmed:
        return 'Подтвердил';
      case GuestStatus.declined:
        return 'Отклонил';
      case GuestStatus.attended:
        return 'Присутствовал';
      case GuestStatus.noShow:
        return 'Не пришел';
      case GuestStatus.registered:
        return 'Зарегистрирован';
      case GuestStatus.checkedIn:
        return 'Зарегистрирован на месте';
      case GuestStatus.cancelled:
        return 'Отменен';
    }
  }
}

/// Модель гостевого приветствия
class GuestGreeting {
  const GuestGreeting({
    required this.id,
    required this.eventId,
    required this.guestId,
    required this.guestName,
    this.guestAvatar,
    required this.type,
    this.text,
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    required this.createdAt,
    required this.likedBy,
    required this.likesCount,
    required this.isPublic,
  });

  /// Создать из Map
  factory GuestGreeting.fromMap(Map<String, dynamic> data) => GuestGreeting(
        id: data['id'] as String? ?? '',
        eventId: data['eventId'] as String? ?? '',
        guestId: data['guestId'] as String? ?? '',
        guestName: data['guestName'] as String? ?? '',
        guestAvatar: data['guestAvatar'] as String?,
        type: GreetingType.values.firstWhere(
          (e) => e.name == data['type'] as String?,
          orElse: () => GreetingType.text,
        ),
        text: data['text'] as String?,
        imageUrl: data['imageUrl'] as String?,
        videoUrl: data['videoUrl'] as String?,
        audioUrl: data['audioUrl'] as String?,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        likedBy: List<String>.from((data['likedBy'] as List<dynamic>?) ?? []),
        likesCount: data['likesCount'] as int? ?? 0,
        isPublic: data['isPublic'] as bool? ?? true,
      );
  final String id;
  final String eventId;
  final String guestId;
  final String guestName;
  final String? guestAvatar;
  final GreetingType type;
  final String? text;
  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl;
  final DateTime createdAt;
  final List<String> likedBy;
  final int likesCount;
  final bool isPublic;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'eventId': eventId,
        'guestId': guestId,
        'guestName': guestName,
        'guestAvatar': guestAvatar,
        'type': type.name,
        'text': text,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'audioUrl': audioUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'likedBy': likedBy,
        'likesCount': likesCount,
        'isPublic': isPublic,
      };

  /// Копировать с изменениями
  GuestGreeting copyWith({
    String? id,
    String? eventId,
    String? guestId,
    String? guestName,
    String? guestAvatar,
    GreetingType? type,
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    DateTime? createdAt,
    List<String>? likedBy,
    int? likesCount,
    bool? isPublic,
  }) =>
      GuestGreeting(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        guestId: guestId ?? this.guestId,
        guestName: guestName ?? this.guestName,
        guestAvatar: guestAvatar ?? this.guestAvatar,
        type: type ?? this.type,
        text: text ?? this.text,
        imageUrl: imageUrl ?? this.imageUrl,
        videoUrl: videoUrl ?? this.videoUrl,
        audioUrl: audioUrl ?? this.audioUrl,
        createdAt: createdAt ?? this.createdAt,
        likedBy: likedBy ?? this.likedBy,
        likesCount: likesCount ?? this.likesCount,
        isPublic: isPublic ?? this.isPublic,
      );
}

/// Тип приветствия
enum GreetingType {
  text,
  image,
  video,
  audio;

  String get displayName {
    switch (this) {
      case GreetingType.text:
        return 'Текст';
      case GreetingType.image:
        return 'Фото';
      case GreetingType.video:
        return 'Видео';
      case GreetingType.audio:
        return 'Аудио';
    }
  }
}

/// Модель гостевого доступа к событию
class GuestEventAccess {
  const GuestEventAccess({
    required this.id,
    required this.eventId,
    required this.accessCode,
    required this.qrCode,
    required this.expiresAt,
    required this.isActive,
    required this.maxUses,
    required this.currentUses,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из Map
  factory GuestEventAccess.fromMap(Map<String, dynamic> data) =>
      GuestEventAccess(
        id: data['id'] as String? ?? '',
        eventId: data['eventId'] as String? ?? '',
        accessCode: data['accessCode'] as String? ?? '',
        qrCode: data['qrCode'] as String? ?? '',
        expiresAt: (data['expiresAt'] as Timestamp).toDate(),
        isActive: data['isActive'] as bool? ?? true,
        maxUses: data['maxUses'] as int? ?? 1,
        currentUses: data['currentUses'] as int? ?? 0,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
  final String id;
  final String eventId;
  final String accessCode;
  final String qrCode;
  final DateTime expiresAt;
  final bool isActive;
  final int maxUses;
  final int currentUses;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'eventId': eventId,
        'accessCode': accessCode,
        'qrCode': qrCode,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'isActive': isActive,
        'maxUses': maxUses,
        'currentUses': currentUses,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Копировать с изменениями
  GuestEventAccess copyWith({
    String? id,
    String? eventId,
    String? accessCode,
    String? qrCode,
    DateTime? expiresAt,
    bool? isActive,
    int? maxUses,
    int? currentUses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      GuestEventAccess(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        accessCode: accessCode ?? this.accessCode,
        qrCode: qrCode ?? this.qrCode,
        expiresAt: expiresAt ?? this.expiresAt,
        isActive: isActive ?? this.isActive,
        maxUses: maxUses ?? this.maxUses,
        currentUses: currentUses ?? this.currentUses,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
