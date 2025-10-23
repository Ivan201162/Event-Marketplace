import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_template.dart';

/// Сервис для работы с шаблонами услуг
class ServiceTemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить все шаблоны услуг
  Future<List<ServiceTemplate>> getServiceTemplates() async {
    try {
      final snapshot = await _firestore
          .collection('serviceTemplates')
          .where('isActive', isEqualTo: true)
          .orderBy('categoryName')
          .orderBy('serviceName')
          .get();

      return snapshot.docs.map(ServiceTemplate.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения шаблонов услуг: $e');
    }
  }

  /// Получить шаблоны услуг по категории
  Future<List<ServiceTemplate>> getServiceTemplatesByCategory(
      String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('serviceTemplates')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .orderBy('serviceName')
          .get();

      return snapshot.docs.map(ServiceTemplate.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения шаблонов услуг по категории: $e');
    }
  }

  /// Получить шаблон услуги по ID
  Future<ServiceTemplate?> getServiceTemplate(String templateId) async {
    try {
      final doc =
          await _firestore.collection('serviceTemplates').doc(templateId).get();
      if (doc.exists) {
        return ServiceTemplate.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения шаблона услуги: $e');
    }
  }

  /// Создать шаблон услуги
  Future<String> createServiceTemplate(ServiceTemplate template) async {
    try {
      final docRef =
          await _firestore.collection('serviceTemplates').add(template.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания шаблона услуги: $e');
    }
  }

  /// Обновить шаблон услуги
  Future<void> updateServiceTemplate(
      String templateId, ServiceTemplate template) async {
    try {
      await _firestore
          .collection('serviceTemplates')
          .doc(templateId)
          .update(template.toMap());
    } catch (e) {
      throw Exception('Ошибка обновления шаблона услуги: $e');
    }
  }

  /// Удалить шаблон услуги
  Future<void> deleteServiceTemplate(String templateId) async {
    try {
      await _firestore.collection('serviceTemplates').doc(templateId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка удаления шаблона услуги: $e');
    }
  }
}

/// Сервис для работы с услугами специалистов
class SpecialistServiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить услуги специалиста
  Future<List<SpecialistService>> getSpecialistServices(
      String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('services')
          .where('isActive', isEqualTo: true)
          .orderBy('serviceName')
          .get();

      return snapshot.docs.map(SpecialistService.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения услуг специалиста: $e');
    }
  }

  /// Получить услугу специалиста по ID
  Future<SpecialistService?> getSpecialistService(
      String specialistId, String serviceId) async {
    try {
      final doc = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('services')
          .doc(serviceId)
          .get();

      if (doc.exists) {
        return SpecialistService.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения услуги специалиста: $e');
    }
  }

  /// Создать услугу специалиста
  Future<String> createSpecialistService(
      String specialistId, SpecialistService service) async {
    try {
      final docRef = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('services')
          .add(service.toMap());

      // Обновляем время последнего обновления цен
      await _firestore.collection('specialists').doc(specialistId).update({
        'lastPriceUpdateAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания услуги специалиста: $e');
    }
  }

  /// Обновить услугу специалиста
  Future<void> updateSpecialistService(
    String specialistId,
    String serviceId,
    SpecialistService service,
  ) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('services')
          .doc(serviceId)
          .update(service.toMap());

      // Обновляем время последнего обновления цен
      await _firestore.collection('specialists').doc(specialistId).update({
        'lastPriceUpdateAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка обновления услуги специалиста: $e');
    }
  }

  /// Удалить услугу специалиста
  Future<void> deleteSpecialistService(
      String specialistId, String serviceId) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('services')
          .doc(serviceId)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now())
      });

      // Обновляем время последнего обновления цен
      await _firestore.collection('specialists').doc(specialistId).update({
        'lastPriceUpdateAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка удаления услуги специалиста: $e');
    }
  }

  /// Получить услуги специалистов по категории
  Future<List<SpecialistService>> getServicesByCategory(
      String categoryId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('services')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .orderBy('priceMin')
          .get();

      return snapshot.docs.map(SpecialistService.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения услуг по категории: $e');
    }
  }

  /// Поиск услуг по названию
  Future<List<SpecialistService>> searchServices(String query) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('services')
          .where('serviceName', isGreaterThanOrEqualTo: query)
          .where('serviceName', isLessThan: '$query\uf8ff')
          .where('isActive', isEqualTo: true)
          .limit(20)
          .get();

      return snapshot.docs.map(SpecialistService.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка поиска услуг: $e');
    }
  }
}
