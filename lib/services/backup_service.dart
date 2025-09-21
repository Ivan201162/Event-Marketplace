import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/backup.dart';

/// Сервис бэкапов и восстановления
class BackupService {
  factory BackupService() => _instance;
  BackupService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  static final BackupService _instance = BackupService._internal();

  /// Создать бэкап
  Future<String> createBackup({
    required String name,
    required String description,
    required BackupType type,
    List<String>? collections,
    Map<String, dynamic>? filters,
    String? createdBy,
  }) async {
    try {
      final backupId = _uuid.v4();
      final now = DateTime.now();

      // Определяем коллекции для бэкапа
      final backupCollections = collections ?? _getDefaultCollections(type);

      final backup = Backup(
        id: backupId,
        name: name,
        description: description,
        type: type,
        collections: backupCollections,
        filters: filters ?? {},
        createdBy: createdBy,
        createdAt: now,
      );

      await _firestore.collection('backups').doc(backupId).set(backup.toMap());

      // Запускаем создание бэкапа в фоне
      _createBackupFile(backupId);

      return backupId;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка создания бэкапа: $e');
      }
      rethrow;
    }
  }

  /// Создать файл бэкапа
  Future<void> _createBackupFile(String backupId) async {
    try {
      // Обновляем статус на "в процессе"
      await _updateBackupStatus(backupId, BackupStatus.inProgress);

      // Получаем данные бэкапа
      final backupDoc =
          await _firestore.collection('backups').doc(backupId).get();
      if (!backupDoc.exists) return;

      final backup = Backup.fromDocument(backupDoc);

      // Собираем данные из коллекций
      final backupData = <String, dynamic>{};
      var totalDocuments = 0;

      for (final collectionName in backup.collections) {
        try {
          final collectionData =
              await _exportCollection(collectionName, backup.filters);
          backupData[collectionName] = collectionData;
          totalDocuments += collectionData.length;
        } catch (e) {
          if (kDebugMode) {
            print('Ошибка экспорта коллекции $collectionName: $e');
          }
        }
      }

      // Создаем JSON файл
      final jsonData = {
        'backup': {
          'id': backup.id,
          'name': backup.name,
          'description': backup.description,
          'type': backup.type.toString(),
          'createdAt': backup.createdAt.toIso8601String(),
          'createdBy': backup.createdBy,
          'collections': backup.collections,
          'filters': backup.filters,
          'totalDocuments': totalDocuments,
        },
        'data': backupData,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      final bytes = utf8.encode(jsonString);

      // Загружаем файл в Firebase Storage
      final fileName =
          'backup_${backupId}_${DateTime.now().millisecondsSinceEpoch}.json';
      final ref = _storage.ref().child('backups/$fileName');

      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'application/json',
          customMetadata: {
            'backupId': backupId,
            'createdAt': backup.createdAt.toIso8601String(),
            'type': backup.type.toString(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Обновляем статус на "завершено"
      await _updateBackupStatus(
        backupId,
        BackupStatus.completed,
        fileUrl: downloadUrl,
        fileSize: bytes.length,
        metadata: {
          'totalDocuments': totalDocuments,
          'fileName': fileName,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка создания файла бэкапа: $e');
      }

      // Обновляем статус на "ошибка"
      await _updateBackupStatus(
        backupId,
        BackupStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Экспортировать коллекцию
  Future<List<Map<String, dynamic>>> _exportCollection(
    String collectionName,
    Map<String, dynamic> filters,
  ) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(collectionName);

      // Применяем фильтры
      for (final entry in filters.entries) {
        if (entry.value is List) {
          query = query.where(entry.key, whereIn: entry.value);
        } else {
          query = query.where(entry.key, isEqualTo: entry.value);
        }
      }

      final snapshot = await query.get();
      final documents = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['_id'] = doc.id;
        data['_collection'] = collectionName;
        documents.add(data);
      }

      return documents;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка экспорта коллекции $collectionName: $e');
      }
      return [];
    }
  }

  /// Обновить статус бэкапа
  Future<void> _updateBackupStatus(
    String backupId,
    BackupStatus status, {
    String? fileUrl,
    int? fileSize,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (status == BackupStatus.completed) {
        updateData['completedAt'] = Timestamp.fromDate(DateTime.now());
        if (fileUrl != null) updateData['fileUrl'] = fileUrl;
        if (fileSize != null) updateData['fileSize'] = fileSize;
        if (metadata != null) updateData['metadata'] = metadata;
      } else if (status == BackupStatus.failed && errorMessage != null) {
        updateData['errorMessage'] = errorMessage;
      }

      await _firestore.collection('backups').doc(backupId).update(updateData);
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка обновления статуса бэкапа: $e');
      }
    }
  }

  /// Получить список бэкапов
  Future<List<Backup>> getBackups({
    String? createdBy,
    BackupType? type,
    BackupStatus? status,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('backups');

      if (createdBy != null) {
        query = query.where('createdBy', isEqualTo: createdBy);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }
      if (status != null) {
        query =
            query.where('status', isEqualTo: status.toString().split('.').last);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).limit(limit).get();

      return snapshot.docs.map(Backup.fromDocument).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения списка бэкапов: $e');
      }
      return [];
    }
  }

  /// Получить бэкап по ID
  Future<Backup?> getBackup(String backupId) async {
    try {
      final doc = await _firestore.collection('backups').doc(backupId).get();
      if (doc.exists) {
        return Backup.fromDocument(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения бэкапа: $e');
      }
      return null;
    }
  }

  /// Скачать бэкап
  Future<String> downloadBackup(String backupId) async {
    try {
      final backup = await getBackup(backupId);
      if (backup == null || !backup.isCompleted) {
        throw Exception('Бэкап не найден или не завершен');
      }

      // TODO: Реализовать скачивание файла
      return backup.fileUrl!;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка скачивания бэкапа: $e');
      }
      rethrow;
    }
  }

  /// Восстановить данные из бэкапа
  Future<String> restoreFromBackup({
    required String backupId,
    required String name,
    required String description,
    required RestoreType type,
    List<String>? collections,
    Map<String, dynamic>? options,
    String? createdBy,
  }) async {
    try {
      final restoreId = _uuid.v4();
      final now = DateTime.now();

      final restore = Restore(
        id: restoreId,
        backupId: backupId,
        name: name,
        description: description,
        type: type,
        collections: collections ?? [],
        options: options ?? {},
        createdBy: createdBy,
        createdAt: now,
      );

      await _firestore
          .collection('restores')
          .doc(restoreId)
          .set(restore.toMap());

      // Запускаем восстановление в фоне
      _restoreFromBackup(restoreId);

      return restoreId;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка создания восстановления: $e');
      }
      rethrow;
    }
  }

  /// Восстановить данные из бэкапа
  Future<void> _restoreFromBackup(String restoreId) async {
    try {
      // Обновляем статус на "в процессе"
      await _updateRestoreStatus(restoreId, RestoreStatus.inProgress);

      // Получаем данные восстановления
      final restoreDoc =
          await _firestore.collection('restores').doc(restoreId).get();
      if (!restoreDoc.exists) return;

      final restore = Restore.fromDocument(restoreDoc);

      // Получаем бэкап
      final backup = await getBackup(restore.backupId);
      if (backup == null || !backup.isCompleted) {
        throw Exception('Бэкап не найден или не завершен');
      }

      // Скачиваем и парсим файл бэкапа
      final backupData = await _downloadAndParseBackup(backup.fileUrl!);

      // Восстанавливаем данные
      await _importBackupData(backupData, restore);

      // Обновляем статус на "завершено"
      await _updateRestoreStatus(restoreId, RestoreStatus.completed);
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка восстановления из бэкапа: $e');
      }

      // Обновляем статус на "ошибка"
      await _updateRestoreStatus(
        restoreId,
        RestoreStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Скачать и распарсить файл бэкапа
  Future<Map<String, dynamic>> _downloadAndParseBackup(String fileUrl) async {
    try {
      // TODO: Реализовать скачивание и парсинг JSON файла
      // Пока возвращаем пустые данные
      return {};
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка скачивания и парсинга бэкапа: $e');
      }
      rethrow;
    }
  }

  /// Импортировать данные бэкапа
  Future<void> _importBackupData(
    Map<String, dynamic> backupData,
    Restore restore,
  ) async {
    try {
      final data = backupData['data'] as Map<String, dynamic>?;
      if (data == null) return;

      final collectionsToRestore = restore.collections.isEmpty
          ? data.keys.toList()
          : restore.collections;

      for (final collectionName in collectionsToRestore) {
        final collectionData = data[collectionName] as List<dynamic>?;
        if (collectionData == null) continue;

        await _importCollection(
          collectionName,
          collectionData,
          restore.options,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка импорта данных бэкапа: $e');
      }
      rethrow;
    }
  }

  /// Импортировать коллекцию
  Future<void> _importCollection(
    String collectionName,
    List<dynamic> documents,
    Map<String, dynamic> options,
  ) async {
    try {
      final batch = _firestore.batch();
      final overwrite = options['overwrite'] as bool? ?? false;

      for (final docData in documents) {
        final data = docData as Map<String, dynamic>;
        final docId = data['_id'] as String?;

        if (docId != null) {
          // Удаляем служебные поля
          data.remove('_id');
          data.remove('_collection');

          final docRef = _firestore.collection(collectionName).doc(docId);

          if (overwrite) {
            batch.set(docRef, data);
          } else {
            batch.set(docRef, data, SetOptions(merge: true));
          }
        }
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка импорта коллекции $collectionName: $e');
      }
      rethrow;
    }
  }

  /// Обновить статус восстановления
  Future<void> _updateRestoreStatus(
    String restoreId,
    RestoreStatus status, {
    String? errorMessage,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (status == RestoreStatus.completed) {
        updateData['completedAt'] = Timestamp.fromDate(DateTime.now());
      } else if (status == RestoreStatus.failed && errorMessage != null) {
        updateData['errorMessage'] = errorMessage;
      }

      await _firestore.collection('restores').doc(restoreId).update(updateData);
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка обновления статуса восстановления: $e');
      }
    }
  }

  /// Получить список восстановлений
  Future<List<Restore>> getRestores({
    String? createdBy,
    RestoreType? type,
    RestoreStatus? status,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('restores');

      if (createdBy != null) {
        query = query.where('createdBy', isEqualTo: createdBy);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }
      if (status != null) {
        query =
            query.where('status', isEqualTo: status.toString().split('.').last);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).limit(limit).get();

      return snapshot.docs.map(Restore.fromDocument).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения списка восстановлений: $e');
      }
      return [];
    }
  }

  /// Получить статистику бэкапов
  Future<BackupStatistics> getBackupStatistics() async {
    try {
      final snapshot = await _firestore.collection('backups').get();

      var totalBackups = 0;
      var successfulBackups = 0;
      var failedBackups = 0;
      var totalSize = 0;
      var lastBackup = DateTime.fromMillisecondsSinceEpoch(0);
      final backupsByType = <String, int>{};
      final backupsByStatus = <String, int>{};

      for (final doc in snapshot.docs) {
        final backup = Backup.fromDocument(doc);
        totalBackups++;

        switch (backup.status) {
          case BackupStatus.completed:
            successfulBackups++;
            if (backup.fileSize != null) {
              totalSize += backup.fileSize!;
            }
            if (backup.completedAt != null &&
                backup.completedAt!.isAfter(lastBackup)) {
              lastBackup = backup.completedAt!;
            }
            break;
          case BackupStatus.failed:
            failedBackups++;
            break;
          default:
            break;
        }

        backupsByType[backup.type.name] =
            (backupsByType[backup.type.name] ?? 0) + 1;
        backupsByStatus[backup.status.name] =
            (backupsByStatus[backup.status.name] ?? 0) + 1;
      }

      return BackupStatistics(
        totalBackups: totalBackups,
        successfulBackups: successfulBackups,
        failedBackups: failedBackups,
        totalSize: totalSize,
        lastBackup: lastBackup,
        backupsByType: backupsByType,
        backupsByStatus: backupsByStatus,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения статистики бэкапов: $e');
      }
      return BackupStatistics(
        totalBackups: 0,
        successfulBackups: 0,
        failedBackups: 0,
        totalSize: 0,
        lastBackup: DateTime.now(),
        backupsByType: const {},
        backupsByStatus: const {},
      );
    }
  }

  /// Получить коллекции по умолчанию для типа бэкапа
  List<String> _getDefaultCollections(BackupType type) {
    switch (type) {
      case BackupType.full:
        return [
          'users',
          'specialists',
          'bookings',
          'payments',
          'reviews',
          'chats',
          'messages',
          'notifications',
          'analyticsEvents',
          'appErrors',
        ];
      case BackupType.incremental:
        return [
          'bookings',
          'payments',
          'messages',
          'notifications',
        ];
      case BackupType.differential:
        return [
          'users',
          'specialists',
          'bookings',
          'payments',
        ];
      case BackupType.selective:
        return [
          'users',
          'specialists',
        ];
    }
  }

  /// Удалить бэкап
  Future<void> deleteBackup(String backupId) async {
    try {
      final backup = await getBackup(backupId);
      if (backup == null) return;

      // Удаляем файл из Storage
      if (backup.fileUrl != null) {
        try {
          final ref = _storage.refFromURL(backup.fileUrl!);
          await ref.delete();
        } catch (e) {
          if (kDebugMode) {
            print('Ошибка удаления файла бэкапа: $e');
          }
        }
      }

      // Удаляем запись из Firestore
      await _firestore.collection('backups').doc(backupId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка удаления бэкапа: $e');
      }
      rethrow;
    }
  }

  /// Очистить старые бэкапы
  Future<void> cleanupOldBackups({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _firestore
          .collection('backups')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      for (final doc in snapshot.docs) {
        await deleteBackup(doc.id);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка очистки старых бэкапов: $e');
      }
    }
  }
}
