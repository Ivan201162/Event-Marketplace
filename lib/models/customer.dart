import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

/// Модель заказчика
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phoneNumber,
    this.maritalStatus = MaritalStatus.single,
    this.weddingDate,
    this.partnerName,
    this.favoriteSpecialists = const [],
    this.ordersHistory = const [],
    this.anniversaries = const [],
    this.anniversaryRemindersEnabled = false,
    required this.createdAt,
    this.lastLoginAt,
    this.additionalData,
  });

  /// Создать заказчика из документа Firestore
  factory Customer.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Customer.fromMap(data, doc.id);
  }

  /// Создать заказчика из Map
  factory Customer.fromMap(Map<String, dynamic> data, [String? id]) => Customer(
        id: id ?? data['id'] ?? '',
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        avatarUrl: data['avatarUrl'],
        phoneNumber: data['phoneNumber'],
        maritalStatus: data['maritalStatus'] != null
            ? MaritalStatus.values.firstWhere(
                (e) => e.name == data['maritalStatus'],
                orElse: () => MaritalStatus.single,
              )
            : MaritalStatus.single,
        weddingDate: data['weddingDate'] != null
            ? (data['weddingDate'] is Timestamp
                ? (data['weddingDate'] as Timestamp).toDate()
                : DateTime.parse(data['weddingDate'].toString()))
            : null,
        partnerName: data['partnerName'],
        favoriteSpecialists:
            List<String>.from(data['favoriteSpecialists'] ?? []),
        ordersHistory: List<String>.from(data['ordersHistory'] ?? []),
        anniversaries: (data['anniversaries'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        anniversaryRemindersEnabled:
            data['anniversaryRemindersEnabled'] as bool? ?? false,
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.parse(data['createdAt'].toString()))
            : DateTime.now(),
        lastLoginAt: data['lastLoginAt'] != null
            ? (data['lastLoginAt'] is Timestamp
                ? (data['lastLoginAt'] as Timestamp).toDate()
                : DateTime.parse(data['lastLoginAt'].toString()))
            : null,
        additionalData: data['additionalData'],
      );

  /// Создать заказчика из AppUser
  factory Customer.fromAppUser(AppUser user) => Customer(
        id: user.id,
        name: user.displayName ?? user.email.split('@').first,
        email: user.email,
        avatarUrl: user.photoURL,
        phoneNumber: user.phoneNumber,
        maritalStatus: user.maritalStatus ?? MaritalStatus.single,
        weddingDate: user.weddingDate,
        partnerName: user.partnerName,
        anniversaryRemindersEnabled: user.anniversaryRemindersEnabled,
        createdAt: user.createdAt,
        lastLoginAt: user.lastLoginAt,
        additionalData: user.additionalData,
      );
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? phoneNumber;
  final MaritalStatus maritalStatus;
  final DateTime? weddingDate;
  final String? partnerName;
  final List<String> favoriteSpecialists; // список ID специалистов
  final List<String> ordersHistory; // история заявок
  final List<Map<String, dynamic>> anniversaries; // годовщины и праздники
  final bool anniversaryRemindersEnabled;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? additionalData;

  /// Получить количество лет в браке
  int? get yearsMarried {
    if (weddingDate == null) return null;
    final now = DateTime.now();
    return now.year - weddingDate!.year;
  }

  /// Получить дату следующей годовщины
  DateTime? get nextAnniversary {
    if (weddingDate == null) return null;
    final now = DateTime.now();
    final thisYear = DateTime(now.year, weddingDate!.month, weddingDate!.day);

    if (thisYear.isAfter(now)) {
      return thisYear;
    } else {
      return DateTime(now.year + 1, weddingDate!.month, weddingDate!.day);
    }
  }

  /// Проверить, является ли сегодня годовщиной
  bool get isAnniversaryToday {
    if (weddingDate == null) return false;
    final now = DateTime.now();
    return now.month == weddingDate!.month && now.day == weddingDate!.day;
  }

  /// Проверить, является ли специалист в избранном
  bool isFavoriteSpecialist(String specialistId) =>
      favoriteSpecialists.contains(specialistId);

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'phoneNumber': phoneNumber,
        'maritalStatus': maritalStatus.name,
        'weddingDate':
            weddingDate != null ? Timestamp.fromDate(weddingDate!) : null,
        'partnerName': partnerName,
        'favoriteSpecialists': favoriteSpecialists,
        'ordersHistory': ordersHistory,
        'anniversaries': anniversaries,
        'anniversaryRemindersEnabled': anniversaryRemindersEnabled,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLoginAt':
            lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
        'additionalData': additionalData,
      };

  /// Копировать с изменениями
  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? phoneNumber,
    MaritalStatus? maritalStatus,
    DateTime? weddingDate,
    String? partnerName,
    List<String>? favoriteSpecialists,
    List<String>? ordersHistory,
    List<Map<String, dynamic>>? anniversaries,
    bool? anniversaryRemindersEnabled,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? additionalData,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        weddingDate: weddingDate ?? this.weddingDate,
        partnerName: partnerName ?? this.partnerName,
        favoriteSpecialists: favoriteSpecialists ?? this.favoriteSpecialists,
        ordersHistory: ordersHistory ?? this.ordersHistory,
        anniversaries: anniversaries ?? this.anniversaries,
        anniversaryRemindersEnabled:
            anniversaryRemindersEnabled ?? this.anniversaryRemindersEnabled,
        createdAt: createdAt ?? this.createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        additionalData: additionalData ?? this.additionalData,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Customer(id: $id, name: $name, email: $email)';
}

// Импорт для AppUser
