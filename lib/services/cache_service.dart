import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/cache_item.dart';

/// Сервис кэширования и оптимизации
class CacheService {
  factory CacheService() => _instance;
  CacheService._internal();
  static final CacheService _instance = CacheService._internal();

  final Map<String, CacheItem> _memoryCache = {};
  final Map<String, int> _accessCount = {};
  final Map<String, DateTime> _lastAccess = {};

  FlutterSecureStorage _prefs = const FlutterSecureStorage();
  Directory? _cacheDirectory;
  CacheConfig _config = const CacheConfig();

  int _hitCount = 0;
  int _missCount = 0;
  bool _isInitialized = false;

  /// Инициализация сервиса кэширования
  Future<void> initialize({CacheConfig? config}) async {
    if (_isInitialized) return;

    try {
      _config = config ?? _config;
      _prefs = const FlutterSecureStorage();
      _cacheDirectory = await getApplicationCacheDirectory();

      // Создаем директорию кэша
      final cacheDir = Directory('${_cacheDirectory!.path}/app_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      // Загружаем статистику
      await _loadStatistics();

      _isInitialized = true;

      if (kDebugMode) {
        print('Cache service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка инициализации сервиса кэширования: $e');
      }
    }
  }

  /// Получить элемент из кэша
  Future<T?> get<T>(String key, {T Function()? fromJson}) async {
    if (!_isInitialized) await initialize();
    if (!_config.enabled) return null;

    try {
      // Проверяем исключенные ключи
      if (_config.isKeyExcluded(key)) return null;

      // Проверяем память
      final memoryItem = _memoryCache[key];
      if (memoryItem != null && memoryItem.isValid) {
        _updateAccess(key);
        _hitCount++;
        return memoryItem.data as T;
      }

      // Проверяем диск
      final diskItem = await _getFromDisk<T>(key, fromJson);
      if (diskItem != null && diskItem.isValid) {
        // Загружаем в память
        _memoryCache[key] = diskItem;
        _updateAccess(key);
        _hitCount++;
        return diskItem.data;
      }

      _missCount++;
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения из кэша: $e');
      }
      _missCount++;
      return null;
    }
  }

