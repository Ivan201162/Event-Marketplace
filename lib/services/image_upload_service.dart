import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Сервис для загрузки изображений в Firebase Storage
class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Загружает аватар пользователя
  Future<String> uploadUserAvatar(File imageFile, String userId) async {
    try {
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/$userId/avatars/$fileName');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'type': 'avatar',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('✅ Avatar uploaded successfully: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading avatar: $e');
      rethrow;
    }
  }

  /// Загружает изображение идеи
  Future<String> uploadIdeaImage(File imageFile, String ideaId) async {
    try {
      final fileName = 'idea_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('ideas/$ideaId/images/$fileName');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'ideaId': ideaId,
            'type': 'idea_image',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('✅ Idea image uploaded successfully: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading idea image: $e');
      rethrow;
    }
  }

  /// Загружает изображение поста
  Future<String> uploadPostImage(File imageFile, String postId) async {
    try {
      final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('posts/$postId/images/$fileName');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'postId': postId,
            'type': 'post_image',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('✅ Post image uploaded successfully: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading post image: $e');
      rethrow;
    }
  }

  /// Удаляет изображение
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('✅ Image deleted successfully: $imageUrl');
    } catch (e) {
      debugPrint('❌ Error deleting image: $e');
      rethrow;
    }
  }

  /// Получает URL изображения по пути
  Future<String> getImageUrl(String imagePath) async {
    try {
      final ref = _storage.ref().child(imagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ Error getting image URL: $e');
      rethrow;
    }
  }

  /// Загружает несколько изображений
  Future<List<String>> uploadMultipleImages(
    List<File> imageFiles,
    String folderPath,
  ) async {
    try {
      final downloadUrls = <String>[];

      for (var i = 0; i < imageFiles.length; i++) {
        final fileName =
            'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage.ref().child('$folderPath/$fileName');

        final uploadTask = await ref.putFile(
          imageFiles[i],
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'index': i.toString(),
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );

        final downloadUrl = await uploadTask.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      debugPrint('✅ ${downloadUrls.length} images uploaded successfully');
      return downloadUrls;
    } catch (e) {
      debugPrint('❌ Error uploading multiple images: $e');
      rethrow;
    }
  }
}
