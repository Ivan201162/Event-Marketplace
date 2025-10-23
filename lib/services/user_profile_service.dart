import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import '../models/user_profile_enhanced.dart';

/// Сервис для работы с расширенным профилем пользователя
class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Получить профиль пользователя
  Future<UserProfileEnhanced?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('user_profiles')
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserProfileEnhanced.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения профиля: $e');
      return null;
    }
  }

  /// Получить текущий профиль пользователя
  Future<UserProfileEnhanced?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUserProfile(user.uid);
  }

  /// Создать или обновить профиль
  Future<void> createOrUpdateProfile(UserProfileEnhanced profile) async {
    try {
      await _firestore
          .collection('user_profiles')
          .doc(profile.id)
          .set(profile.toMap(), SetOptions(merge: true));

      debugPrint('✅ Профиль сохранен: ${profile.id}');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения профиля: $e');
      rethrow;
    }
  }

  /// Обновить базовую информацию профиля
  Future<void> updateBasicInfo({
    required String userId,
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    String? city,
    String? region,
    String? phone,
    String? website,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (username != null) updateData['username'] = username;
      if (bio != null) updateData['bio'] = bio;
      if (city != null) updateData['city'] = city;
      if (region != null) updateData['region'] = region;
      if (phone != null) updateData['phone'] = phone;
      if (website != null) updateData['website'] = website;

      // Обновляем displayName если изменились имя или фамилия
      if (firstName != null || lastName != null) {
        final currentProfile = await getUserProfile(userId);
        final newFirstName = firstName ?? currentProfile?.firstName ?? '';
        final newLastName = lastName ?? currentProfile?.lastName ?? '';
        updateData['displayName'] = '$newFirstName $newLastName'.trim();
      }

      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .update(updateData);

      debugPrint('✅ Базовая информация профиля обновлена');
    } catch (e) {
      debugPrint('❌ Ошибка обновления базовой информации: $e');
      rethrow;
    }
  }

  /// Загрузить аватарку
  Future<String?> uploadAvatar(String userId, XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final fileName = 'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Обновляем URL аватарки в профиле
      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .update({
        'avatarUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Аватарка загружена: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки аватарки: $e');
      rethrow;
    }
  }

  /// Загрузить обложку профиля
  Future<String?> uploadCover(String userId, XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final fileName = 'covers/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Обновляем URL обложки в профиле
      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .update({
        'coverUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Обложка загружена: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки обложки: $e');
      rethrow;
    }
  }

  /// Загрузить видео-презентацию
  Future<String?> uploadVideoPresentation(String userId, XFile videoFile) async {
    try {
      final file = File(videoFile.path);
      
      // Сжимаем видео до 30 секунд
      final compressedVideo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (compressedVideo == null) {
        throw Exception('Ошибка сжатия видео');
      }

      final fileName = 'videos/$userId/${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(File(compressedVideo.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Обновляем URL видео в профиле
      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .update({
        'videoPresentation': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Видео-презентация загружена: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки видео-презентации: $e');
      rethrow;
    }
  }

  /// Добавить социальную ссылку
  Future<void> addSocialLink(String userId, SocialLink socialLink) async {
    try {
      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .update({
        'socialLinks': FieldValue.arrayUnion([socialLink.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Социальная ссылка добавлена');
    } catch (e) {
      debugPrint('❌ Ошибка добавления социальной ссылки: $e');
      rethrow;
    }
  }

  /// Удалить социальную ссылку
  Future<void> removeSocialLink(String userId, SocialLink socialLink) async {
    try {
      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .update({
        'socialLinks': FieldValue.arrayRemove([socialLink.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Социальная ссылка удалена');
    } catch (e) {
      debugPrint('❌ Ошибка удаления социальной ссылки: $e');
      rethrow;
    }
  }

  /// Обновить настройки видимости
  Future<void> updateVisibilitySettings(
    String userId,
    ProfileVisibilitySettings settings,
  ) async {
    try {
      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .update({
        'visibilitySettings': settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Настройки видимости обновлены');
    } catch (e) {
      debugPrint('❌ Ошибка обновления настроек видимости: $e');
      rethrow;
    }
  }

  /// Обновить настройки конфиденциальности
  Future<void> updatePrivacySettings(
    String userId,
    PrivacySettings settings,
  ) async {
    try {
      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .update({
        'privacySettings': settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Настройки конфиденциальности обновлены');
    } catch (e) {
      debugPrint('❌ Ошибка обновления настроек конфиденциальности: $e');
      rethrow;
    }
  }

  /// Обновить настройки уведомлений
  Future<void> updateNotificationSettings(
    String userId,
    NotificationSettings settings,
  ) async {
    try {
      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .update({
        'notificationSettings': settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Настройки уведомлений обновлены');
    } catch (e) {
      debugPrint('❌ Ошибка обновления настроек уведомлений: $e');
      rethrow;
    }
  }

  /// Обновить настройки внешнего вида
  Future<void> updateAppearanceSettings(
    String userId,
    AppearanceSettings settings,
  ) async {
    try {
      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .update({
        'appearanceSettings': settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Настройки внешнего вида обновлены');
    } catch (e) {
      debugPrint('❌ Ошибка обновления настроек внешнего вида: $e');
      rethrow;
    }
  }

  /// Обновить настройки безопасности
  Future<void> updateSecuritySettings(
    String userId,
    SecuritySettings settings,
  ) async {
    try {
      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .update({
        'securitySettings': settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Настройки безопасности обновлены');
    } catch (e) {
      debugPrint('❌ Ошибка обновления настроек безопасности: $e');
      rethrow;
    }
  }

  /// Переключить PRO-аккаунт
  Future<void> toggleProAccount(String userId, bool isPro) async {
    try {
      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .update({
        'isProAccount': isPro,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ PRO-аккаунт ${isPro ? 'включен' : 'отключен'}');
    } catch (e) {
      debugPrint('❌ Ошибка переключения PRO-аккаунта: $e');
      rethrow;
    }
  }

  /// Проверить доступность username
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final query = await _firestore
          .collection('user_profiles')
          .where('username', isEqualTo: username)
          .get();

      return query.docs.isEmpty;
    } catch (e) {
      debugPrint('❌ Ошибка проверки username: $e');
      return false;
    }
  }

  /// Получить предпросмотр профиля для других пользователей
  Future<Map<String, dynamic>?> getProfilePreview(String userId, String viewerId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return null;

      final visibilitySettings = profile.visibilitySettings;
      if (visibilitySettings == null) {
        // Если настройки не заданы, показываем базовую информацию
        return {
          'id': profile.id,
          'displayName': profile.displayName,
          'username': profile.username,
          'avatarUrl': profile.avatarUrl,
          'bio': profile.bio,
          'isProAccount': profile.isProAccount,
          'isVerified': profile.isVerified,
        };
      }

      final preview = <String, dynamic>{
        'id': profile.id,
        'displayName': profile.displayName,
        'username': profile.username,
        'avatarUrl': profile.avatarUrl,
        'isProAccount': profile.isProAccount,
        'isVerified': profile.isVerified,
      };

      // Добавляем поля в зависимости от настроек видимости
      if (visibilitySettings.showCity && profile.city != null) {
        preview['city'] = profile.city;
      }
      if (profile.bio != null) {
        preview['bio'] = profile.bio;
      }
      if (visibilitySettings.showPhone && profile.phone != null) {
        preview['phone'] = profile.phone;
      }
      if (visibilitySettings.showEmail && profile.email != null) {
        preview['email'] = profile.email;
      }

      return preview;
    } catch (e) {
      debugPrint('❌ Ошибка получения предпросмотра профиля: $e');
      return null;
    }
  }

  /// Отправить подтверждение изменений по email
  Future<void> sendEmailConfirmation(String userId, String changes) async {
    try {
      // TODO: Интеграция с email сервисом
      debugPrint('📧 Отправка подтверждения изменений: $changes');
    } catch (e) {
      debugPrint('❌ Ошибка отправки подтверждения: $e');
    }
  }

  /// Отправить подтверждение изменений по SMS
  Future<void> sendSMSConfirmation(String phone, String changes) async {
    try {
      // TODO: Интеграция с SMS сервисом
      debugPrint('📱 Отправка SMS подтверждения: $changes');
    } catch (e) {
      debugPrint('❌ Ошибка отправки SMS: $e');
    }
  }

  /// Создать профиль из базового пользователя
  Future<UserProfileEnhanced> createProfileFromUser(AppUser user) async {
    final profile = UserProfileEnhanced(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      avatarUrl: user.photoURL,
      createdAt: user.createdAt,
      updatedAt: DateTime.now(),
      lastLoginAt: user.lastLoginAt,
      isActive: user.isActive,
      role: user.role,
      visibilitySettings: const ProfileVisibilitySettings(),
      privacySettings: const PrivacySettings(),
      notificationSettings: const NotificationSettings(),
      appearanceSettings: const AppearanceSettings(),
      securitySettings: const SecuritySettings(),
    );

    await createOrUpdateProfile(profile);
    return profile;
  }
}