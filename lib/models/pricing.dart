import 'package:cloud_firestore/cloud_firestore.dart';

/// Базовая цена услуги специалиста
class BasePricing {
  BasePricing({
    required this.id,
    required this.eventType,
    required this.priceFrom,
    required this.hours,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String eventType; // Свадьба, Юбилей, Корпоратив и т.д.
  final int priceFrom; // Цена "от" в рублях
  final int hours; // Количество часов
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BasePricing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BasePricing(
      id: doc.id,
      eventType: data['eventType'] as String,
      priceFrom: (data['priceFrom'] as num).toInt(),
      hours: (data['hours'] as num?)?.toInt() ?? 4,
      description: data['description'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventType': eventType,
      'priceFrom': priceFrom,
      'hours': hours,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Специальная цена на конкретную дату
class SpecialDatePricing {
  SpecialDatePricing({
    required this.date, // YYYY-MM-DD
    required this.eventType,
    this.priceFrom,
    this.coefficient, // Коэффициент (например, 1.5 для +50%)
    this.hours,
    this.createdAt,
    this.updatedAt,
  });

  final String date; // YYYY-MM-DD
  final String eventType;
  final int? priceFrom; // Фиксированная цена
  final double? coefficient; // Коэффициент умножения базовой цены
  final int? hours;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SpecialDatePricing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpecialDatePricing(
      date: doc.id,
      eventType: data['eventType'] as String,
      priceFrom: (data['priceFrom'] as num?)?.toInt(),
      coefficient: (data['coefficient'] as num?)?.toDouble(),
      hours: (data['hours'] as num?)?.toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'eventType': eventType,
      if (priceFrom != null) 'priceFrom': priceFrom,
      if (coefficient != null) 'coefficient': coefficient,
      if (hours != null) 'hours': hours,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Рыночная оценка цены
enum PriceRating {
  excellent, // 🟢 Отличная цена (ниже среднего -15%)
  average, // 🟡 Средняя цена (среднее ±15%)
  high, // 🔴 Высокая цена (выше +15%)
}

extension PriceRatingExtension on PriceRating {
  String get emoji {
    switch (this) {
      case PriceRating.excellent:
        return '🟢';
      case PriceRating.average:
        return '🟡';
      case PriceRating.high:
        return '🔴';
    }
  }

  String get label {
    switch (this) {
      case PriceRating.excellent:
        return 'отличная цена';
      case PriceRating.average:
        return 'средняя цена';
      case PriceRating.high:
        return 'высокая цена';
    }
  }
}

