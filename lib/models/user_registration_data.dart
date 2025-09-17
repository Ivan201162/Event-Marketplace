import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип пользователя
enum UserType {
  customer, // Клиент
  specialist, // Специалист
  individualEntrepreneur, // ИП
  selfEmployed, // Самозанятый
  organization, // Организация
}

/// Тип документа
enum DocumentType {
  passport, // Паспорт
  driverLicense, // Водительские права
  internationalPassport, // Загранпаспорт
  militaryId, // Военный билет
  birthCertificate, // Свидетельство о рождении
}

/// Данные для регистрации пользователя
class UserRegistrationData {
  final String? id;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String phoneNumber;
  final DateTime birthDate;
  final UserType userType;
  final String? profileImageUrl;
  final bool agreeToTerms;
  final bool agreeToPrivacy;
  final bool agreeToMarketing;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Дополнительные поля для специалистов
  final String? businessName;
  final String? inn; // ИНН
  final String? ogrn; // ОГРН
  final String? kpp; // КПП
  final String? legalAddress;
  final String? actualAddress;
  final String? bankName;
  final String? bankAccount;
  final String? correspondentAccount;
  final String? bik;

  // Документы
  final List<DocumentData> documents;
  final List<String> specializations;
  final String? bio;
  final List<String> portfolioImages;
  final List<String> portfolioVideos;
  final double? rating;
  final int? completedBookings;
  final bool isVerified;
  final bool isActive;

  const UserRegistrationData({
    this.id,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.phoneNumber,
    required this.birthDate,
    required this.userType,
    this.profileImageUrl,
    required this.agreeToTerms,
    required this.agreeToPrivacy,
    this.agreeToMarketing = false,
    required this.createdAt,
    required this.updatedAt,
    this.businessName,
    this.inn,
    this.ogrn,
    this.kpp,
    this.legalAddress,
    this.actualAddress,
    this.bankName,
    this.bankAccount,
    this.correspondentAccount,
    this.bik,
    this.documents = const [],
    this.specializations = const [],
    this.bio,
    this.portfolioImages = const [],
    this.portfolioVideos = const [],
    this.rating,
    this.completedBookings,
    this.isVerified = false,
    this.isActive = true,
  });

  /// Создать из документа Firestore
  factory UserRegistrationData.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserRegistrationData(
      id: doc.id,
      email: data['email'] ?? '',
      password: '', // Пароль не сохраняется в Firestore
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      middleName: data['middleName'] as String?,
      phoneNumber: data['phoneNumber'] ?? '',
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      userType: UserType.values.firstWhere(
        (e) => e.name == data['userType'],
        orElse: () => UserType.customer,
      ),
      profileImageUrl: data['profileImageUrl'] as String?,
      agreeToTerms: data['agreeToTerms'] ?? false,
      agreeToPrivacy: data['agreeToPrivacy'] ?? false,
      agreeToMarketing: data['agreeToMarketing'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      businessName: data['businessName'] as String?,
      inn: data['inn'] as String?,
      ogrn: data['ogrn'] as String?,
      kpp: data['kpp'] as String?,
      legalAddress: data['legalAddress'] as String?,
      actualAddress: data['actualAddress'] as String?,
      bankName: data['bankName'] as String?,
      bankAccount: data['bankAccount'] as String?,
      correspondentAccount: data['correspondentAccount'] as String?,
      bik: data['bik'] as String?,
      documents: (data['documents'] as List<dynamic>?)
              ?.map((doc) => DocumentData.fromMap(doc))
              .toList() ??
          [],
      specializations: List<String>.from(data['specializations'] ?? []),
      bio: data['bio'] as String?,
      portfolioImages: List<String>.from(data['portfolioImages'] ?? []),
      portfolioVideos: List<String>.from(data['portfolioVideos'] ?? []),
      rating: (data['rating'] as num?)?.toDouble(),
      completedBookings: data['completedBookings'] as int?,
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'phoneNumber': phoneNumber,
      'birthDate': Timestamp.fromDate(birthDate),
      'userType': userType.name,
      'profileImageUrl': profileImageUrl,
      'agreeToTerms': agreeToTerms,
      'agreeToPrivacy': agreeToPrivacy,
      'agreeToMarketing': agreeToMarketing,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'businessName': businessName,
      'inn': inn,
      'ogrn': ogrn,
      'kpp': kpp,
      'legalAddress': legalAddress,
      'actualAddress': actualAddress,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'correspondentAccount': correspondentAccount,
      'bik': bik,
      'documents': documents.map((doc) => doc.toMap()).toList(),
      'specializations': specializations,
      'bio': bio,
      'portfolioImages': portfolioImages,
      'portfolioVideos': portfolioVideos,
      'rating': rating,
      'completedBookings': completedBookings,
      'isVerified': isVerified,
      'isActive': isActive,
    };
  }

