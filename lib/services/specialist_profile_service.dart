import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/specialist.dart';

/// Сервис для работы с профилем специалиста (контакты, услуги)
class SpecialistProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'specialists';

  /// Обновить контакты специалиста
  Future<void> updateContacts(
    String specialistId,
    Map<String, String> contacts,
  ) async {
    try {
      await _firestore.collection(_collection).doc(specialistId).update({
        'contacts': contacts,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка обновления контактов: $e');
    }
  }

  /// Обновить услуги с ценами
  Future<void> updateServicesWithPrices(
    String specialistId,
    Map<String, double> servicesWithPrices,
  ) async {
    try {
      await _firestore.collection(_collection).doc(specialistId).update({
        'servicesWithPrices': servicesWithPrices,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка обновления услуг: $e');
    }
  }

  /// Добавить контакт
  Future<void> addContact(
    String specialistId,
    String contactType,
    String contactValue,
  ) async {
    try {
      final specialistDoc =
          await _firestore.collection(_collection).doc(specialistId).get();

      if (!specialistDoc.exists) {
        throw Exception('Специалист не найден');
      }

      final specialist = Specialist.fromDocument(specialistDoc);
      final updatedContacts = Map<String, String>.from(specialist.contacts);
      updatedContacts[contactType] = contactValue;

      await updateContacts(specialistId, updatedContacts);
    } catch (e) {
      throw Exception('Ошибка добавления контакта: $e');
    }
  }

  /// Удалить контакт
  Future<void> removeContact(String specialistId, String contactType) async {
    try {
      final specialistDoc =
          await _firestore.collection(_collection).doc(specialistId).get();

      if (!specialistDoc.exists) {
        throw Exception('Специалист не найден');
      }

      final specialist = Specialist.fromDocument(specialistDoc);
      final updatedContacts = Map<String, String>.from(specialist.contacts);
      updatedContacts.remove(contactType);

      await updateContacts(specialistId, updatedContacts);
    } catch (e) {
      throw Exception('Ошибка удаления контакта: $e');
    }
  }

  /// Добавить услугу с ценой
  Future<void> addServiceWithPrice(
    String specialistId,
    String serviceName,
    double price,
  ) async {
    try {
      final specialistDoc =
          await _firestore.collection(_collection).doc(specialistId).get();

      if (!specialistDoc.exists) {
        throw Exception('Специалист не найден');
      }

      final specialist = Specialist.fromDocument(specialistDoc);
      final updatedServices =
          Map<String, double>.from(specialist.servicesWithPrices);
      updatedServices[serviceName] = price;

      await updateServicesWithPrices(specialistId, updatedServices);
    } catch (e) {
      throw Exception('Ошибка добавления услуги: $e');
    }
  }

  /// Обновить цену услуги
  Future<void> updateServicePrice(
    String specialistId,
    String serviceName,
    double newPrice,
  ) async {
    try {
      final specialistDoc =
          await _firestore.collection(_collection).doc(specialistId).get();

      if (!specialistDoc.exists) {
        throw Exception('Специалист не найден');
      }

      final specialist = Specialist.fromDocument(specialistDoc);
      final updatedServices =
          Map<String, double>.from(specialist.servicesWithPrices);

      if (updatedServices.containsKey(serviceName)) {
        updatedServices[serviceName] = newPrice;
        await updateServicesWithPrices(specialistId, updatedServices);
      } else {
        throw Exception('Услуга не найдена');
      }
    } catch (e) {
      throw Exception('Ошибка обновления цены услуги: $e');
    }
  }

  /// Удалить услугу
  Future<void> removeService(String specialistId, String serviceName) async {
    try {
      final specialistDoc =
          await _firestore.collection(_collection).doc(specialistId).get();

      if (!specialistDoc.exists) {
        throw Exception('Специалист не найден');
      }

      final specialist = Specialist.fromDocument(specialistDoc);
      final updatedServices =
          Map<String, double>.from(specialist.servicesWithPrices);
      updatedServices.remove(serviceName);

      await updateServicesWithPrices(specialistId, updatedServices);
    } catch (e) {
      throw Exception('Ошибка удаления услуги: $e');
    }
  }

  /// Получить контакты специалиста
  Future<Map<String, String>> getSpecialistContacts(String specialistId) async {
    try {
      final specialistDoc =
          await _firestore.collection(_collection).doc(specialistId).get();

      if (!specialistDoc.exists) {
        throw Exception('Специалист не найден');
      }

      final specialist = Specialist.fromDocument(specialistDoc);
      return specialist.contacts;
    } catch (e) {
      throw Exception('Ошибка получения контактов: $e');
    }
  }

  /// Получить услуги с ценами
  Future<Map<String, double>> getSpecialistServicesWithPrices(
    String specialistId,
  ) async {
    try {
      final specialistDoc =
          await _firestore.collection(_collection).doc(specialistId).get();

      if (!specialistDoc.exists) {
        throw Exception('Специалист не найден');
      }

      final specialist = Specialist.fromDocument(specialistDoc);
      return specialist.servicesWithPrices;
    } catch (e) {
      throw Exception('Ошибка получения услуг: $e');
    }
  }

  /// Получить поток контактов специалиста
  Stream<Map<String, String>> getSpecialistContactsStream(
    String specialistId,
  ) =>
      _firestore
          .collection(_collection)
          .doc(specialistId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return <String, String>{};
        final specialist = Specialist.fromDocument(doc);
        return specialist.contacts;
      });

  /// Получить поток услуг с ценами
  Stream<Map<String, double>> getSpecialistServicesWithPricesStream(
    String specialistId,
  ) =>
      _firestore
          .collection(_collection)
          .doc(specialistId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return <String, double>{};
        final specialist = Specialist.fromDocument(doc);
        return specialist.servicesWithPrices;
      });
}
