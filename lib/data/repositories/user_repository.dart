import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/debug_utils.dart';
import '../../models/user.dart';

/// Репозиторий для работы с пользователями
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить пользователя по ID
  Future<AppUser?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromDocument(doc);
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  /// Обновить данные пользователя
  Future<bool> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(updates);
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  /// Создать пользователя
  Future<bool> createUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
      return true;
    } catch (e) {
      debugPrint('Error creating user: $e');
      return false;
    }
  }

  /// Обеспечить наличие полей по умолчанию для пользователя
  Future<void> ensureUserDefaults(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final updates = <String, dynamic>{};

      if (!data.containsKey('city')) {
        updates['city'] = null; // отсутствует — остаётся null, UI обработает
      }
      if (!data.containsKey('role')) {
        updates['role'] = 'customer';
      }
      if (!data.containsKey('region')) {
        updates['region'] = null;
      }
      if (!data.containsKey('avatarUrl')) {
        updates['avatarUrl'] = null;
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await doc.reference.update(updates);
      }
    } catch (e) {
      debugPrint('Error ensuring user defaults: $e');
    }
  }

  /// Поток изменений пользователя
  Stream<AppUser?> watchUser(String uid) =>
      _firestore.collection('users').doc(uid).snapshots().map((doc) {
        if (!doc.exists) return null;
        return AppUser.fromDocument(doc);
      });
}

/// Провайдер репозитория пользователя
final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

/// Провайдер пользователя по ID
final userProvider = StreamProvider.family<AppUser?, String>((ref, uid) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.watchUser(uid);
});

/// Провайдер для обновления пользователя
final updateUserProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final repository = ref.watch(userRepositoryProvider);
  final uid = params['uid'] as String;
  final updates = Map<String, dynamic>.from(params);
  updates.remove('uid');
  return repository.updateUser(uid, updates);
});
