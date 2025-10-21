import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/storage_guard.dart';

/// Сервис для работы с файловым хранилищем
class StorageService {
  final FirebaseStorage? _storage = getStorage();

  FirebaseStorage get _s {
    final storage = _storage;
    if (storage == null) {
      throw Exception('Firebase Storage is not available on web.');
    }
    return storage;
  }

  /// Загрузить PDF договора в Firebase Storage
  Future<String> uploadContractPdf(String contractId, Uint8List pdfBytes) async {
    try {
      final ref = _s.ref().child('contracts').child('$contractId.pdf');

      final uploadTask = ref.putData(
        pdfBytes,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'type': 'contract',
            'contractId': contractId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки PDF договора: $e');
    }
  }

  /// Сохранить строку в локальное хранилище
  Future<void> setString(String key, String value) async {
    // Реализация для локального хранилища
  }

  /// Получить строку из локального хранилища
  Future<String?> getString(String key) async {
    // Реализация для локального хранилища
    return null;
  }

  /// Сохранить число в локальное хранилище
  Future<void> setInt(String key, int value) async {
    // Реализация для локального хранилища
  }

  /// Получить число из локального хранилища
  Future<int?> getInt(String key) async {
    // Реализация для локального хранилища
    return null;
  }

  /// Удалить значение из локального хранилища
  Future<void> remove(String key) async {
    // Реализация для локального хранилища
  }

  /// Загрузить изображение профиля
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final ref = _storage
          .ref()
          .child('profile_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки изображения профиля: $e');
    }
  }

  /// Загрузить PDF акта выполненных работ в Firebase Storage
  Future<String> uploadWorkActPdf(String workActId, Uint8List pdfBytes) async {
    try {
      final ref = _storage.ref().child('work_acts').child('$workActId.pdf');

      final uploadTask = ref.putData(
        pdfBytes,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'type': 'work_act',
            'workActId': workActId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки PDF акта: $e');
    }
  }

  /// Загрузить PDF счета в Firebase Storage
  Future<String> uploadInvoicePdf(String invoiceId, Uint8List pdfBytes) async {
    try {
      final ref = _s.ref().child('invoices').child('$invoiceId.pdf');

      final uploadTask = ref.putData(
        pdfBytes,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'type': 'invoice',
            'invoiceId': invoiceId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки PDF счета: $e');
    }
  }

  /// Скачать файл по URL
  Future<void> downloadFile(String downloadUrl, String fileName) async {
    try {
      // Запрашиваем разрешение на запись
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Нет разрешения на запись файлов');
      }

      // Получаем директорию для загрузок
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Не удалось получить директорию для загрузок');
      }

      final downloadsDir = Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final file = File('${downloadsDir.path}/$fileName');

      // Скачиваем файл
      final ref = _s.refFromURL(downloadUrl);
      final data = await ref.getData();

      if (data != null) {
        await file.writeAsBytes(data);
      } else {
        throw Exception('Не удалось получить данные файла');
      }
    } on Exception catch (e) {
      throw Exception('Ошибка скачивания файла: $e');
    }
  }

  /// Получить URL файла по пути
  Future<String> getFileUrl(String path) async {
    try {
      final ref = _s.ref().child(path);
      return await ref.getDownloadURL();
    } on Exception catch (e) {
      throw Exception('Ошибка получения URL файла: $e');
    }
  }

  /// Удалить файл из Firebase Storage
  Future<void> deleteFile(String path) async {
    try {
      final ref = _s.ref().child(path);
      await ref.delete();
    } on Exception catch (e) {
      throw Exception('Ошибка удаления файла: $e');
    }
  }

  /// Получить список файлов в папке
  Future<List<Reference>> listFiles(String path) async {
    try {
      final ref = _s.ref().child(path);
      final result = await ref.listAll();
      return result.items;
    } on Exception catch (e) {
      throw Exception('Ошибка получения списка файлов: $e');
    }
  }

  /// Получить метаданные файла
  Future<FullMetadata> getFileMetadata(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getMetadata();
    } on Exception catch (e) {
      throw Exception('Ошибка получения метаданных файла: $e');
    }
  }

  /// Загрузить изображение
  Future<String> uploadImage(String path, Uint8List imageBytes, String fileName) async {
    try {
      final ref = _s.ref().child(path).child(fileName);

      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'type': 'image', 'uploadedAt': DateTime.now().toIso8601String()},
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки изображения: $e');
    }
  }

  /// Загрузить документ
  Future<String> uploadDocument(
    String path,
    Uint8List documentBytes,
    String fileName,
    String contentType,
  ) async {
    try {
      final ref = _s.ref().child(path).child(fileName);

      final uploadTask = ref.putData(
        documentBytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {'type': 'document', 'uploadedAt': DateTime.now().toIso8601String()},
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки документа: $e');
    }
  }

  /// Получить размер файла в читаемом формате
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Проверить существование файла
  Future<bool> fileExists(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.getMetadata();
      return true;
    } on Exception {
      return false;
    }
  }

  /// Получить прогресс загрузки
  Stream<TaskSnapshot> getUploadProgress(String path) {
    final ref = _s.ref().child(path);
    return ref.putData(Uint8List(0)).snapshotEvents;
  }
}