  /// Сохранить элемент в кэш
  Future<void> set<T>(
    String key,
    T data, {
    Duration? ttl,
    CacheType type = CacheType.memory,
    Map<String, dynamic>? metadata,
    T Function(T)? toJson,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_config.enabled) return;

    try {
      // Проверяем исключенные ключи
      if (_config.isKeyExcluded(key)) return;

      final now = DateTime.now();
      final expiry = ttl ?? _config.getTTL(key);
      final expiresAt = now.add(expiry);

      // Вычисляем размер
      final size = _calculateSize(data, toJson);

      final cacheItem = CacheItem<T>(
        key: key,
        data: data,
        createdAt: now,
        expiresAt: expiresAt,
        type: type,
        metadata: metadata ?? {},
        size: size,
        lastAccessed: now,
      );

      // Сохраняем в память
      if (type == CacheType.memory ||
          type == CacheType.api ||
          type == CacheType.user) {
        _memoryCache[key] = cacheItem;
        _updateAccess(key);

        // Проверяем лимиты памяти
        await _checkMemoryLimits();
      }

      // Сохраняем на диск
      if (type == CacheType.disk ||
          type == CacheType.image ||
          type == CacheType.database) {
        await _saveToDisk(cacheItem, toJson);
      }

      if (_config.enableLogging) {
        if (kDebugMode) {
          print('Cached: $key (${cacheItem.formattedSize})');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка сохранения в кэш: $e');
      }
    }
  }

  /// Удалить элемент из кэша
  Future<void> remove(String key) async {
    if (!_isInitialized) await initialize();

    try {
      // Удаляем из памяти
      _memoryCache.remove(key);
      _accessCount.remove(key);
      _lastAccess.remove(key);

      // Удаляем с диска
      await _removeFromDisk(key);

      if (_config.enableLogging) {
        if (kDebugMode) {
          print('Removed from cache: $key');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка удаления из кэша: $e');
      }
    }
  }

  /// Очистить весь кэш
  Future<void> clear({CacheType? type}) async {
    if (!_isInitialized) await initialize();

    try {
      if (type == null) {
        // Очищаем все
        _memoryCache.clear();
        _accessCount.clear();
        _lastAccess.clear();
        await _clearDisk();
      } else {
        // Очищаем по типу
        final keysToRemove = _memoryCache.entries
            .where((entry) => entry.value.type == type)
            .map((entry) => entry.key)
            .toList();

        for (final key in keysToRemove) {
          await remove(key);
        }
      }

      if (_config.enableLogging) {
        if (kDebugMode) {
          print(
            'Cache cleared${type != null ? ' (type: ${type.displayName})' : ''}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка очистки кэша: $e');
      }
    }
  }

  /// Очистить истекшие элементы
  Future<void> clearExpired() async {
    if (!_isInitialized) await initialize();

    try {
      final expiredKeys = _memoryCache.entries
          .where((entry) => entry.value.isExpired)
          .map((entry) => entry.key)
          .toList();

      for (final key in expiredKeys) {
        await remove(key);
      }

      await _clearExpiredFromDisk();

      if (_config.enableLogging) {
        if (kDebugMode) {
          print('Expired items cleared: ${expiredKeys.length}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка очистки истекших элементов: $e');
      }
    }
  }

  /// Получить статистику кэша
  Future<CacheStatistics> getStatistics() async {
    if (!_isInitialized) await initialize();

    try {
      final allItems = <CacheItem>[];

      // Добавляем элементы из памяти
      allItems.addAll(_memoryCache.values);

      // Добавляем элементы с диска
      final diskItems = await _getAllFromDisk();
      allItems.addAll(diskItems);

      return CacheStatistics.fromCacheItems(
        'Общий кэш',
        allItems,
        _hitCount,
        _missCount,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения статистики кэша: $e');
      }
      return CacheStatistics.fromCacheItems('Общий кэш', [], 0, 0);
    }
  }

  /// Получить элемент с диска
  Future<CacheItem<T>?> _getFromDisk<T>(
    String key,
    T Function()? fromJson,
  ) async {
    try {
      final file = File('${_cacheDirectory!.path}/app_cache/$key.json');
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final data = json.decode(content);

      return CacheItem.fromMap(data, fromJson ?? () => data as T);
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка чтения с диска: $e');
      }
      return null;
    }
  }

  /// Сохранить элемент на диск
  Future<void> _saveToDisk<T>(CacheItem<T> item, T Function(T)? toJson) async {
    try {
      final file = File('${_cacheDirectory!.path}/app_cache/${item.key}.json');
      final data = item.toMap(toJson ?? (data) => data);
      final content = json.encode(data);

      await file.writeAsString(content);
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка сохранения на диск: $e');
      }
    }
  }

  /// Удалить элемент с диска
  Future<void> _removeFromDisk(String key) async {
    try {
      final file = File('${_cacheDirectory!.path}/app_cache/$key.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка удаления с диска: $e');
      }
    }
  }

  /// Очистить диск
  Future<void> _clearDisk() async {
    try {
      final cacheDir = Directory('${_cacheDirectory!.path}/app_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка очистки диска: $e');
      }
    }
  }

