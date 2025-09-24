import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/specialist_service.dart';

/// Сервис для работы с услугами специалистов
class SpecialistServiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать услугу
  Future<String> createService(SpecialistService service) async {
    try {
      final docRef = await _firestore.collection('specialist_services').add(service.toMap());
      
      debugPrint('Service created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating service: $e');
      throw Exception('Ошибка создания услуги: $e');
    }
  }

  /// Обновить услугу
  Future<void> updateService(SpecialistService service) async {
    try {
      await _firestore.collection('specialist_services').doc(service.id).update({
        ...service.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Service updated: ${service.id}');
    } catch (e) {
      debugPrint('Error updating service: $e');
      throw Exception('Ошибка обновления услуги: $e');
    }
  }

  /// Удалить услугу
  Future<void> deleteService(String serviceId) async {
    try {
      await _firestore.collection('specialist_services').doc(serviceId).delete();
      
      debugPrint('Service deleted: $serviceId');
    } catch (e) {
      debugPrint('Error deleting service: $e');
      throw Exception('Ошибка удаления услуги: $e');
    }
  }

  /// Получить услуги специалиста
  Stream<List<SpecialistService>> getSpecialistServices(
    String specialistId, {
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) {
    Query query = _firestore
        .collection('specialist_services')
        .where('specialistId', isEqualTo: specialistId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SpecialistService.fromDocument(doc)).toList();
    });
  }

  /// Получить активные услуги специалиста
  Stream<List<SpecialistService>> getActiveServices(String specialistId) {
    return _firestore
        .collection('specialist_services')
        .where('specialistId', isEqualTo: specialistId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SpecialistService.fromDocument(doc)).toList();
    });
  }

  /// Получить популярные услуги специалиста
  Stream<List<SpecialistService>> getPopularServices(String specialistId) {
    return _firestore
        .collection('specialist_services')
        .where('specialistId', isEqualTo: specialistId)
        .where('isPopular', isEqualTo: true)
        .orderBy('bookingCount', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SpecialistService.fromDocument(doc)).toList();
    });
  }

  /// Получить рекомендуемые услуги специалиста
  Stream<List<SpecialistService>> getRecommendedServices(String specialistId) {
    return _firestore
        .collection('specialist_services')
        .where('specialistId', isEqualTo: specialistId)
        .where('isRecommended', isEqualTo: true)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SpecialistService.fromDocument(doc)).toList();
    });
  }

  /// Получить услуги по категории
  Stream<List<SpecialistService>> getServicesByCategory(
    String specialistId,
    String category,
  ) {
    return _firestore
        .collection('specialist_services')
        .where('specialistId', isEqualTo: specialistId)
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SpecialistService.fromDocument(doc)).toList();
    });
  }

  /// Получить услуги по типу цены
  Stream<List<SpecialistService>> getServicesByPriceType(
    String specialistId,
    ServicePriceType priceType,
  ) {
    return _firestore
        .collection('specialist_services')
        .where('specialistId', isEqualTo: specialistId)
        .where('priceType', isEqualTo: priceType.name)
        .where('isActive', isEqualTo: true)
        .orderBy('price')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SpecialistService.fromDocument(doc)).toList();
    });
  }

  /// Поиск услуг
  Stream<List<SpecialistService>> searchServices(
    String specialistId,
    String query, {
    int limit = 20,
  }) {
    return _firestore
        .collection('specialist_services')
        .where('specialistId', isEqualTo: specialistId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SpecialistService.fromDocument(doc)).toList();
    });
  }

  /// Получить услугу по ID
  Future<SpecialistService?> getServiceById(String serviceId) async {
    try {
      final doc = await _firestore.collection('specialist_services').doc(serviceId).get();
      if (!doc.exists) return null;
      
      return SpecialistService.fromDocument(doc);
    } catch (e) {
      debugPrint('Error getting service by ID: $e');
      return null;
    }
  }

  /// Обновить статистику услуги
  Future<void> updateServiceStats(String serviceId, {
    int? bookingCount,
    double? rating,
    int? reviewCount,
    double? totalEarnings,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (bookingCount != null) {
        updateData['bookingCount'] = FieldValue.increment(bookingCount);
      }
      if (rating != null) {
        updateData['rating'] = rating;
      }
      if (reviewCount != null) {
        updateData['reviewCount'] = FieldValue.increment(reviewCount);
      }
      if (totalEarnings != null) {
        updateData['totalEarnings'] = FieldValue.increment(totalEarnings);
      }

      await _firestore.collection('specialist_services').doc(serviceId).update(updateData);
      
      debugPrint('Service stats updated: $serviceId');
    } catch (e) {
      debugPrint('Error updating service stats: $e');
      throw Exception('Ошибка обновления статистики услуги: $e');
    }
  }

  /// Отметить услугу как популярную
  Future<void> markAsPopular(String serviceId, bool isPopular) async {
    try {
      await _firestore.collection('specialist_services').doc(serviceId).update({
        'isPopular': isPopular,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Service popularity updated: $serviceId');
    } catch (e) {
      debugPrint('Error updating service popularity: $e');
      throw Exception('Ошибка обновления популярности услуги: $e');
    }
  }

  /// Отметить услугу как рекомендуемую
  Future<void> markAsRecommended(String serviceId, bool isRecommended) async {
    try {
      await _firestore.collection('specialist_services').doc(serviceId).update({
        'isRecommended': isRecommended,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Service recommendation updated: $serviceId');
    } catch (e) {
      debugPrint('Error updating service recommendation: $e');
      throw Exception('Ошибка обновления рекомендации услуги: $e');
    }
  }

  /// Активировать/деактивировать услугу
  Future<void> toggleServiceStatus(String serviceId, bool isActive) async {
    try {
      await _firestore.collection('specialist_services').doc(serviceId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Service status updated: $serviceId');
    } catch (e) {
      debugPrint('Error updating service status: $e');
      throw Exception('Ошибка обновления статуса услуги: $e');
    }
  }

  /// Обновить цену услуги
  Future<void> updateServicePrice(String serviceId, double newPrice, {
    double? originalPrice,
    int? discount,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'price': newPrice,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (originalPrice != null) {
        updateData['originalPrice'] = originalPrice;
      }
      if (discount != null) {
        updateData['discount'] = discount;
      }

      await _firestore.collection('specialist_services').doc(serviceId).update(updateData);
      
      // Сохраняем историю изменения цены
      await _savePriceHistory(serviceId, newPrice, originalPrice, discount);
      
      debugPrint('Service price updated: $serviceId');
    } catch (e) {
      debugPrint('Error updating service price: $e');
      throw Exception('Ошибка обновления цены услуги: $e');
    }
  }

  /// Получить статистику услуг специалиста
  Future<Map<String, dynamic>> getSpecialistServiceStats(String specialistId) async {
    try {
      final servicesQuery = await _firestore
          .collection('specialist_services')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      if (servicesQuery.docs.isEmpty) {
        return {
          'totalServices': 0,
          'activeServices': 0,
          'popularServices': 0,
          'recommendedServices': 0,
          'totalBookings': 0,
          'averageRating': 0.0,
          'totalEarnings': 0.0,
          'averagePrice': 0.0,
        };
      }

      int totalServices = 0;
      int activeServices = 0;
      int popularServices = 0;
      int recommendedServices = 0;
      int totalBookings = 0;
      double totalRating = 0.0;
      int ratedServices = 0;
      double totalEarnings = 0.0;
      double totalPrice = 0.0;

      for (final doc in servicesQuery.docs) {
        final service = SpecialistService.fromDocument(doc);
        
        totalServices++;
        
        if (service.isActive) activeServices++;
        if (service.isPopular) popularServices++;
        if (service.isRecommended) recommendedServices++;
        
        totalBookings += service.bookingCount;
        
        if (service.rating > 0) {
          totalRating += service.rating;
          ratedServices++;
        }
        
        if (service.totalEarnings != null) {
          totalEarnings += service.totalEarnings!;
        }
        
        totalPrice += service.price;
      }

      return {
        'totalServices': totalServices,
        'activeServices': activeServices,
        'popularServices': popularServices,
        'recommendedServices': recommendedServices,
        'totalBookings': totalBookings,
        'averageRating': ratedServices > 0 ? totalRating / ratedServices : 0.0,
        'totalEarnings': totalEarnings,
        'averagePrice': totalServices > 0 ? totalPrice / totalServices : 0.0,
      };
    } catch (e) {
      debugPrint('Error getting specialist service stats: $e');
      return {};
    }
  }

  /// Получить топ услуги по заказам
  Future<List<SpecialistService>> getTopServicesByBookings(
    String specialistId, {
    int limit = 10,
  }) async {
    try {
      final servicesQuery = await _firestore
          .collection('specialist_services')
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .orderBy('bookingCount', descending: true)
          .limit(limit)
          .get();

      return servicesQuery.docs.map((doc) => SpecialistService.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('Error getting top services by bookings: $e');
      return [];
    }
  }

  /// Получить топ услуги по рейтингу
  Future<List<SpecialistService>> getTopServicesByRating(
    String specialistId, {
    int limit = 10,
  }) async {
    try {
      final servicesQuery = await _firestore
          .collection('specialist_services')
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .where('rating', isGreaterThan: 0)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return servicesQuery.docs.map((doc) => SpecialistService.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('Error getting top services by rating: $e');
      return [];
    }
  }

  /// Получить топ услуги по доходам
  Future<List<SpecialistService>> getTopServicesByEarnings(
    String specialistId, {
    int limit = 10,
  }) async {
    try {
      final servicesQuery = await _firestore
          .collection('specialist_services')
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .where('totalEarnings', isGreaterThan: 0)
          .orderBy('totalEarnings', descending: true)
          .limit(limit)
          .get();

      return servicesQuery.docs.map((doc) => SpecialistService.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('Error getting top services by earnings: $e');
      return [];
    }
  }

  /// Дублировать услугу
  Future<String> duplicateService(String serviceId, String newName) async {
    try {
      final originalService = await getServiceById(serviceId);
      if (originalService == null) {
        throw Exception('Услуга не найдена');
      }

      final duplicatedService = originalService.copyWith(
        id: '', // Будет установлен Firestore
        name: newName,
        bookingCount: 0,
        rating: 0.0,
        reviewCount: 0,
        totalEarnings: null,
        createdAt: DateTime.now(),
        updatedAt: null,
        lastBookedAt: null,
      );

      final newServiceId = await createService(duplicatedService);
      
      debugPrint('Service duplicated: $serviceId -> $newServiceId');
      return newServiceId;
    } catch (e) {
      debugPrint('Error duplicating service: $e');
      throw Exception('Ошибка дублирования услуги: $e');
    }
  }

  /// Сохранить историю изменения цены
  Future<void> _savePriceHistory(
    String serviceId,
    double newPrice,
    double? originalPrice,
    int? discount,
  ) async {
    try {
      await _firestore.collection('service_price_history').add({
        'serviceId': serviceId,
        'newPrice': newPrice,
        'originalPrice': originalPrice,
        'discount': discount,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error saving price history: $e');
    }
  }

  /// Получить историю изменения цен услуги
  Future<List<Map<String, dynamic>>> getServicePriceHistory(String serviceId) async {
    try {
      final historyQuery = await _firestore
          .collection('service_price_history')
          .where('serviceId', isEqualTo: serviceId)
          .orderBy('updatedAt', descending: true)
          .limit(50)
          .get();

      return historyQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'newPrice': data['newPrice'],
          'originalPrice': data['originalPrice'],
          'discount': data['discount'],
          'updatedAt': (data['updatedAt'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting service price history: $e');
      return [];
    }
  }

  /// Получить аналитику услуг
  Future<Map<String, dynamic>> getServiceAnalytics(String specialistId) async {
    try {
      final servicesQuery = await _firestore
          .collection('specialist_services')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      if (servicesQuery.docs.isEmpty) {
        return {
          'totalServices': 0,
          'activeServices': 0,
          'totalBookings': 0,
          'totalEarnings': 0.0,
          'averageRating': 0.0,
          'priceRange': {'min': 0.0, 'max': 0.0, 'average': 0.0},
          'categoryDistribution': {},
          'priceTypeDistribution': {},
        };
      }

      final services = servicesQuery.docs.map((doc) => SpecialistService.fromDocument(doc)).toList();
      
      // Анализ цен
      final prices = services.map((s) => s.price).toList();
      prices.sort();
      
      // Анализ категорий
      final categoryDistribution = <String, int>{};
      for (final service in services) {
        if (service.category != null) {
          categoryDistribution[service.category!] = (categoryDistribution[service.category!] ?? 0) + 1;
        }
      }
      
      // Анализ типов цен
      final priceTypeDistribution = <String, int>{};
      for (final service in services) {
        priceTypeDistribution[service.priceType.name] = (priceTypeDistribution[service.priceType.name] ?? 0) + 1;
      }

      return {
        'totalServices': services.length,
        'activeServices': services.where((s) => s.isActive).length,
        'totalBookings': services.fold(0, (sum, s) => sum + s.bookingCount),
        'totalEarnings': services.fold(0.0, (sum, s) => sum + (s.totalEarnings ?? 0.0)),
        'averageRating': services.where((s) => s.rating > 0).fold(0.0, (sum, s) => sum + s.rating) / services.where((s) => s.rating > 0).length,
        'priceRange': {
          'min': prices.isNotEmpty ? prices.first : 0.0,
          'max': prices.isNotEmpty ? prices.last : 0.0,
          'average': prices.isNotEmpty ? prices.reduce((a, b) => a + b) / prices.length : 0.0,
        },
        'categoryDistribution': categoryDistribution,
        'priceTypeDistribution': priceTypeDistribution,
      };
    } catch (e) {
      debugPrint('Error getting service analytics: $e');
      return {};
    }
  }
}
