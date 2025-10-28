import 'package:cloud_firestore/cloud_firestore.dart';

/// Расширенная модель профиля заказчика
class CustomerProfileExtended {
  const CustomerProfileExtended({
    required this.id,
    required this.userId,
    required this.createdAt, required this.updatedAt, required this.extendedPreferences, required this.lastUpdated, this.name,
    this.photoURL,
    this.avatarUrl,
    this.bio,
    this.phoneNumber,
    this.location,
    this.interests = const [],
    this.eventTypes = const [],
    this.preferences,
    this.inspirationPhotos = const [],
    this.notes = const [],
    this.favoriteSpecialists = const [],
    this.savedEvents = const [],
  });

  /// Создаёт расширенный профиль из документа Firestore
  factory CustomerProfileExtended.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return CustomerProfileExtended(
      id: doc.id,
      userId: data['userId'] as String,
      photoURL: data['photoURL'] as String?,
      bio: data['bio'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      location: data['location'] as String?,
      interests: List<String>.from(data['interests'] as List? ?? []),
      eventTypes: List<String>.from(data['eventTypes'] as List? ?? []),
      preferences: data['preferences'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      inspirationPhotos: (data['inspirationPhotos'] as List?)
              ?.map((photo) =>
                  InspirationPhoto.fromMap(photo as Map<String, dynamic>),)
              .toList() ??
          [],
      notes: (data['notes'] as List?)
              ?.map(
                  (note) => CustomerNote.fromMap(note as Map<String, dynamic>),)
              .toList() ??
          [],
      favoriteSpecialists:
          List<String>.from(data['favoriteSpecialists'] as List? ?? []),
      savedEvents: List<String>.from(data['savedEvents'] as List? ?? []),
      extendedPreferences: data['extendedPreferences'] != null
          ? CustomerPreferences.fromMap(
              data['extendedPreferences'] as Map<String, dynamic>,)
          : const CustomerPreferences(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String userId;
  final String? name;
  final String? photoURL;
  final String? avatarUrl;
  final String? bio;
  final String? phoneNumber;
  final String? location;
  final List<String> interests;
  final List<String> eventTypes;
  final Map<String, dynamic>? preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<InspirationPhoto> inspirationPhotos;
  final List<CustomerNote> notes;
  final List<String> favoriteSpecialists;
  final List<String> savedEvents;
  final CustomerPreferences extendedPreferences;
  final DateTime lastUpdated;

  /// Преобразует расширенный профиль в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'photoURL': photoURL,
        'bio': bio,
        'phoneNumber': phoneNumber,
        'location': location,
        'interests': interests,
        'eventTypes': eventTypes,
        'preferences': preferences,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'inspirationPhotos':
            inspirationPhotos.map((photo) => photo.toMap()).toList(),
        'notes': notes.map((note) => note.toMap()).toList(),
        'favoriteSpecialists': favoriteSpecialists,
        'savedEvents': savedEvents,
        'extendedPreferences': extendedPreferences.toMap(),
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };

  /// Создаёт копию расширенного профиля с обновлёнными полями
  CustomerProfileExtended copyWith({
    String? id,
    String? userId,
    String? photoURL,
    String? bio,
    String? phoneNumber,
    String? location,
    List<String>? interests,
    List<String>? eventTypes,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InspirationPhoto>? inspirationPhotos,
    List<CustomerNote>? notes,
    List<String>? favoriteSpecialists,
    List<String>? savedEvents,
    CustomerPreferences? extendedPreferences,
    DateTime? lastUpdated,
  }) =>
      CustomerProfileExtended(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        photoURL: photoURL ?? this.photoURL,
        bio: bio ?? this.bio,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        location: location ?? this.location,
        interests: interests ?? this.interests,
        eventTypes: eventTypes ?? this.eventTypes,
        preferences: preferences ?? this.preferences,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        inspirationPhotos: inspirationPhotos ?? this.inspirationPhotos,
        notes: notes ?? this.notes,
        favoriteSpecialists: favoriteSpecialists ?? this.favoriteSpecialists,
        savedEvents: savedEvents ?? this.savedEvents,
        extendedPreferences: extendedPreferences ?? this.extendedPreferences,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

/// Фото для вдохновения
class InspirationPhoto {
  const InspirationPhoto({
    required this.id,
    required this.url,
    required this.uploadedAt, this.caption,
    this.tags = const [],
    this.isPublic = false,
  });

  /// Создаёт фото из Map
  factory InspirationPhoto.fromMap(Map<String, dynamic> map) =>
      InspirationPhoto(
        id: map['id'] as String,
        url: map['url'] as String,
        caption: map['caption'] as String?,
        tags: List<String>.from(map['tags'] as List? ?? []),
        uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
        isPublic: map['isPublic'] as bool? ?? false,
      );
  final String id;
  final String url;
  final String? caption;
  final List<String> tags;
  final DateTime uploadedAt;
  final bool isPublic;

  /// Преобразует фото в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'url': url,
        'caption': caption,
        'tags': tags,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'isPublic': isPublic,
      };

  /// Создаёт копию фото с обновлёнными полями
  InspirationPhoto copyWith({
    String? id,
    String? url,
    String? caption,
    List<String>? tags,
    DateTime? uploadedAt,
    bool? isPublic,
  }) =>
      InspirationPhoto(
        id: id ?? this.id,
        url: url ?? this.url,
        caption: caption ?? this.caption,
        tags: tags ?? this.tags,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        isPublic: isPublic ?? this.isPublic,
      );
}

/// Заметка заказчика
class CustomerNote {
  const CustomerNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt, required this.updatedAt, this.tags = const [],
    this.isPinned = false,
    this.eventId,
    this.specialistId,
  });

  /// Создаёт заметку из Map
  factory CustomerNote.fromMap(Map<String, dynamic> map) => CustomerNote(
        id: map['id'] as String,
        title: map['title'] as String,
        content: map['content'] as String,
        tags: List<String>.from(map['tags'] as List? ?? []),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        isPinned: map['isPinned'] as bool? ?? false,
        eventId: map['eventId'] as String?,
        specialistId: map['specialistId'] as String?,
      );
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final String? eventId;
  final String? specialistId;

  /// Преобразует заметку в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'tags': tags,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isPinned': isPinned,
        'eventId': eventId,
        'specialistId': specialistId,
      };

  /// Создаёт копию заметки с обновлёнными полями
  CustomerNote copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    String? eventId,
    String? specialistId,
  }) =>
      CustomerNote(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        tags: tags ?? this.tags,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isPinned: isPinned ?? this.isPinned,
        eventId: eventId ?? this.eventId,
        specialistId: specialistId ?? this.specialistId,
      );
}

