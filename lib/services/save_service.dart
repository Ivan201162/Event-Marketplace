import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с сохранениями (bookmarks)
class SaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Сохранить/убрать из сохранённых
  Future<bool> toggleSave({
    required String contentType, // 'posts', 'reels', 'ideas'
    required String contentId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final saveRef = _firestore
          .collection('saves')
          .doc(userId)
          .collection(contentType)
          .doc(contentId);

      final saveDoc = await saveRef.get();

      if (saveDoc.exists) {
        await saveRef.delete();
      } else {
        await saveRef.set({
          'contentId': contentId,
          'contentType': contentType,
          'userId': userId,
          'savedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error toggling save: $e');
      return false;
    }
  }

  /// Проверить, сохранён ли контент
  Future<bool> isSaved({
    required String contentType,
    required String contentId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final saveDoc = await _firestore
          .collection('saves')
          .doc(userId)
          .collection(contentType)
          .doc(contentId)
          .get();

      return saveDoc.exists;
    } catch (e) {
      debugPrint('Error checking save: $e');
      return false;
    }
  }

  /// Stream статуса сохранения
  Stream<bool> isSavedStream({
    required String contentType,
    required String contentId,
  }) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(false);

    return _firestore
        .collection('saves')
        .doc(userId)
        .collection(contentType)
        .doc(contentId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Получить все сохранённые элементы
  Stream<List<Map<String, dynamic>>> getSavedItems({
    required String contentType,
  }) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('saves')
        .doc(userId)
        .collection(contentType)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final items = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final contentId = data['contentId'] as String?;
        if (contentId != null) {
          final contentDoc = await _firestore
              .collection(contentType)
              .doc(contentId)
              .get();
          if (contentDoc.exists) {
            items.add({
              'id': contentId,
              ...contentDoc.data()!,
            });
          }
        }
      }
      return items;
    });
  }
}

