import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель организатора мероприятий
class EventOrganizer {
  const EventOrganizer({
    required this.id,
    required this.userId,
    required this.companyName,
    this.description,
    this.website,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.region,
    required this.eventTypes,
    required this.specializations,
    this.rating,
    required this.totalEvents,
    required this.completedEvents,
    required this.createdAt,
    required this.updatedAt,
    required this.isVerified,
    required this.isActive,
    this.socialLinks,
    this.portfolioImages,
    this.businessHours,
    this.licenseNumber,
    this.taxId,
  });

  factory EventOrganizer.fromMap(Map<String, dynamic> map) => EventOrganizer(
    id: map['id'] as String,
    userId: map['userId'] as String,
    companyName: map['companyName'] as String,
    description: map['description'] as String?,
    website: map['website'] as String?,
    phone: map['phone'] as String?,
    email: map['email'] as String?,
    address: map['address'] as String?,
    city: map['city'] as String?,
    region: map['region'] as String?,
    eventTypes: List<String>.from(map['eventTypes'] ?? []),
    specializations: List<String>.from(map['specializations'] ?? []),
    rating: (map['rating'] as num?)?.toDouble(),
    totalEvents: map['totalEvents'] as int? ?? 0,
    completedEvents: map['completedEvents'] as int? ?? 0,
    createdAt: _parseTimestamp(map['createdAt']),
    updatedAt: _parseTimestamp(map['updatedAt']),
    isVerified: map['isVerified'] as bool? ?? false,
    isActive: map['isActive'] as bool? ?? true,
    socialLinks: map['socialLinks'] as Map<String, dynamic>?,
    portfolioImages: List<String>.from(map['portfolioImages'] ?? []),
    businessHours: map['businessHours'] as Map<String, dynamic>?,
    licenseNumber: map['licenseNumber'] as String?,
    taxId: map['taxId'] as String?,
  );

  factory EventOrganizer.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return EventOrganizer.fromMap({...data, 'id': doc.id});
  }
  final String id;
  final String userId;
  final String companyName;
  final String? description;
  final String? website;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? region;
  final List<String> eventTypes;
  final List<String> specializations;
  final double? rating;
  final int totalEvents;
  final int completedEvents;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final bool isActive;
  final Map<String, dynamic>? socialLinks;
  final List<String>? portfolioImages;
  final Map<String, dynamic>? businessHours;
  final String? licenseNumber;
  final String? taxId;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'companyName': companyName,
    if (description != null) 'description': description,
    if (website != null) 'website': website,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (address != null) 'address': address,
    if (city != null) 'city': city,
    if (region != null) 'region': region,
    'eventTypes': eventTypes,
    'specializations': specializations,
    if (rating != null) 'rating': rating,
    'totalEvents': totalEvents,
    'completedEvents': completedEvents,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'isVerified': isVerified,
    'isActive': isActive,
    if (socialLinks != null) 'socialLinks': socialLinks,
    if (portfolioImages != null) 'portfolioImages': portfolioImages,
    if (businessHours != null) 'businessHours': businessHours,
    if (licenseNumber != null) 'licenseNumber': licenseNumber,
    if (taxId != null) 'taxId': taxId,
  };

  EventOrganizer copyWith({
    String? id,
    String? userId,
    String? companyName,
    String? description,
    String? website,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? region,
    List<String>? eventTypes,
    List<String>? specializations,
    double? rating,
    int? totalEvents,
    int? completedEvents,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isActive,
    Map<String, dynamic>? socialLinks,
    List<String>? portfolioImages,
    Map<String, dynamic>? businessHours,
    String? licenseNumber,
    String? taxId,
  }) => EventOrganizer(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    companyName: companyName ?? this.companyName,
    description: description ?? this.description,
    website: website ?? this.website,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    city: city ?? this.city,
    region: region ?? this.region,
    eventTypes: eventTypes ?? this.eventTypes,
    specializations: specializations ?? this.specializations,
    rating: rating ?? this.rating,
    totalEvents: totalEvents ?? this.totalEvents,
    completedEvents: completedEvents ?? this.completedEvents,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isVerified: isVerified ?? this.isVerified,
    isActive: isActive ?? this.isActive,
    socialLinks: socialLinks ?? this.socialLinks,
    portfolioImages: portfolioImages ?? this.portfolioImages,
    businessHours: businessHours ?? this.businessHours,
    licenseNumber: licenseNumber ?? this.licenseNumber,
    taxId: taxId ?? this.taxId,
  );

  static DateTime _parseTimestamp(timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (timestamp is String) return DateTime.parse(timestamp);
    return DateTime.now();
  }

  @override
  String toString() =>
      'EventOrganizer(id: $id, companyName: $companyName, eventTypes: $eventTypes)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventOrganizer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Типы мероприятий
enum EventType {
  wedding('Свадьба'),
  corporate('Корпоратив'),
  birthday('День рождения'),
  conference('Конференция'),
  exhibition('Выставка'),
  concert('Концерт'),
  festival('Фестиваль'),
  party('Вечеринка'),
  seminar('Семинар'),
  training('Тренинг'),
  other('Другое');

  const EventType(this.displayName);
  final String displayName;
}

/// Специализации организатора
enum OrganizerSpecialization {
  planning('Планирование'),
  decoration('Оформление'),
  catering('Кейтеринг'),
  entertainment('Развлечения'),
  photography('Фотография'),
  videography('Видеосъемка'),
  music('Музыка'),
  flowers('Цветы'),
  transport('Транспорт'),
  security('Безопасность'),
  technical('Техническое обеспечение'),
  marketing('Маркетинг'),
  other('Другое');

  const OrganizerSpecialization(this.displayName);
  final String displayName;
}