/// Предпочтения заказчика
class CustomerPreferences {
  const CustomerPreferences({
    this.preferredCategories = const [],
    this.preferredLocations = const [],
    this.preferredTimeStart,
    this.preferredTimeEnd,
    this.preferredDays = const [],
    this.allowNotifications = true,
    this.allowMarketing = false,
    this.language = 'ru',
    this.theme = 'system',
  });

  /// Создаёт предпочтения из Map
  factory CustomerPreferences.fromMap(Map<String, dynamic> map) =>
      CustomerPreferences(
        preferredCategories:
            List<String>.from(map['preferredCategories'] as List? ?? []),
        preferredLocations:
            List<String>.from(map['preferredLocations'] as List? ?? []),
        preferredTimeStart: map['preferredTimeStart'] != null
            ? TimeOfDay.fromMap(
                map['preferredTimeStart'] as Map<String, dynamic>,)
            : null,
        preferredTimeEnd: map['preferredTimeEnd'] != null
            ? TimeOfDay.fromMap(map['preferredTimeEnd'] as Map<String, dynamic>)
            : null,
        preferredDays: List<String>.from(map['preferredDays'] as List? ?? []),
        allowNotifications: map['allowNotifications'] as bool? ?? true,
        allowMarketing: map['allowMarketing'] as bool? ?? false,
        language: map['language'] as String? ?? 'ru',
        theme: map['theme'] as String? ?? 'system',
      );
  final List<String> preferredCategories;
  final List<String> preferredLocations;
  final TimeOfDay? preferredTimeStart;
  final TimeOfDay? preferredTimeEnd;
  final List<String> preferredDays;
  final bool allowNotifications;
  final bool allowMarketing;
  final String language;
  final String theme;