  /// Создать копию с обновлёнными полями
  UserRegistrationData copyWith({
    String? id,
    String? email,
    String? password,
    String? firstName,
    String? lastName,
    String? middleName,
    String? phoneNumber,
    DateTime? birthDate,
    UserType? userType,
    String? profileImageUrl,
    bool? agreeToTerms,
    bool? agreeToPrivacy,
    bool? agreeToMarketing,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? businessName,
    String? inn,
    String? ogrn,
    String? kpp,
    String? legalAddress,
    String? actualAddress,
    String? bankName,
    String? bankAccount,
    String? correspondentAccount,
    String? bik,
    List<DocumentData>? documents,
    List<String>? specializations,
    String? bio,
    List<String>? portfolioImages,
    List<String>? portfolioVideos,
    double? rating,
    int? completedBookings,
    bool? isVerified,
    bool? isActive,
  }) {
    return UserRegistrationData(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      userType: userType ?? this.userType,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      agreeToTerms: agreeToTerms ?? this.agreeToTerms,
      agreeToPrivacy: agreeToPrivacy ?? this.agreeToPrivacy,
      agreeToMarketing: agreeToMarketing ?? this.agreeToMarketing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      businessName: businessName ?? this.businessName,
      inn: inn ?? this.inn,
      ogrn: ogrn ?? this.ogrn,
      kpp: kpp ?? this.kpp,
      legalAddress: legalAddress ?? this.legalAddress,
      actualAddress: actualAddress ?? this.actualAddress,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      correspondentAccount: correspondentAccount ?? this.correspondentAccount,
      bik: bik ?? this.bik,
      documents: documents ?? this.documents,
      specializations: specializations ?? this.specializations,
      bio: bio ?? this.bio,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      portfolioVideos: portfolioVideos ?? this.portfolioVideos,
      rating: rating ?? this.rating,
      completedBookings: completedBookings ?? this.completedBookings,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Получить полное имя
  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$lastName $firstName $middleName';
    }
    return '$lastName $firstName';
  }

  /// Получить короткое имя
  String get shortName {
    return '$firstName ${lastName[0]}.';
  }

  /// Проверить, является ли пользователь специалистом
  bool get isSpecialist {
    return userType == UserType.specialist ||
        userType == UserType.individualEntrepreneur ||
        userType == UserType.selfEmployed ||
        userType == UserType.organization;
  }

  /// Проверить, является ли пользователь ИП или самозанятым
  bool get isBusinessEntity {
    return userType == UserType.individualEntrepreneur ||
        userType == UserType.selfEmployed ||
        userType == UserType.organization;
  }

  /// Получить описание типа пользователя
  String get userTypeDescription {
    switch (userType) {
      case UserType.customer:
        return 'Клиент';
      case UserType.specialist:
        return 'Специалист';
      case UserType.individualEntrepreneur:
        return 'Индивидуальный предприниматель';
      case UserType.selfEmployed:
        return 'Самозанятый';
      case UserType.organization:
        return 'Организация';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRegistrationData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserRegistrationData(id: $id, email: $email, fullName: $fullName, userType: $userType)';
  }
}

/// Данные документа
class DocumentData {
  final String id;
  final DocumentType type;
  final String series;
  final String number;
  final String issuedBy;
  final DateTime issuedDate;
  final String? departmentCode;
  final String? imageUrl;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentData({
    required this.id,
    required this.type,
    required this.series,
    required this.number,
    required this.issuedBy,
    required this.issuedDate,
    this.departmentCode,
    this.imageUrl,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из Map
  factory DocumentData.fromMap(Map<String, dynamic> map) {
    return DocumentData(
      id: map['id'] ?? '',
      type: DocumentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DocumentType.passport,
      ),
      series: map['series'] ?? '',
      number: map['number'] ?? '',
      issuedBy: map['issuedBy'] ?? '',
      issuedDate: (map['issuedDate'] as Timestamp).toDate(),
      departmentCode: map['departmentCode'] as String?,
      imageUrl: map['imageUrl'] as String?,
      isVerified: map['isVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'series': series,
      'number': number,
      'issuedBy': issuedBy,
      'issuedDate': Timestamp.fromDate(issuedDate),
      'departmentCode': departmentCode,
      'imageUrl': imageUrl,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Получить описание типа документа
  String get typeDescription {
    switch (type) {
      case DocumentType.passport:
        return 'Паспорт';
      case DocumentType.driverLicense:
        return 'Водительские права';
      case DocumentType.internationalPassport:
        return 'Загранпаспорт';
      case DocumentType.militaryId:
        return 'Военный билет';
      case DocumentType.birthCertificate:
        return 'Свидетельство о рождении';
    }
  }

  /// Получить полный номер документа
  String get fullNumber {
    if (series.isNotEmpty && number.isNotEmpty) {
      return '$series $number';
    }
    return number;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DocumentData(id: $id, type: $type, fullNumber: $fullNumber)';
  }
}
