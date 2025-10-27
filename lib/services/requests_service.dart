import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/request.dart';

/// Сервис для работы с заявками
class RequestsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить заявки
  Future<List<Request>> getRequests() async {
    try {
      final snapshot = await _firestore
          .collection('requests')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Request.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки заявок: $e');
    }
  }

  /// Загрузить больше заявок
  Future<List<Request>> getMoreRequests(int offset) async {
    try {
      final snapshot = await _firestore
          .collection('requests')
          .orderBy('createdAt', descending: true)
          .startAfter([offset])
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Request.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки дополнительных заявок: $e');
    }
  }

  /// Поиск заявок
  Future<List<Request>> searchRequests(String query) async {
    try {
      final snapshot = await _firestore
          .collection('requests')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + '\uf8ff')
          .orderBy('title')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Request.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка поиска заявок: $e');
    }
  }

  /// Фильтрация заявок
  Future<List<Request>> filterRequests(String filter) async {
    try {
      Query query = _firestore.collection('requests');

      switch (filter) {
        case 'open':
          query = query.where('status', isEqualTo: 'OPEN');
          break;
        case 'in_progress':
          query = query.where('status', isEqualTo: 'IN_PROGRESS');
          break;
        case 'done':
          query = query.where('status', isEqualTo: 'DONE');
          break;
        default:
          // Все заявки
          break;
      }

      query = query.orderBy('createdAt', descending: true);
      final snapshot = await query.limit(20).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Request.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка фильтрации заявок: $e');
    }
  }

  /// Создать заявку
  Future<String> createRequest(Request request) async {
    try {
      final docRef =
          await _firestore.collection('requests').add(request.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания заявки: $e');
    }
  }

  /// Обновить статус заявки
  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка обновления статуса заявки: $e');
    }
  }

  /// Удалить заявку
  Future<void> deleteRequest(String requestId) async {
    try {
      await _firestore.collection('requests').doc(requestId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления заявки: $e');
    }
  }

  /// Получить заявку по ID
  Future<Request?> getRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection('requests').doc(requestId).get();
      if (doc.exists) {
        return Request.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения заявки: $e');
    }
  }
}
