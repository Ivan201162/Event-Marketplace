import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Загружает аватар пользователя
  Future<String> uploadUserAvatar(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('avatars/$userId.jpg');
      
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'type': 'avatar',
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ Avatar uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading avatar: $e');
      rethrow;
    }
  }

  /// Загружает изображение сторис
  Future<String> uploadStoryImage(String storyId, File imageFile) async {
    try {
      final ref = _storage.ref().child('stories/$storyId.jpg');
      
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'storyId': storyId,
            'type': 'story',
          },
        ),
      );
      
      final downloadUrl = await ref.getDownloadURL();
      
      debugPrint('✅ Story image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading story image: $e');
      rethrow;
    }
  }

  /// Загружает обложку профиля пользователя
  Future<String> uploadUserCover(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('users/$userId/cover.jpg');

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'type': 'cover',
          },
        ),
      );

      final downloadUrl = await ref.getDownloadURL();

      debugPrint('✅ User cover uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading user cover: $e');
      rethrow;
    }
  }

  /// Загружает изображение поста
  Future<String> uploadPostImage(String postId, File imageFile) async {
    try {
      final ref = _storage.ref().child('posts/$postId.jpg');
      
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'postId': postId,
            'type': 'post',
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ Post image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading post image: $e');
      rethrow;
    }
  }

  /// Загружает изображение идеи
  Future<String> uploadIdeaImage(String ideaId, File imageFile) async {
    try {
      final ref = _storage.ref().child('ideas/$ideaId.jpg');
      
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'ideaId': ideaId,
            'type': 'idea',
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ Idea image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading idea image: $e');
      rethrow;
    }
  }

  /// Удаляет файл по URL
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      debugPrint('✅ File deleted successfully: $url');
    } catch (e) {
      debugPrint('❌ Error deleting file: $e');
      rethrow;
    }
  }

  /// Получает размер файла
  Future<int> getFileSize(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      final metadata = await ref.getMetadata();
      return metadata.size ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting file size: $e');
      return 0;
    }
  }
}