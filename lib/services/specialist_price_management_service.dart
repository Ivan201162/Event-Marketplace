import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/specialist.dart';

/// Сервис для управления ценами специалиста
class SpecialistPriceManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить цены специалиста по услугам
  Future<List<ServicePrice>> getSpecialistPrices(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('specialist_prices')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(ServicePrice.fromDocument).toList();
    } catch (e) {
      debugPrint('Ошибка получения цен специалиста: $e');
      return [];
    }
  }

  /// Добавить цену за услугу
  Future<String> addServicePrice({
    required String specialistId,
    required String serviceName,
    required double price,
    String? description,
    String? duration,
    List<String>? includedServices,
  }) async {
    try {
      final servicePrice = ServicePrice(
        id: '', // Будет сгенерирован Firestore
        specialistId: specialistId,
        serviceName: serviceName,
        price: price,
        description: description,
        duration: duration,
        includedServices: includedServices ?? [],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('specialist_prices').add(servicePrice.toMap());

      // Обновляем время последнего обновления цен в профиле специалиста
      await _updateSpecialistLastPriceUpdate(specialistId);

      return docRef.id;
    } catch (e) {
      debugPrint('Ошибка добавления цены услуги: $e');
      rethrow;
    }
  }

  /// Обновить цену услуги
  Future<void> updateServicePrice({
    required String priceId,
    required String serviceName,
    required double price,
    String? description,
    String? duration,
    List<String>? includedServices,
  }) async {
    try {
      await _firestore.collection('specialist_prices').doc(priceId).update({
        'serviceName': serviceName,
        'price': price,
        'description': description,
        'duration': duration,
        'includedServices': includedServices ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Получаем specialistId для обновления времени последнего обновления
      final doc = await _firestore.collection('specialist_prices').doc(priceId).get();

      if (doc.exists) {
        final data = doc.data()!;
        final specialistId = data['specialistId'] as String;
        await _updateSpecialistLastPriceUpdate(specialistId);
      }
    } catch (e) {
      debugPrint('Ошибка обновления цены услуги: $e');
      rethrow;
    }
  }

  /// Удалить цену услуги
  Future<void> deleteServicePrice(String priceId) async {
    try {
      // Получаем specialistId перед удалением
      final doc = await _firestore.collection('specialist_prices').doc(priceId).get();

      if (doc.exists) {
        final data = doc.data()!;
        final specialistId = data['specialistId'] as String;

        await _firestore.collection('specialist_prices').doc(priceId).delete();

        // Обновляем время последнего обновления цен
        await _updateSpecialistLastPriceUpdate(specialistId);
      }
    } catch (e) {
      debugPrint('Ошибка удаления цены услуги: $e');
      rethrow;
    }
  }

  /// Активировать/деактивировать цену услуги
  Future<void> toggleServicePriceStatus(String priceId, bool isActive) async {
    try {
      await _firestore.collection('specialist_prices').doc(priceId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Ошибка изменения статуса цены услуги: $e');
      rethrow;
    }
  }

  /// Проверить, нужно ли напомнить об обновлении цен
  Future<bool> shouldRemindAboutPriceUpdate(String specialistId) async {
    try {
      final doc = await _firestore.collection('specialists').doc(specialistId).get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final lastPriceUpdate = data['lastPriceUpdateAt'] as Timestamp?;

      if (lastPriceUpdate == null) return true;

      final lastUpdateDate = lastPriceUpdate.toDate();
      final now = DateTime.now();
      final difference = now.difference(lastUpdateDate);

      // Напоминаем раз в месяц (30 дней)
      return difference.inDays >= 30;
    } catch (e) {
      debugPrint('Ошибка проверки напоминания об обновлении цен: $e');
      return false;
    }
  }

  /// Получить шаблоны цен для категории специалиста
  Future<List<ServicePriceTemplate>> getPriceTemplatesForCategory(
    SpecialistCategory category,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('price_templates')
          .where('category', isEqualTo: category.name)
          .get();

      return snapshot.docs.map(ServicePriceTemplate.fromDocument).toList();
    } catch (e) {
      debugPrint('Ошибка получения шаблонов цен: $e');
      return [];
    }
  }

  /// Применить шаблон цен к специалисту
  Future<void> applyPriceTemplate({
    required String specialistId,
    required String templateId,
  }) async {
    try {
      final templateDoc = await _firestore.collection('price_templates').doc(templateId).get();

      if (!templateDoc.exists) {
        throw Exception('Шаблон не найден');
      }

      final template = ServicePriceTemplate.fromDocument(templateDoc);

      // Добавляем цены из шаблона
      for (final service in template.services) {
        await addServicePrice(
          specialistId: specialistId,
          serviceName: service.name,
          price: service.price,
          description: service.description,
          duration: service.duration,
          includedServices: service.includedServices,
        );
      }
    } catch (e) {
      debugPrint('Ошибка применения шаблона цен: $e');
      rethrow;
    }
  }

  // ========== ПРИВАТНЫЕ МЕТОДЫ ==========

  /// Обновить время последнего обновления цен в профиле специалиста
  Future<void> _updateSpecialistLastPriceUpdate(String specialistId) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).update({
        'lastPriceUpdateAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Ошибка обновления времени последнего обновления цен: $e');
    }
  }
}

/// Модель цены услуги
class ServicePrice {
  const ServicePrice({
    required this.id,
    required this.specialistId,
    required this.serviceName,
    required this.price,
    this.description,
    this.duration,
    this.includedServices = const [],
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServicePrice.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ServicePrice(
      id: doc.id,
      specialistId: data['specialistId'] as String? ?? '',
      serviceName: data['serviceName'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String?,
      duration: data['duration'] as String?,
      includedServices: List<String>.from(data['includedServices'] ?? []),
      isActive: data['isActive'] as bool? ?? true,
      createdAt:
          data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  final String id;
  final String specialistId;
  final String serviceName;
  final double price;
  final String? description;
  final String? duration;
  final List<String> includedServices;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'serviceName': serviceName,
        'price': price,
        'description': description,
        'duration': duration,
        'includedServices': includedServices,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

/// Модель шаблона цен
class ServicePriceTemplate {
  const ServicePriceTemplate({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.services,
    required this.createdAt,
  });

  factory ServicePriceTemplate.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ServicePriceTemplate(
      id: doc.id,
      category: SpecialistCategory.values.firstWhere(
        (e) => e.name == data['category'] as String,
        orElse: () => SpecialistCategory.other,
      ),
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      services: (data['services'] as List<dynamic>?)
              ?.map(
                (e) => TemplateService.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      createdAt:
          data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  final String id;
  final SpecialistCategory category;
  final String name;
  final String description;
  final List<TemplateService> services;
  final DateTime createdAt;
}

/// Модель услуги в шаблоне
class TemplateService {
  const TemplateService({
    required this.name,
    required this.price,
    this.description,
    this.duration,
    this.includedServices = const [],
  });

  factory TemplateService.fromMap(Map<String, dynamic> data) => TemplateService(
        name: data['name'] as String? ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        description: data['description'] as String?,
        duration: data['duration'] as String?,
        includedServices: List<String>.from(data['includedServices'] ?? []),
      );

  final String name;
  final double price;
  final String? description;
  final String? duration;
  final List<String> includedServices;

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'description': description,
        'duration': duration,
        'includedServices': includedServices,
      };
}
