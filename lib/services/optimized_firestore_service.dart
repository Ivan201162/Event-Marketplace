import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Оптимизированный сервис для работы с Firestore
class OptimizedFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Кэш для часто используемых запросов
  static final Map<String, QuerySnapshot> _queryCache = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);
  static final Map<String, DateTime> _cacheTimestamps = {};

  /// Получение документа с кэшированием
  static Future<DocumentSnapshot?> getDocument(
    String collection,
    String documentId, {
    bool useCache = true,
  }) async {
    final cacheKey = '$collection/$documentId';

    if (useCache && _queryCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiration) {
        // Возвращаем кэшированный результат
        return _queryCache[cacheKey]?.docs.first;
      }
    }

    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();

      if (useCache) {
        _queryCache[cacheKey] = QuerySnapshot.fromDocuments([doc]);
        _cacheTimestamps[cacheKey] = DateTime.now();
      }

      return doc;
    } catch (e) {
      print('Error getting document: $e');
      return null;
    }
  }

  /// Получение коллекции с пагинацией и кэшированием
  static Future<QuerySnapshot> getCollection(
    String collection, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    List<QueryOrder>? orderBy,
    List<QueryFilter>? where,
    bool useCache = true,
  }) async {
    final cacheKey =
        _generateCacheKey(collection, limit, startAfter, orderBy, where);

    if (useCache && _queryCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiration) {
        return _queryCache[cacheKey]!;
      }
    }

    try {
      Query query = _firestore.collection(collection);

      // Применяем фильтры
      if (where != null) {
        for (final filter in where) {
          query = query.where(filter.field, isEqualTo: filter.value);
        }
      }

      // Применяем сортировку
      if (orderBy != null) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      // Применяем пагинацию
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();

      if (useCache) {
        _queryCache[cacheKey] = snapshot;
        _cacheTimestamps[cacheKey] = DateTime.now();
      }

      return snapshot;
    } catch (e) {
      print('Error getting collection: $e');
      rethrow;
    }
  }

  /// Получение коллекции в реальном времени с оптимизацией
  static Stream<QuerySnapshot> getCollectionStream(
    String collection, {
    int limit = 20,
    List<QueryOrder>? orderBy,
    List<QueryFilter>? where,
  }) {
    Query query = _firestore.collection(collection);

    // Применяем фильтры
    if (where != null) {
      for (final filter in where) {
        query = query.where(filter.field, isEqualTo: filter.value);
      }
    }

    // Применяем сортировку
    if (orderBy != null) {
      for (final order in orderBy) {
        query = query.orderBy(order.field, descending: order.descending);
      }
    }

    query = query.limit(limit);

    return query.snapshots();
  }

  /// Создание документа с оптимизацией
  static Future<String?> createDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      final docRef = await _firestore.collection(collection).add(data);

      // Очищаем кэш для этой коллекции
      _clearCollectionCache(collection);

      return docRef.id;
    } catch (e) {
      print('Error creating document: $e');
      return null;
    }
  }

  /// Обновление документа с оптимизацией
  static Future<bool> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);

      // Очищаем кэш для этого документа
      _clearDocumentCache(collection, documentId);

      return true;
    } catch (e) {
      print('Error updating document: $e');
      return false;
    }
  }

  /// Удаление документа с оптимизацией
  static Future<bool> deleteDocument(
    String collection,
    String documentId,
  ) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();

      // Очищаем кэш для этого документа
      _clearDocumentCache(collection, documentId);

      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }

  /// Очистка кэша для коллекции
  static void _clearCollectionCache(String collection) {
    _queryCache.removeWhere((key, value) => key.startsWith(collection));
    _cacheTimestamps.removeWhere((key, value) => key.startsWith(collection));
  }

  /// Очистка кэша для документа
  static void _clearDocumentCache(String collection, String documentId) {
    final cacheKey = '$collection/$documentId';
    _queryCache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
  }

  /// Генерация ключа кэша
  static String _generateCacheKey(
    String collection,
    int limit,
    DocumentSnapshot? startAfter,
    List<QueryOrder>? orderBy,
    List<QueryFilter>? where,
  ) {
    final buffer = StringBuffer();
    buffer.write(collection);
    buffer.write('_limit_$limit');

    if (startAfter != null) {
      buffer.write('_start_${startAfter.id}');
    }

    if (orderBy != null) {
      for (final order in orderBy) {
        buffer.write('_order_${order.field}_${order.descending}');
      }
    }

    if (where != null) {
      for (final filter in where) {
        buffer.write('_where_${filter.field}_${filter.value}');
      }
    }

    return buffer.toString();
  }

  /// Очистка всего кэша
  static void clearAllCache() {
    _queryCache.clear();
    _cacheTimestamps.clear();
  }

  /// Получение статистики кэша
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _queryCache.length,
      'cacheKeys': _queryCache.keys.toList(),
    };
  }
}

/// Класс для фильтров запросов
class QueryFilter {
  const QueryFilter({
    required this.field,
    required this.value,
  });

  final String field;
  final dynamic value;
}

/// Класс для сортировки запросов
class QueryOrder {
  const QueryOrder({
    required this.field,
    this.descending = false,
  });

  final String field;
  final bool descending;
}

/// Провайдер для оптимизированного сервиса Firestore
final optimizedFirestoreServiceProvider =
    Provider<OptimizedFirestoreService>((ref) {
  return OptimizedFirestoreService();
});
