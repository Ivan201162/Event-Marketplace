import 'package:cloud_firestore/cloud_firestore.dart';

import 'customer.dart';
import 'user.dart';

/// Расширенная модель профиля заказчика с портфолио
class CustomerPortfolio {
  const CustomerPortfolio({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phoneNumber,
    this.maritalStatus = MaritalStatus.single,
    this.weddingDate,
    this.partnerName,
    this.favoriteSpecialists = const [],
    this.anniversaries = const [],
    this.notes,
    this.anniversaryRemindersEnabled = false,
    required this.createdAt,
    this.lastLoginAt,
    this.additionalData,
  });

  /// Создать из документа Firestore
  factory CustomerPortfolio.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return CustomerPortfolio.fromMap(data, doc.id);
  }

  /// Создать из Map
  factory CustomerPortfolio.fromMap(Map<String, dynamic> data, [String? id]) =>
      CustomerPortfolio(
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
        anniversaries: (data['anniversaries'] as List<dynamic>?)
                ?.map((e) =>
                    e is Timestamp ? e.toDate() : DateTime.parse(e.toString()))
                .toList() ??
            [],
        notes: data['notes'],
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

  /// Создать из Customer
  factory CustomerPortfolio.fromCustomer(Customer customer) =>
      CustomerPortfolio(
        id: customer.id,
        name: customer.name,
        email: customer.email,
        avatarUrl: customer.avatarUrl,
        phoneNumber: customer.phoneNumber,
        maritalStatus: customer.maritalStatus,
        weddingDate: customer.weddingDate,
        partnerName: customer.partnerName,
        favoriteSpecialists: customer.favoriteSpecialists,
        anniversaries:
            customer.weddingDate != null ? [customer.weddingDate!] : [],
        anniversaryRemindersEnabled: customer.anniversaryRemindersEnabled,
        createdAt: customer.createdAt,
        lastLoginAt: customer.lastLoginAt,
        additionalData: customer.additionalData,
      );
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? phoneNumber;
  final MaritalStatus maritalStatus;
  final DateTime? weddingDate;
  final String? partnerName;
  final List<String> favoriteSpecialists;
  final List<DateTime> anniversaries;
  final String? notes;
  final bool anniversaryRemindersEnabled;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? additionalData;

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
        'anniversaries': anniversaries.map(Timestamp.fromDate).toList(),
        'notes': notes,
        'anniversaryRemindersEnabled': anniversaryRemindersEnabled,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLoginAt':
            lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
        'additionalData': additionalData,
      };

  /// Копировать с изменениями
  CustomerPortfolio copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? phoneNumber,
    MaritalStatus? maritalStatus,
    DateTime? weddingDate,
    String? partnerName,
    List<String>? favoriteSpecialists,
    List<DateTime>? anniversaries,
    String? notes,
    bool? anniversaryRemindersEnabled,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? additionalData,
  }) =>
      CustomerPortfolio(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        weddingDate: weddingDate ?? this.weddingDate,
        partnerName: partnerName ?? this.partnerName,
        favoriteSpecialists: favoriteSpecialists ?? this.favoriteSpecialists,
        anniversaries: anniversaries ?? this.anniversaries,
        notes: notes ?? this.notes,
        anniversaryRemindersEnabled:
            anniversaryRemindersEnabled ?? this.anniversaryRemindersEnabled,
        createdAt: createdAt ?? this.createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        additionalData: additionalData ?? this.additionalData,
      );

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

  /// Добавить годовщину
  CustomerPortfolio addAnniversary(DateTime anniversary) {
    final newAnniversaries = List<DateTime>.from(anniversaries);
    if (!newAnniversaries.any(
      (date) => date.month == anniversary.month && date.day == anniversary.day,
    )) {
      newAnniversaries.add(anniversary);
    }
    return copyWith(anniversaries: newAnniversaries);
  }

  /// Удалить годовщину
  CustomerPortfolio removeAnniversary(DateTime anniversary) {
    final newAnniversaries = anniversaries
        .where((date) =>
            !(date.month == anniversary.month && date.day == anniversary.day))
        .toList();
    return copyWith(anniversaries: newAnniversaries);
  }

  /// Добавить специалиста в избранное
  CustomerPortfolio addFavoriteSpecialist(String specialistId) {
    if (favoriteSpecialists.contains(specialistId)) return this;
    final newFavorites = List<String>.from(favoriteSpecialists)
      ..add(specialistId);
    return copyWith(favoriteSpecialists: newFavorites);
  }

  /// Удалить специалиста из избранного
  CustomerPortfolio removeFavoriteSpecialist(String specialistId) {
    final newFavorites =
        favoriteSpecialists.where((id) => id != specialistId).toList();
    return copyWith(favoriteSpecialists: newFavorites);
  }

  /// Получить ближайшие годовщины (в течение следующих 30 дней)
  List<DateTime> get upcomingAnniversaries {
    final now = DateTime.now();
    final upcoming = <DateTime>[];

    for (final anniversary in anniversaries) {
      final thisYear = DateTime(now.year, anniversary.month, anniversary.day);
      final nextYear =
          DateTime(now.year + 1, anniversary.month, anniversary.day);

      if (thisYear.isAfter(now) && thisYear.difference(now).inDays <= 30) {
        upcoming.add(thisYear);
      } else if (nextYear.difference(now).inDays <= 30) {
        upcoming.add(nextYear);
      }
    }

    upcoming.sort();
    return upcoming;
  }

  /// Получить годовщины сегодня
  List<DateTime> get todayAnniversaries {
    final now = DateTime.now();
    return anniversaries
        .where((anniversary) =>
            anniversary.month == now.month && anniversary.day == now.day)
        .toList();
  }

  /// Получить статистику портфолио
  Map<String, dynamic> get portfolioStats => {
        'favoriteSpecialistsCount': favoriteSpecialists.length,
        'anniversariesCount': anniversaries.length,
        'upcomingAnniversariesCount': upcomingAnniversaries.length,
        'todayAnniversariesCount': todayAnniversaries.length,
        'yearsMarried': yearsMarried,
        'hasNotes': notes != null && notes!.isNotEmpty,
        'anniversaryRemindersEnabled': anniversaryRemindersEnabled,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerPortfolio && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CustomerPortfolio(id: $id, name: $name, email: $email)';
}