  /// Преобразует предпочтения в Map
  Map<String, dynamic> toMap() => {
        'preferredCategories': preferredCategories,
        'preferredLocations': preferredLocations,
        'preferredTimeStart': preferredTimeStart?.toMap(),
        'preferredTimeEnd': preferredTimeEnd?.toMap(),
        'preferredDays': preferredDays,
        'allowNotifications': allowNotifications,
        'allowMarketing': allowMarketing,
        'language': language,
        'theme': theme,
      };

  /// Создаёт копию предпочтений с обновлёнными полями
  CustomerPreferences copyWith({
    List<String>? preferredCategories,
    List<String>? preferredLocations,
    TimeOfDay? preferredTimeStart,
    TimeOfDay? preferredTimeEnd,
    List<String>? preferredDays,
    bool? allowNotifications,
    bool? allowMarketing,
    String? language,
    String? theme,
  }) =>
      CustomerPreferences(
        preferredCategories: preferredCategories ?? this.preferredCategories,
        preferredLocations: preferredLocations ?? this.preferredLocations,
        preferredTimeStart: preferredTimeStart ?? this.preferredTimeStart,
        preferredTimeEnd: preferredTimeEnd ?? this.preferredTimeEnd,
        preferredDays: preferredDays ?? this.preferredDays,
        allowNotifications: allowNotifications ?? this.allowNotifications,
        allowMarketing: allowMarketing ?? this.allowMarketing,
        language: language ?? this.language,
        theme: theme ?? this.theme,
      );
}

/// Время дня
class TimeOfDay {
  const TimeOfDay({required this.hour, required this.minute});

  /// Создаёт время из Map
  factory TimeOfDay.fromMap(Map<String, dynamic> map) =>
      TimeOfDay(hour: map['hour'] as int, minute: map['minute'] as int);
  final int hour;
  final int minute;

  /// Преобразует время в Map
  Map<String, dynamic> toMap() => {'hour': hour, 'minute': minute};

  /// Форматирует время для отображения
  String get formatted {
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  @override
  String toString() => formatted;
}

/// Расширения для работы с расширенным профилем
extension CustomerProfileExtendedExtension on CustomerProfileExtended {
  /// Получает закреплённые заметки
  List<CustomerNote> get pinnedNotes =>
      notes.where((note) => note.isPinned).toList();

  /// Получает публичные фото
  List<InspirationPhoto> get publicPhotos =>
      inspirationPhotos.where((photo) => photo.isPublic).toList();

  /// Получает заметки по тегу
  List<CustomerNote> getNotesByTag(String tag) =>
      notes.where((note) => note.tags.contains(tag)).toList();

  /// Получает фото по тегу
  List<InspirationPhoto> getPhotosByTag(String tag) =>
      inspirationPhotos.where((photo) => photo.tags.contains(tag)).toList();

  /// Получает все теги из заметок
  Set<String> get allNoteTags => notes.expand((note) => note.tags).toSet();

  /// Получает все теги из фото
  Set<String> get allPhotoTags =>
      inspirationPhotos.expand((photo) => photo.tags).toSet();

  /// Получает все теги
  Set<String> get allTags => {...allNoteTags, ...allPhotoTags};
}
