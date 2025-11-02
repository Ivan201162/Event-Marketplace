import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/search_filters.dart';
import 'package:event_marketplace_app/models/specialist.dart';
import 'package:flutter/foundation.dart';

/// Service for managing specialists data
class SpecialistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'specialists';

  /// Get all specialists
  Future<List<Specialist>> getAllSpecialists() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs.map(Specialist.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error getting all specialists: $e');
      return [];
    }
  }

  /// Get specialists by city
  Future<List<Specialist>> getSpecialistsByCity(String city) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('city', isEqualTo: city)
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs.map(Specialist.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error getting specialists by city: $e');
      return [];
    }
  }

  /// Get specialists by specialization
  Future<List<Specialist>> getSpecialistsBySpecialization(
      String specialization,) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('specialization', isEqualTo: specialization)
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs.map(Specialist.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error getting specialists by specialization: $e');
      return [];
    }
  }

  /// Get top specialists (by rating)
  Future<List<Specialist>> getTopSpecialists({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('rating', descending: true)
          .orderBy('completedEvents', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(Specialist.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error getting top specialists: $e');
      return [];
    }
  }

  /// Get top specialists by city
  Future<List<Specialist>> getTopSpecialistsByCity(String city,
      {int limit = 10,}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('city', isEqualTo: city)
          .orderBy('rating', descending: true)
          .orderBy('completedEvents', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(Specialist.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error getting top specialists by city: $e');
      return [];
    }
  }

  /// Search specialists with filters
  Future<List<Specialist>> searchSpecialists(SearchFilters filters) async {
    try {
      Query query = _firestore.collection(_collection);

      // Apply filters
      if (filters.city != null && filters.city!.isNotEmpty) {
        query = query.where('city', isEqualTo: filters.city);
      }

      if (filters.specialization != null &&
          filters.specialization!.isNotEmpty) {
        query =
            query.where('specialization', isEqualTo: filters.specialization);
      }

      if (filters.minRating != null) {
        query =
            query.where('rating', isGreaterThanOrEqualTo: filters.minRating);
      }

      if (filters.minPrice != null) {
        query = query.where('pricePerHour',
            isGreaterThanOrEqualTo: filters.minPrice,);
      }

      if (filters.maxPrice != null) {
        query =
            query.where('pricePerHour', isLessThanOrEqualTo: filters.maxPrice);
      }

      if (filters.isAvailable != null) {
        query = query.where('isAvailable', isEqualTo: filters.isAvailable);
      }

      // Apply sorting
      if (filters.sortBy != null) {
        final ascending = filters.sortAscending ?? false;
        switch (filters.sortBy) {
          case 'rating':
            query = query.orderBy('rating', descending: !ascending);
          case 'price':
            query = query.orderBy('pricePerHour', descending: !ascending);
          case 'experience':
            query = query.orderBy('completedEvents', descending: !ascending);
          case 'name':
            query = query.orderBy('name', descending: !ascending);
          default:
            query = query.orderBy('rating', descending: true);
        }
      } else {
        query = query.orderBy('rating', descending: true);
      }

      final snapshot = await query.get();
      var specialists =
          snapshot.docs.map(Specialist.fromFirestore).toList();

      // Apply text search filter (client-side for now)
      if (filters.query != null && filters.query!.isNotEmpty) {
        final searchQuery = filters.query!.toLowerCase();
        specialists = specialists.where((specialist) {
          final descMatch = specialist.description?.toLowerCase().contains(searchQuery) ?? false;
          return specialist.name.toLowerCase().contains(searchQuery) ||
              specialist.specialization.toLowerCase().contains(searchQuery) ||
              descMatch ||
              specialist.services.any(
                  (service) => service.toLowerCase().contains(searchQuery),);
        }).toList();
      }

      // Apply services filter (client-side)
      if (filters.services != null && filters.services!.isNotEmpty) {
        specialists = specialists.where((specialist) {
          return filters.services!.any(
            (service) => specialist.services
                .any((s) => s.toLowerCase().contains(service.toLowerCase())),
          );
        }).toList();
      }

      return specialists;
    } catch (e) {
      debugPrint('Error searching specialists: $e');
      return [];
    }
  }

  /// Get specialist by ID
  Future<Specialist?> getSpecialistById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Specialist.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting specialist by ID: $e');
      return null;
    }
  }

  /// Get available specializations
  Future<List<String>> getSpecializations() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      final specializations = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final specialization = data['specialization'] as String?;
        if (specialization != null && specialization.isNotEmpty) {
          specializations.add(specialization);
        }
      }

      return specializations.toList()..sort();
    } catch (e) {
      debugPrint('Error getting specializations: $e');
      return [];
    }
  }

  /// Get available cities
  Future<List<String>> getCities() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      final cities = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final city = data['city'] as String?;
        if (city != null && city.isNotEmpty) {
          cities.add(city);
        }
      }

      return cities.toList()..sort();
    } catch (e) {
      debugPrint('Error getting cities: $e');
      return [];
    }
  }

  /// Get available services
  Future<List<String>> getServices() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      final services = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final specialistServices = data['services'] as List<dynamic>?;
        if (specialistServices != null) {
          for (final service in specialistServices) {
            if (service is String && service.isNotEmpty) {
              services.add(service);
            }
          }
        }
      }

      return services.toList()..sort();
    } catch (e) {
      debugPrint('Error getting services: $e');
      return [];
    }
  }

  /// Stream of specialists (for real-time updates)
  Stream<List<Specialist>> getSpecialistsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Specialist.fromFirestore).toList(),);
  }

  /// Stream of specialists by city
  Stream<List<Specialist>> getSpecialistsByCityStream(String city) {
    return _firestore
        .collection(_collection)
        .where('city', isEqualTo: city)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Specialist.fromFirestore).toList(),);
  }

  /// Stream of all active specialists
  Stream<List<Specialist>> getAllSpecialistsStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Specialist.fromFirestore).toList(),);
  }
}
