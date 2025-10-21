import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель акции/предложения
class Promotion {
  const Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.discount,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
    required this.specialistId,
    this.specialistName,
    this.city,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создание из Firestore документа
  factory Promotion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Promotion(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      discount: data['discount'] ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      specialistId: data['specialistId'] ?? '',
      specialistName: data['specialistName'],
      city: data['city'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String title;
  final String description;
  final String category;
  final int discount;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;
  final String specialistId;
  final String? specialistName;
  final String? city;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() => {
    'title': title,
    'description': description,
    'category': category,
    'discount': discount,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'imageUrl': imageUrl,
    'specialistId': specialistId,
    'specialistName': specialistName,
    'city': city,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  /// Копирование с изменениями
  Promotion copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? discount,
    DateTime? startDate,
    DateTime? endDate,
    String? imageUrl,
    String? specialistId,
    String? specialistName,
    String? city,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Promotion(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    discount: discount ?? this.discount,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    imageUrl: imageUrl ?? this.imageUrl,
    specialistId: specialistId ?? this.specialistId,
    specialistName: specialistName ?? this.specialistName,
    city: city ?? this.city,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Проверка, активна ли акция
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Оставшееся время до окончания
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) {
      return Duration.zero;
    }
    return endDate.difference(now);
  }

  /// Форматированное время до окончания
  String get formattedTimeRemaining {
    final duration = timeRemaining;
    if (duration == Duration.zero) {
      return 'Завершена';
    }

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '$daysд $hoursч';
    } else if (hours > 0) {
      return '$hoursч $minutesм';
    } else {
      return '$minutesм';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Promotion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Promotion(id: $id, title: $title, discount: $discount%, category: $category)';
}

/// Категории акций
enum PromotionCategory {
  all('Все'),
  photographer('Фотографы'),
  videographer('Видеографы'),
  dj('DJ'),
  host('Ведущие'),
  decorator('Декораторы'),
  caterer('Кейтеринг'),
  musician('Музыканты'),
  other('Другое');

  const PromotionCategory(this.displayName);
  final String displayName;
}

/// Типы акций
enum PromotionType {
  discount('Скидка'),
  seasonal('Сезонное предложение'),
  gift('Подарок'),
  promoCode('Промокод');

  const PromotionType(this.displayName);
  final String displayName;
}
