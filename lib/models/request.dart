/// Статус заявки
enum RequestStatus {
  open,
  inProgress,
  done,
  canceled,
}

/// Модель заявки
class Request {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String category;
  final String subCategory;
  final String city;
  final double budgetMin;
  final double budgetMax;
  final DateTime dateTime;
  final RequestStatus status;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Request({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.category,
    required this.subCategory,
    required this.city,
    required this.budgetMin,
    required this.budgetMax,
    required this.dateTime,
    required this.status,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Request.fromMap(Map<String, dynamic> map, String id) {
    return Request(
      id: id,
      ownerId: map['ownerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      city: map['city'] ?? '',
      budgetMin: (map['budgetMin'] ?? 0.0).toDouble(),
      budgetMax: (map['budgetMax'] ?? 0.0).toDouble(),
      dateTime:
          DateTime.parse(map['dateTime'] ?? DateTime.now().toIso8601String()),
      status: RequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RequestStatus.open,
      ),
      attachments: List<String>.from(map['attachments'] ?? []),
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'category': category,
      'subCategory': subCategory,
      'city': city,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'dateTime': dateTime.toIso8601String(),
      'status': status.name,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Request copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    String? category,
    String? subCategory,
    String? city,
    double? budgetMin,
    double? budgetMax,
    DateTime? dateTime,
    RequestStatus? status,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Request(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      city: city ?? this.city,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
