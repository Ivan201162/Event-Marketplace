import 'package:cloud_firestore/cloud_firestore.dart';

/// Шаблон услуги по категории
class ServiceTemplate {
  const ServiceTemplate({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.serviceName,
    required this.description,
    required this.createdAt, required this.updatedAt, this.requiredFields = const [],
    this.defaultPricing = const {},
    this.isActive = true,
  });

  /// Создать из документа Firestore
  factory ServiceTemplate.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ServiceTemplate(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      serviceName: data['serviceName'] ?? '',
      description: data['description'] ?? '',
      requiredFields: List<String>.from(data['requiredFields'] ?? []),
      defaultPricing: Map<String, dynamic>.from(data['defaultPricing'] ?? {}),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String categoryId;
  final String categoryName;
  final String serviceName;
  final String description;
  final List<String> requiredFields;
  final Map<String, dynamic> defaultPricing;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'serviceName': serviceName,
        'description': description,
        'requiredFields': requiredFields,
        'defaultPricing': defaultPricing,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceTemplate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ServiceTemplate(id: $id, serviceName: $serviceName, categoryName: $categoryName)';
}

/// Услуга специалиста
class SpecialistService {
  const SpecialistService({
    required this.id,
    required this.specialistId,
    required this.serviceName,
    required this.description,
    required this.priceMin,
    required this.priceMax,
    required this.createdAt, required this.updatedAt, this.currency = 'RUB',
    this.pricingDetails = const {},
    this.isActive = true,
  });

  /// Создать из документа Firestore
  factory SpecialistService.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistService(
      id: doc.id,
      specialistId: data['specialistId'] ?? '',
      serviceName: data['serviceName'] ?? '',
      description: data['description'] ?? '',
      priceMin: (data['priceMin'] as num).toDouble(),
      priceMax: (data['priceMax'] as num).toDouble(),
      currency: data['currency'] ?? 'RUB',
      pricingDetails: Map<String, dynamic>.from(data['pricingDetails'] ?? {}),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String specialistId;
  final String serviceName;
  final String description;
  final double priceMin;
  final double priceMax;
  final String currency;
  final Map<String, dynamic> pricingDetails;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'serviceName': serviceName,
        'description': description,
        'priceMin': priceMin,
        'priceMax': priceMax,
        'currency': currency,
        'pricingDetails': pricingDetails,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Получить среднюю цену
  double get averagePrice => (priceMin + priceMax) / 2;

  /// Получить диапазон цен в читаемом виде
  String get priceRange {
    if (priceMin == priceMax) {
      return '${priceMin.toStringAsFixed(0)} $currency';
    }
    return '${priceMin.toStringAsFixed(0)} - ${priceMax.toStringAsFixed(0)} $currency';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialistService && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SpecialistService(id: $id, serviceName: $serviceName, priceRange: $priceRange)';
}
