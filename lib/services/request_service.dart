import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/request.dart';

/// Service for managing requests
class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'requests';

  /// Get requests sent by user
  Future<List<Request>> getSentRequests(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('fromUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Request.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting sent requests: $e');
      return [];
    }
  }

  /// Get requests received by user
  Future<List<Request>> getReceivedRequests(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('toUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Request.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting received requests: $e');
      return [];
    }
  }

  /// Get requests by status
  Future<List<Request>> getRequestsByStatus(String userId, RequestStatus status, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: status.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Request.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting requests by status: $e');
      return [];
    }
  }

  /// Get requests by category
  Future<List<Request>> getRequestsByCategory(String category, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Request.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting requests by category: $e');
      return [];
    }
  }

  /// Get requests by city
  Future<List<Request>> getRequestsByCity(String city, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('city', isEqualTo: city)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Request.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting requests by city: $e');
      return [];
    }
  }

  /// Create a new request
  Future<String?> createRequest({
    required String fromUserId,
    required String toUserId,
    required String city,
    required DateTime date,
    required int budget,
    required String category,
    String? description,
    String? fromUserName,
    String? fromUserAvatarUrl,
    String? toUserName,
    String? toUserAvatarUrl,
    String? eventType,
    int? guestCount,
    String? location,
    List<String>? requirements,
    String? notes,
  }) async {
    try {
      final request = Request(
        id: '', // Will be set by Firestore
        fromUserId: fromUserId,
        toUserId: toUserId,
        city: city,
        date: date,
        budget: budget,
        category: category,
        status: RequestStatus.pending,
        description: description,
        fromUserName: fromUserName,
        fromUserAvatarUrl: fromUserAvatarUrl,
        toUserName: toUserName,
        toUserAvatarUrl: toUserAvatarUrl,
        eventType: eventType,
        guestCount: guestCount,
        location: location,
        requirements: requirements ?? [],
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection(_collection).add(request.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating request: $e');
      return null;
    }
  }

  /// Update request status
  Future<bool> updateRequestStatus(String requestId, RequestStatus status) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': status.toString().split('.').last,
        'responseDate': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating request status: $e');
      return false;
    }
  }

  /// Update request
  Future<bool> updateRequest(String requestId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        ...updates,
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating request: $e');
      return false;
    }
  }

  /// Delete request
  Future<bool> deleteRequest(String requestId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting request: $e');
      return false;
    }
  }

  /// Get request by ID
  Future<Request?> getRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(requestId).get();
      if (doc.exists) {
        return Request.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting request by ID: $e');
      return null;
    }
  }

  /// Search requests
  Future<List<Request>> searchRequests(String query, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final requests = snapshot.docs.map((doc) => Request.fromFirestore(doc)).toList();
      
      // Filter requests that contain the query in description, category, or city
      return requests.where((request) {
        final searchQuery = query.toLowerCase();
        return (request.description?.toLowerCase().contains(searchQuery) ?? false) ||
               request.category.toLowerCase().contains(searchQuery) ||
               request.city.toLowerCase().contains(searchQuery) ||
               (request.eventType?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    } catch (e) {
      debugPrint('Error searching requests: $e');
      return [];
    }
  }

  /// Get request statistics
  Future<Map<String, int>> getRequestStats(String userId) async {
    try {
      final sentSnapshot = await _firestore
          .collection(_collection)
          .where('fromUserId', isEqualTo: userId)
          .get();

      final receivedSnapshot = await _firestore
          .collection(_collection)
          .where('toUserId', isEqualTo: userId)
          .get();

      final int sentCount = sentSnapshot.docs.length;
      final int receivedCount = receivedSnapshot.docs.length;
      int pendingCount = 0;
      int acceptedCount = 0;
      int completedCount = 0;

      for (final doc in receivedSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        switch (status) {
          case 'pending':
            pendingCount++;
            break;
          case 'accepted':
            acceptedCount++;
            break;
          case 'completed':
            completedCount++;
            break;
        }
      }

      return {
        'sent': sentCount,
        'received': receivedCount,
        'pending': pendingCount,
        'accepted': acceptedCount,
        'completed': completedCount,
      };
    } catch (e) {
      debugPrint('Error getting request stats: $e');
      return {
        'sent': 0,
        'received': 0,
        'pending': 0,
        'accepted': 0,
        'completed': 0,
      };
    }
  }

  /// Get available categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final categories = <String>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }
      
      return categories.toList()..sort();
    } catch (e) {
      debugPrint('Error getting categories: $e');
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

  /// Stream of sent requests
  Stream<List<Request>> getSentRequestsStream(String userId, {int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('fromUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Request.fromFirestore(doc))
            .toList());
  }

  /// Stream of received requests
  Stream<List<Request>> getReceivedRequestsStream(String userId, {int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Request.fromFirestore(doc))
            .toList());
  }

  /// Get pending requests count
  Future<int> getPendingRequestsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: RequestStatus.pending.toString().split('.').last)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting pending requests count: $e');
      return 0;
    }
  }

  /// Stream of pending requests count
  Stream<int> getPendingRequestsCountStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: RequestStatus.pending.toString().split('.').last)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
