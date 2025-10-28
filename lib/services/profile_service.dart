import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/user_profile.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Сервис для работы с профилем пользователя
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Получить профиль текущего пользователя
  Future<UserProfile> getCurrentUserProfile() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc('current_user_id') // TODO: Получить ID текущего пользователя
          .get();

      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!, doc.id);
      } else {
        // Создать профиль по умолчанию
        return _createDefaultProfile();
      }
    } catch (e) {
      throw Exception('Ошибка загрузки профиля: $e');
    }
  }

  /// Обновить профиль
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.id)
          .update(profile.toMap());
    } catch (e) {
      throw Exception('Ошибка обновления профиля: $e');
    }
  }

  /// Подписаться/отписаться
  Future<void> toggleFollow() async {
    try {
      // TODO: Реализовать логику подписки
      await _firestore.collection('users').doc('current_user_id').update({
        'isFollowing': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка подписки: $e');
    }
  }

  /// Загрузить аватар
  Future<String> uploadAvatar(String imagePath) async {
    try {
      final ref = _storage.ref().child('avatars').child(
          'current_user_id_${DateTime.now().millisecondsSinceEpoch}.jpg',);

      final uploadTask = await ref.putFile(File(imagePath));
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки аватара: $e');
    }
  }

  /// Загрузить обложку
  Future<String> uploadCover(String imagePath) async {
    try {
      final ref = _storage.ref().child('covers').child(
          'current_user_id_${DateTime.now().millisecondsSinceEpoch}.jpg',);

      final uploadTask = await ref.putFile(File(imagePath));
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки обложки: $e');
    }
  }

  /// Создать профиль по умолчанию
  UserProfile _createDefaultProfile() {
    return UserProfile(
      id: 'current_user_id',
      displayName: 'Пользователь',
      username: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: 'user@example.com',
      bio: '',
      city: '',
      socialLinks: {},
      isPro: false,
      isVerified: false,
      followersCount: 0,
      followingCount: 0,
      postsCount: 0,
      ideasCount: 0,
      requestsCount: 0,
      isFollowing: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
