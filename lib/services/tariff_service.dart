import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Tariff model
class Tariff {

  const Tariff({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration, required this.createdAt, required this.updatedAt, this.currency = 'RUB',
    this.features = const [],
    this.isActive = true,
    this.isPopular = false,
    this.sortOrder = 0,
  });

  /// Create Tariff from Firestore document
  factory Tariff.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Tariff(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'RUB',
      duration: data['duration'] ?? 30,
      features: List<String>.from(data['features'] ?? []),
      isActive: data['isActive'] ?? true,
      isPopular: data['isPopular'] ?? false,
      sortOrder: data['sortOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int duration; // in days
  final List<String> features;
  final bool isActive;
  final bool isPopular;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Convert Tariff to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'duration': duration,
      'features': features,
      'isActive': isActive,
      'isPopular': isPopular,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get formatted price
  String get formattedPrice => '$price $currency';

  /// Get duration in months
  double get durationInMonths => duration / 30.0;

  /// Check if tariff has specific feature
  bool hasFeature(String feature) => features.contains(feature);
}

/// Service for managing tariffs
class TariffService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'tariffs';

  /// Get all active tariffs
  Future<List<Tariff>> getTariffs() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs.map(Tariff.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error getting tariffs: $e');
      return [];
    }
  }

  /// Get popular tariffs
  Future<List<Tariff>> getPopularTariffs() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('isPopular', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs.map(Tariff.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error getting popular tariffs: $e');
      return [];
    }
  }

  /// Get tariff by ID
  Future<Tariff?> getTariffById(String tariffId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(tariffId).get();
      if (doc.exists) {
        return Tariff.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting tariff by ID: $e');
      return null;
    }
  }

  /// Create tariff (admin only)
  Future<String?> createTariff(Tariff tariff) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(tariff.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating tariff: $e');
      return null;
    }
  }

  /// Update tariff (admin only)
  Future<bool> updateTariff(
      String tariffId, Map<String, dynamic> updates,) async {
    try {
      await _firestore.collection(_collection).doc(tariffId).update({
        ...updates,
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating tariff: $e');
      return false;
    }
  }

  /// Delete tariff (admin only)
  Future<bool> deleteTariff(String tariffId) async {
    try {
      await _firestore.collection(_collection).doc(tariffId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting tariff: $e');
      return false;
    }
  }

  /// Stream of tariffs
  Stream<List<Tariff>> getTariffsStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Tariff.fromFirestore).toList(),);
  }

  /// Get tariffs by price range
  Future<List<Tariff>> getTariffsByPriceRange(
      double minPrice, double maxPrice,) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('price', isGreaterThanOrEqualTo: minPrice)
          .where('price', isLessThanOrEqualTo: maxPrice)
          .orderBy('price')
          .get();

      return snapshot.docs.map(Tariff.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error getting tariffs by price range: $e');
      return [];
    }
  }

  /// Get tariffs by duration
  Future<List<Tariff>> getTariffsByDuration(int duration) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('duration', isEqualTo: duration)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs.map(Tariff.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error getting tariffs by duration: $e');
      return [];
    }
  }
}
