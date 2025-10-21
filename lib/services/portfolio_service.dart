import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/specialist_profile.dart';

/// Сервис для работы с портфолио специалиста
class PortfolioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Загрузить изображение в портфолио
  Future<PortfolioItem?> uploadImage({
    required String userId,
    required File imageFile,
    String? title,
    String? description,
  }) async {
    try {
      // Генерируем уникальное имя файла
      final fileName = 'portfolio_images/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Загружаем файл в Firebase Storage
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Создаем элемент портфолио
      final portfolioItem = PortfolioItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'photo',
        url: downloadUrl,
        title: title,
        description: description,
        createdAt: DateTime.now(),
      );

      // Сохраняем в профиле специалиста
      await _addPortfolioItemToProfile(userId, portfolioItem);

      return portfolioItem;
    } on Exception catch (e) {
      debugPrint('Ошибка загрузки изображения: $e');
      return null;
    }
  }

  /// Загрузить видео в портфолио
  Future<PortfolioItem?> uploadVideo({
    required String userId,
    required File videoFile,
    String? title,
    String? description,
  }) async {
    try {
      // Генерируем уникальное имя файла
      final fileName = 'portfolio_videos/${userId}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Загружаем файл в Firebase Storage
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(videoFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Создаем элемент портфолио
      final portfolioItem = PortfolioItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'video',
        url: downloadUrl,
        title: title,
        description: description,
        createdAt: DateTime.now(),
      );

      // Сохраняем в профиле специалиста
      await _addPortfolioItemToProfile(userId, portfolioItem);

      return portfolioItem;
    } on Exception catch (e) {
      debugPrint('Ошибка загрузки видео: $e');
      return null;
    }
  }

  /// Загрузить документ в портфолио
  Future<PortfolioItem?> uploadDocument({
    required String userId,
    required File documentFile,
    String? title,
    String? description,
  }) async {
    try {
      // Получаем расширение файла
      final extension = documentFile.path.split('.').last;

      // Генерируем уникальное имя файла
      final fileName =
          'portfolio_documents/${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Загружаем файл в Firebase Storage
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(documentFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Создаем элемент портфолио
      final portfolioItem = PortfolioItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'document',
        url: downloadUrl,
        title: title,
        description: description,
        createdAt: DateTime.now(),
      );

      // Сохраняем в профиле специалиста
      await _addPortfolioItemToProfile(userId, portfolioItem);

      return portfolioItem;
    } on Exception catch (e) {
      debugPrint('Ошибка загрузки документа: $e');
      return null;
    }
  }

  /// Добавить элемент портфолио в профиль специалиста
  Future<void> _addPortfolioItemToProfile(String userId, PortfolioItem item) async {
    try {
      final profileRef = _firestore.collection('specialist_profiles').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(profileRef);

        if (snapshot.exists) {
          final data = snapshot.data()!;
          final portfolio = (data['portfolio'] as List<dynamic>? ?? [])
              .map((e) => PortfolioItem.fromMap(Map<String, dynamic>.from(e)))
              .toList();

          portfolio.add(item);

          transaction.update(profileRef, {
            'portfolio': portfolio.map((e) => e.toMap()).toList(),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      });
    } on Exception catch (e) {
      debugPrint('Ошибка сохранения элемента портфолио: $e');
      throw Exception('Не удалось сохранить элемент портфолио');
    }
  }

  /// Удалить элемент портфолио
  Future<void> removePortfolioItem(String userId, String itemId) async {
    try {
      final profileRef = _firestore.collection('specialist_profiles').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(profileRef);

        if (snapshot.exists) {
          final data = snapshot.data()!;
          final portfolio = (data['portfolio'] as List<dynamic>? ?? [])
              .map((e) => PortfolioItem.fromMap(Map<String, dynamic>.from(e)))
              .toList();

          // Удаляем элемент из списка
          portfolio.removeWhere((item) => item.id == itemId);

          transaction.update(profileRef, {
            'portfolio': portfolio.map((e) => e.toMap()).toList(),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      });
    } on Exception catch (e) {
      debugPrint('Ошибка удаления элемента портфолио: $e');
      throw Exception('Не удалось удалить элемент портфолио');
    }
  }

  /// Обновить элемент портфолио
  Future<void> updatePortfolioItem(String userId, PortfolioItem updatedItem) async {
    try {
      final profileRef = _firestore.collection('specialist_profiles').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(profileRef);

        if (snapshot.exists) {
          final data = snapshot.data()!;
          final portfolio = (data['portfolio'] as List<dynamic>? ?? [])
              .map((e) => PortfolioItem.fromMap(Map<String, dynamic>.from(e)))
              .toList();

          // Находим и обновляем элемент
          final index = portfolio.indexWhere((item) => item.id == updatedItem.id);
          if (index != -1) {
            portfolio[index] = updatedItem;
          }

          transaction.update(profileRef, {
            'portfolio': portfolio.map((e) => e.toMap()).toList(),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      });
    } on Exception catch (e) {
      debugPrint('Ошибка обновления элемента портфолио: $e');
      throw Exception('Не удалось обновить элемент портфолио');
    }
  }

  /// Получить портфолио специалиста
  Future<List<PortfolioItem>> getPortfolio(String userId) async {
    try {
      final doc = await _firestore.collection('specialist_profiles').doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        final portfolio = (data['portfolio'] as List<dynamic>? ?? [])
            .map((e) => PortfolioItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();

        // Сортируем по дате создания (новые сначала)
        portfolio.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return portfolio;
      }

      return [];
    } on Exception catch (e) {
      debugPrint('Ошибка получения портфолио: $e');
      return [];
    }
  }

  /// Выбрать изображение из галереи
  Future<File?> pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      return image != null ? File(image.path) : null;
    } on Exception catch (e) {
      debugPrint('Ошибка выбора изображения: $e');
      return null;
    }
  }

  /// Сделать фото с камеры
  Future<File?> takePhotoWithCamera() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      return image != null ? File(image.path) : null;
    } on Exception catch (e) {
      debugPrint('Ошибка съемки фото: $e');
      return null;
    }
  }

  /// Выбрать видео из галереи
  Future<File?> pickVideoFromGallery() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      return video != null ? File(video.path) : null;
    } on Exception catch (e) {
      debugPrint('Ошибка выбора видео: $e');
      return null;
    }
  }

  /// Выбрать файл
  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        return File(result.files.first.path!);
      }

      return null;
    } on Exception catch (e) {
      debugPrint('Ошибка выбора файла: $e');
      return null;
    }
  }

  /// Получить размер файла в читаемом формате
  String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Проверить, поддерживается ли тип файла
  bool isSupportedFileType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    const supportedExtensions = [
      'jpg', 'jpeg', 'png', 'gif', 'webp', // Изображения
      'mp4', 'avi', 'mov', 'wmv', 'flv', // Видео
      'pdf', 'doc', 'docx', 'txt', 'rtf', // Документы
    ];
    return supportedExtensions.contains(extension);
  }

  /// Получить максимальный размер файла для загрузки (в байтах)
  int get maxFileSize => 50 * 1024 * 1024; // 50 MB

  /// Проверить размер файла
  bool isFileSizeValid(File file) => file.lengthSync() <= maxFileSize;
}
