import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель профиля заказчика
class CustomerProfile {
  CustomerProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.bio,
    this.location,
    this.companyName,
    this.website,
    this.avatarUrl,
    this.contacts = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    // Безопасное преобразование данных
    Map<String, dynamic> safeData;
    if (data is Map<String, dynamic>) {
      safeData = data;
    } else if (data is Map<dynamic, dynamic>) {
      safeData = data.map((key, value) => MapEntry(key.toString(), value));
    } else {
      throw Exception('Document data is not a Map: ${data.runtimeType}');
    }

    return CustomerProfile(
      id: doc.id,
      name: safeData['name'] as String,
      email: safeData['email'] as String,
      phone: safeData['phone'] as String?,
      bio: safeData['bio'] as String?,
      location: safeData['location'] as String?,
      companyName: safeData['companyName'] as String?,
      website: safeData['website'] as String?,
      avatarUrl: safeData['avatarUrl'] as String?,
      contacts: safeData['contacts'] != null
          ? Map<String, String>.from(safeData['contacts'])
          : {},
      createdAt: safeData['createdAt'] != null
          ? (safeData['createdAt'] is Timestamp
              ? (safeData['createdAt'] as Timestamp).toDate()
              : DateTime.parse(safeData['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: safeData['updatedAt'] != null
          ? (safeData['updatedAt'] is Timestamp
              ? (safeData['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(safeData['updatedAt'].toString()))
          : DateTime.now(),
    );
  }
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? bio;
  final String? location;
  final String? companyName;
  final String? website;
  final String? avatarUrl;
  final Map<String, String> contacts;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'phone': phone,
        'bio': bio,
        'location': location,
        'companyName': companyName,
        'website': website,
        'avatarUrl': avatarUrl,
        'contacts': contacts,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  CustomerProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? location,
    String? companyName,
    String? website,
    String? avatarUrl,
    Map<String, String>? contacts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CustomerProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        bio: bio ?? this.bio,
        location: location ?? this.location,
        companyName: companyName ?? this.companyName,
        website: website ?? this.website,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        contacts: contacts ?? this.contacts,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Форма для редактирования профиля заказчика
class CustomerProfileForm {
  CustomerProfileForm({
    required this.name,
    required this.email,
    this.phone,
    this.bio,
    this.location,
    this.companyName,
    this.website,
    this.avatarUrl,
    this.contacts = const {},
  });

  factory CustomerProfileForm.fromProfile(CustomerProfile profile) =>
      CustomerProfileForm(
        name: profile.name,
        email: profile.email,
        phone: profile.phone,
        bio: profile.bio,
        location: profile.location,
        companyName: profile.companyName,
        website: profile.website,
        avatarUrl: profile.avatarUrl,
        contacts: profile.contacts,
      );
  final String name;
  final String email;
  final String? phone;
  final String? bio;
  final String? location;
  final String? companyName;
  final String? website;
  final String? avatarUrl;
  final Map<String, String> contacts;

  CustomerProfile toProfile(String id) => CustomerProfile(
        id: id,
        name: name,
        email: email,
        phone: phone,
        bio: bio,
        location: location,
        companyName: companyName,
        website: website,
        avatarUrl: avatarUrl,
        contacts: contacts,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  CustomerProfileForm copyWith({
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? location,
    String? companyName,
    String? website,
    String? avatarUrl,
    Map<String, String>? contacts,
  }) =>
      CustomerProfileForm(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        bio: bio ?? this.bio,
        location: location ?? this.location,
        companyName: companyName ?? this.companyName,
        website: website ?? this.website,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        contacts: contacts ?? this.contacts,
      );
}