  /// Очистить истекшие элементы с диска
  Future<void> _clearExpiredFromDisk() async {
    try {
      final cacheDir = Directory('${_cacheDirectory!.path}/app_cache');
      if (!await cacheDir.exists()) return;

      final files = await cacheDir.list().toList();
      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final data = json.decode(content);
            final expiresAt = DateTime.parse(data['expiresAt']);

            if (DateTime.now().isAfter(expiresAt)) {
              await file.delete();
            }
          } catch (e) {
            // Удаляем поврежденные файлы
            await file.delete();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка очистки истекших элементов с диска: $e');
      }
    }
  }

  /// Получить все элементы с диска
  Future<List<CacheItem>> _getAllFromDisk() async {
    final items = <CacheItem>[];

    try {
      final cacheDir = Directory('${_cacheDirectory!.path}/app_cache');
      if (!await cacheDir.exists()) return items;

      final files = await cacheDir.list().toList();
      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final data = json.decode(content);
            final item = CacheItem.fromMap(data, () => data);
            items.add(item);
          } catch (e) {
            // Пропускаем поврежденные файлы
            continue;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения всех элементов с диска: $e');
      }
    }

    return items;
  }

  /// Вычислить размер данных
  int _calculateSize<T>(T data, T Function(T)? toJson) {
    try {
      if (data is String) return data.length;
      if (data is List) return data.length;
      if (data is Map) return data.length;

      final json = toJson?.call(data) ?? data;
      return json.toString().length;
    } catch (e) {
      return 0;
    }
  }

  /// Обновить информацию о доступе
  void _updateAccess(String key) {
    _accessCount[key] = (_accessCount[key] ?? 0) + 1;
    _lastAccess[key] = DateTime.now();
  }

  /// Проверить лимиты памяти
  Future<void> _checkMemoryLimits() async {
    // Проверяем количество элементов
    if (_memoryCache.length > _config.maxItems) {
      await _evictItems();
    }

    // Проверяем размер
    final totalSize =
        _memoryCache.values.fold(0, (sum, item) => sum + (item.size ?? 0));
    if (totalSize > _config.maxSize) {
      await _evictItems();
    }
  }

  /// Вытеснить элементы по политике
  Future<void> _evictItems() async {
    final items = _memoryCache.entries.toList();

    switch (_config.evictionPolicy) {
      case CacheEvictionPolicy.lru:
        items.sort(
          (a, b) => (a.value.lastAccessed ?? a.value.createdAt)
              .compareTo(b.value.lastAccessed ?? b.value.createdAt),
        );
        break;
      case CacheEvictionPolicy.lfu:
        items.sort(
          (a, b) =>
              (_accessCount[a.key] ?? 0).compareTo(_accessCount[b.key] ?? 0),
        );
        break;
      case CacheEvictionPolicy.fifo:
        items.sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));
        break;
      case CacheEvictionPolicy.ttl:
        items.sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));
        break;
      case CacheEvictionPolicy.random:
        items.shuffle();
        break;
    }

    // Удаляем 20% элементов
    final itemsToRemove = (items.length * 0.2).ceil();
    for (var i = 0; i < itemsToRemove && i < items.length; i++) {
      await remove(items[i].key);
    }
  }

  /// Загрузить статистику
  Future<void> _loadStatistics() async {
    try {
      _hitCount =
          int.tryParse(await _prefs.read(key: 'cache_hit_count') ?? "0") ??
              0 ??
              0;
      _missCount =
          int.tryParse(await _prefs.read(key: 'cache_miss_count') ?? "0") ??
              0 ??
              0;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки статистики: $e');
      }
    }
  }

  /// Сохранить статистику
  Future<void> _saveStatistics() async {
    try {
      await _prefs.write(key: 'cache_hit_count', value: _hitCount.toString());
      await _prefs.write(key: 'cache_miss_count', value: _missCount.toString());
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка сохранения статистики: $e');
      }
    }
  }

  /// Получить конфигурацию
  CacheConfig get config => _config;

  /// Обновить конфигурацию
  Future<void> updateConfig(CacheConfig newConfig) async {
    _config = newConfig;

    // Применяем новые лимиты
    await _checkMemoryLimits();

    if (_config.enableLogging) {
      if (kDebugMode) {
        print('Cache config updated: ${_config.toString()}');
      }
    }
  }

  /// Получить размер кэша
  Future<int> getCacheSize() async {
    if (!_isInitialized) await initialize();

    var totalSize = 0;

    // Размер в памяти
    totalSize +=
        _memoryCache.values.fold(0, (sum, item) => sum + (item.size ?? 0));

    // Размер на диске
    try {
      final cacheDir = Directory('${_cacheDirectory!.path}/app_cache');
      if (await cacheDir.exists()) {
        final files = await cacheDir.list().toList();
        for (final file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка вычисления размера кэша: $e');
      }
    }

    return totalSize;
  }

  /// Получить количество элементов в кэше
  int getItemCount() => _memoryCache.length;

  /// Проверить, существует ли ключ
  bool containsKey(String key) =>
      _memoryCache.containsKey(key) && _memoryCache[key]!.isValid;

  /// Получить все ключи
  List<String> getAllKeys() => _memoryCache.keys.toList();

  /// Закрыть сервис
  Future<void> dispose() async {
    await _saveStatistics();
    _memoryCache.clear();
    _accessCount.clear();
    _lastAccess.clear();
    _isInitialized = false;
  }
}
