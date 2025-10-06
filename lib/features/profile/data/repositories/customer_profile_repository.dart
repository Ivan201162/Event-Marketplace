import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_profile.dart';

/// Репозиторий для работы с профилями заказчиков
class CustomerProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'customer_profiles';

  /// Получить профиль заказчика по ID
  Future<CustomerProfile?> getProfile(String customerId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(customerId).get();
      if (doc.exists) {
        return CustomerProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения профиля: $e');
      return null;
    }
  }

  /// Сохранить профиль заказчика
  Future<bool> saveProfile(CustomerProfile profile) async {
    try {
      await _firestore.collection(_collection).doc(profile.id).set(
            profile.toFirestore(),
            SetOptions(merge: true),
          );
      return true;
    } catch (e) {
      print('Ошибка сохранения профиля: $e');
      return false;
    }
  }

  /// Обновить профиль заказчика
  Future<bool> updateProfile(
      String customerId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection(_collection).doc(customerId).update(updates);
      return true;
    } catch (e) {
      print('Ошибка обновления профиля: $e');
      return false;
    }
  }

  /// Удалить профиль заказчика
  Future<bool> deleteProfile(String customerId) async {
    try {
      await _firestore.collection(_collection).doc(customerId).delete();
      return true;
    } catch (e) {
      print('Ошибка удаления профиля: $e');
      return false;
    }
  }

  /// Получить поток обновлений профиля
  Stream<CustomerProfile?> getProfileStream(String customerId) =>
      _firestore.collection(_collection).doc(customerId).snapshots().map((doc) {
        if (doc.exists) {
          return CustomerProfile.fromFirestore(doc);
        }
        return null;
      });
}
