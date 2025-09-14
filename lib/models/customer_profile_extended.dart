import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_profile.dart';

/// Расширенная модель профиля заказчика
class CustomerProfileExtended extends CustomerProfile {
  final List<InspirationPhoto> inspirationPhotos;
  final List<CustomerNote> notes;
  final List<String> favoriteSpecialists;
  final List<String> savedEvents;
  final CustomerPreferences preferences;
  final DateTime lastUpdated;

  const CustomerProfileExtended({
    required super.id,
    required super.userId,
    required super.name,
    required super.email,
    required super.phone,
    required super.avatarUrl,
    required super.bio,
    required super.location,
    required super.eventTypes,
    required super.budgetRange,
    required super.preferredDates,
    required super.specialRequirements,
    required super.createdAt,
    this.inspirationPhotos = const [],
    this.notes = const [],
    this.favoriteSpecialists = const [],
    this.savedEvents = const [],
    required this.preferences,
    required this.lastUpdated,
  });

  /// Создаёт расширенный профиль из документа Firestore
  factory CustomerProfileExtended.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CustomerProfileExtended(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      bio: data['bio'] as String?,
      location: data['location'] as String?,
      eventTypes: List<String>.from(data['eventTypes'] as List? ?? []),
      budgetRange: data['budgetRange'] != null 
          ? BudgetRange.fromMap(data['budgetRange'] as Map<String, dynamic>)
          : const BudgetRange(min: 0, max: 100000),
      preferredDates: (data['preferredDates'] as List?)
          ?.map((date) => (date as Timestamp).toDate())
          .toList() ?? [],
      specialRequirements: List<String>.from(data['specialRequirements'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      inspirationPhotos: (data['inspirationPhotos'] as List?)
          ?.map((photo) => InspirationPhoto.fromMap(photo as Map<String, dynamic>))
          .toList() ?? [],
      notes: (data['notes'] as List?)
          ?.map((note) => CustomerNote.fromMap(note as Map<String, dynamic>))
          .toList() ?? [],
      favoriteSpecialists: List<String>.from(data['favoriteSpecialists'] as List? ?? []),
      savedEvents: List<String>.from(data['savedEvents'] as List? ?? []),
      preferences: data['preferences'] != null
          ? CustomerPreferences.fromMap(data['preferences'] as Map<String, dynamic>)
          : const CustomerPreferences(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  /// Преобразует расширенный профиль в Map для Firestore
  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    baseMap.addAll({
      'inspirationPhotos': inspirationPhotos.map((photo) => photo.toMap()).toList(),
      'notes': notes.map((note) => note.toMap()).toList(),
      'favoriteSpecialists': favoriteSpecialists,
      'savedEvents': savedEvents,
      'preferences': preferences.toMap(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    });
    return baseMap;
  }

  /// Создаёт копию расширенного профиля с обновлёнными полями
  CustomerProfileExtended copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? location,
    List<String>? eventTypes,
    BudgetRange? budgetRange,
    List<DateTime>? preferredDates,
    List<String>? specialRequirements,
    DateTime? createdAt,
    List<InspirationPhoto>? inspirationPhotos,
    List<CustomerNote>? notes,
    List<String>? favoriteSpecialists,
    List<String>? savedEvents,
    CustomerPreferences? preferences,
    DateTime? lastUpdated,
  }) {
    return CustomerProfileExtended(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      eventTypes: eventTypes ?? this.eventTypes,
      budgetRange: budgetRange ?? this.budgetRange,
      preferredDates: preferredDates ?? this.preferredDates,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      createdAt: createdAt ?? this.createdAt,
      inspirationPhotos: inspirationPhotos ?? this.inspirationPhotos,
      notes: notes ?? this.notes,
      favoriteSpecialists: favoriteSpecialists ?? this.favoriteSpecialists,
      savedEvents: savedEvents ?? this.savedEvents,
      preferences: preferences ?? this.preferences,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Фото для вдохновения
class InspirationPhoto {
  final String id;
  final String url;
  final String? caption;
  final List<String> tags;
  final DateTime uploadedAt;
  final bool isPublic;

  const InspirationPhoto({
    required this.id,
    required this.url,
    this.caption,
    this.tags = const [],
    required this.uploadedAt,
    this.isPublic = false,
  });

  /// Создаёт фото из Map
  factory InspirationPhoto.fromMap(Map<String, dynamic> map) {
    return InspirationPhoto(
      id: map['id'] as String,
      url: map['url'] as String,
      caption: map['caption'] as String?,
      tags: List<String>.from(map['tags'] as List? ?? []),
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      isPublic: map['isPublic'] as bool? ?? false,
    );
  }

  /// Преобразует фото в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'caption': caption,
      'tags': tags,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'isPublic': isPublic,
    };
  }

  /// Создаёт копию фото с обновлёнными полями
  InspirationPhoto copyWith({
    String? id,
    String? url,
    String? caption,
    List<String>? tags,
    DateTime? uploadedAt,
    bool? isPublic,
  }) {
    return InspirationPhoto(
      id: id ?? this.id,
      url: url ?? this.url,
      caption: caption ?? this.caption,
      tags: tags ?? this.tags,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

/// Заметка заказчика
class CustomerNote {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final String? eventId;
  final String? specialistId;

  const CustomerNote({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.eventId,
    this.specialistId,
  });

  /// Создаёт заметку из Map
  factory CustomerNote.fromMap(Map<String, dynamic> map) {
    return CustomerNote(
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
  }

  /// Преобразует заметку в Map
  Map<String, dynamic> toMap() {
    return {
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
  }

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
  }) {
    return CustomerNote(
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
}

/// Предпочтения заказчика
class CustomerPreferences {
  final List<String> preferredCategories;
  final List<String> preferredLocations;
  final TimeOfDay? preferredTimeStart;
  final TimeOfDay? preferredTimeEnd;
  final List<String> preferredDays;
  final bool allowNotifications;
  final bool allowMarketing;
  final String language;
  final String theme;

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
  factory CustomerPreferences.fromMap(Map<String, dynamic> map) {
    return CustomerPreferences(
      preferredCategories: List<String>.from(map['preferredCategories'] as List? ?? []),
      preferredLocations: List<String>.from(map['preferredLocations'] as List? ?? []),
      preferredTimeStart: map['preferredTimeStart'] != null
          ? TimeOfDay.fromMap(map['preferredTimeStart'] as Map<String, dynamic>)
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
  }

  /// Преобразует предпочтения в Map
  Map<String, dynamic> toMap() {
    return {
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
  }

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
  }) {
    return CustomerPreferences(
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
}

/// Время дня
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({
    required this.hour,
    required this.minute,
  });

  /// Создаёт время из Map
  factory TimeOfDay.fromMap(Map<String, dynamic> map) {
    return TimeOfDay(
      hour: map['hour'] as int,
      minute: map['minute'] as int,
    );
  }

  /// Преобразует время в Map
  Map<String, dynamic> toMap() {
    return {
      'hour': hour,
      'minute': minute,
    };
  }

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
  List<CustomerNote> get pinnedNotes => notes.where((note) => note.isPinned).toList();

  /// Получает публичные фото
  List<InspirationPhoto> get publicPhotos => inspirationPhotos.where((photo) => photo.isPublic).toList();

  /// Получает заметки по тегу
  List<CustomerNote> getNotesByTag(String tag) {
    return notes.where((note) => note.tags.contains(tag)).toList();
  }

  /// Получает фото по тегу
  List<InspirationPhoto> getPhotosByTag(String tag) {
    return inspirationPhotos.where((photo) => photo.tags.contains(tag)).toList();
  }

  /// Получает все теги из заметок
  Set<String> get allNoteTags {
    return notes.expand((note) => note.tags).toSet();
  }

  /// Получает все теги из фото
  Set<String> get allPhotoTags {
    return inspirationPhotos.expand((photo) => photo.tags).toSet();
  }

  /// Получает все теги
  Set<String> get allTags {
    return {...allNoteTags, ...allPhotoTags};
  }
}
