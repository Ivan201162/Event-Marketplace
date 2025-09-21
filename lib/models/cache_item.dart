import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель элемента кэша
class CacheItem<T> {
  const CacheItem({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.expiresAt,
    required this.type,
    this.metadata = const {},
    this.size,
    this.etag,
    this.lastAccessed,
  });

  /// Создать из Map
  factory CacheItem.fromMap(
    Map<String, dynamic> data,
    T Function() fromJson,
  ) =>
      CacheItem<T>(
        key: data['key'] as String? ?? '',
        data: fromJson(),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        expiresAt: (data['expiresAt'] as Timestamp).toDate(),
        type: CacheType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => CacheType.memory,
        ),
        metadata: Map<String, dynamic>.from(data['metadata'] as Map<dynamic, dynamic>? ?? {}),
        size: data['size'] as int?,
        etag: data['etag'] as String?,
        lastAccessed: data['lastAccessed'] != null
            ? (data['lastAccessed'] as Timestamp).toDate()
            : null,
      );
  final String key;
  final T data;
  final DateTime createdAt;
  final DateTime expiresAt;
  final CacheType type;
  final Map<String, dynamic> metadata;
  final int? size;
  final String? etag;
  final DateTime? lastAccessed;

  /// Преобразовать в Map
  Map<String, dynamic> toMap(T Function(T) toJson) => {
        'key': key,
        'data': toJson(data),
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'type': type.toString().split('.').last,
        'metadata': metadata,
        'size': size,
        'etag': etag,
        'lastAccessed':
            lastAccessed != null ? Timestamp.fromDate(lastAccessed!) : null,
      };

  /// Создать копию с изменениями
  CacheItem<T> copyWith({
    String? key,
    T? data,
    DateTime? createdAt,
    DateTime? expiresAt,
    CacheType? type,
    Map<String, dynamic>? metadata,
    int? size,
    String? etag,
    DateTime? lastAccessed,
  }) =>
      CacheItem<T>(
        key: key ?? this.key,
        data: data ?? this.data,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        type: type ?? this.type,
        metadata: metadata ?? this.metadata,
        size: size ?? this.size,
        etag: etag ?? this.etag,
        lastAccessed: lastAccessed ?? this.lastAccessed,
      );

  /// Проверить, истек ли срок действия
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Проверить, действителен ли элемент
  bool get isValid => !isExpired;

  /// Получить время жизни
  Duration get age => DateTime.now().difference(createdAt);

  /// Получить оставшееся время
  Duration get timeToExpiry => expiresAt.difference(DateTime.now());

  /// Получить время с последнего доступа
  Duration? get timeSinceLastAccess {
    if (lastAccessed == null) return null;
    return DateTime.now().difference(lastAccessed!);
  }

  /// Получить приоритет кэша (для LRU)
  double get priority {
    final ageInHours = age.inHours.toDouble();
    final accessTime = lastAccessed ?? createdAt;
    final timeSinceAccess =
        DateTime.now().difference(accessTime).inHours.toDouble();

    // Приоритет основан на времени последнего доступа и возрасте
    return 1.0 / (1.0 + timeSinceAccess + ageInHours * 0.1);
  }

  /// Получить размер в читаемом формате
  String get formattedSize {
    if (size == null) return 'Неизвестно';

    const units = ['B', 'KB', 'MB', 'GB'];
    var sizeValue = size!;
    var unitIndex = 0;

    while (sizeValue >= 1024 && unitIndex < units.length - 1) {
      sizeValue ~/= 1024;
      unitIndex++;
    }

    return '$sizeValue ${units[unitIndex]}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheItem<T> &&
        other.key == key &&
        other.data == data &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt &&
        other.type == type &&
        other.metadata == metadata &&
        other.size == size &&
        other.etag == etag &&
        other.lastAccessed == lastAccessed;
  }

  @override
  int get hashCode => Object.hash(
        key,
        data,
        createdAt,
        expiresAt,
        type,
        metadata,
        size,
        etag,
        lastAccessed,
      );

  @override
  String toString() =>
      'CacheItem(key: $key, type: $type, expiresAt: $expiresAt)';
}

/// Типы кэша
enum CacheType {
  memory,
  disk,
  network,
  database,
  image,
  api,
  user,
  session,
}

/// Расширение для типов кэша
extension CacheTypeExtension on CacheType {
  String get displayName {
    switch (this) {
      case CacheType.memory:
        return 'Память';
      case CacheType.disk:
        return 'Диск';
      case CacheType.network:
        return 'Сеть';
      case CacheType.database:
        return 'База данных';
      case CacheType.image:
        return 'Изображение';
      case CacheType.api:
        return 'API';
      case CacheType.user:
        return 'Пользователь';
      case CacheType.session:
        return 'Сессия';
    }
  }

  String get description {
    switch (this) {
      case CacheType.memory:
        return 'Кэш в оперативной памяти';
      case CacheType.disk:
        return 'Кэш на диске';
      case CacheType.network:
        return 'Кэш сетевых запросов';
      case CacheType.database:
        return 'Кэш запросов к базе данных';
      case CacheType.image:
        return 'Кэш изображений';
      case CacheType.api:
        return 'Кэш API ответов';
      case CacheType.user:
        return 'Кэш пользовательских данных';
      case CacheType.session:
        return 'Кэш сессионных данных';
    }
  }

  Duration get defaultTTL {
    switch (this) {
      case CacheType.memory:
        return const Duration(minutes: 15);
      case CacheType.disk:
        return const Duration(hours: 1);
      case CacheType.network:
        return const Duration(minutes: 5);
      case CacheType.database:
        return const Duration(minutes: 30);
      case CacheType.image:
        return const Duration(days: 7);
      case CacheType.api:
        return const Duration(minutes: 10);
      case CacheType.user:
        return const Duration(hours: 2);
      case CacheType.session:
        return const Duration(hours: 24);
    }
  }

  int get maxSize {
    switch (this) {
      case CacheType.memory:
        return 50 * 1024 * 1024; // 50MB
      case CacheType.disk:
        return 500 * 1024 * 1024; // 500MB
      case CacheType.network:
        return 10 * 1024 * 1024; // 10MB
      case CacheType.database:
        return 100 * 1024 * 1024; // 100MB
      case CacheType.image:
        return 1 * 1024 * 1024 * 1024; // 1GB
      case CacheType.api:
        return 20 * 1024 * 1024; // 20MB
      case CacheType.user:
        return 5 * 1024 * 1024; // 5MB
      case CacheType.session:
        return 2 * 1024 * 1024; // 2MB
    }
  }
}

/// Модель статистики кэша
class CacheStatistics {
  const CacheStatistics({
    required this.cacheType,
    required this.totalItems,
    required this.validItems,
    required this.expiredItems,
    required this.totalSize,
    required this.hitCount,
    required this.missCount,
    required this.hitRate,
    required this.lastUpdated,
    required this.itemsByType,
    required this.averageAge,
    required this.averageTimeToExpiry,
  });

  /// Создать из списка элементов кэша
  factory CacheStatistics.fromCacheItems(
    String cacheType,
    List<CacheItem> items,
    int hitCount,
    int missCount,
  ) {
    final validItems = items.where((item) => item.isValid).length;
    final expiredItems = items.length - validItems;
    final totalSize = items.fold(0, (sum, item) => sum + (item.size ?? 0));

    final hitRate =
        (hitCount + missCount) > 0 ? hitCount / (hitCount + missCount) : 0.0;

    final averageAge = items.isNotEmpty
        ? Duration(
            milliseconds: items
                    .map((item) => item.age.inMilliseconds)
                    .reduce((a, b) => a + b) ~/
                items.length,
          )
        : Duration.zero;

    final averageTimeToExpiry = items.isNotEmpty
        ? Duration(
            milliseconds: items
                    .map((item) => item.timeToExpiry.inMilliseconds)
                    .reduce((a, b) => a + b) ~/
                items.length,
          )
        : Duration.zero;

    final itemsByType = <String, int>{};
    for (final item in items) {
      final type = item.type.displayName;
      itemsByType[type] = (itemsByType[type] ?? 0) + 1;
    }

    return CacheStatistics(
      cacheType: cacheType,
      totalItems: items.length,
      validItems: validItems,
      expiredItems: expiredItems,
      totalSize: totalSize,
      hitCount: hitCount,
      missCount: missCount,
      hitRate: hitRate,
      lastUpdated: DateTime.now(),
      itemsByType: itemsByType,
      averageAge: averageAge,
      averageTimeToExpiry: averageTimeToExpiry,
    );
  }
  final String cacheType;
  final int totalItems;
  final int validItems;
  final int expiredItems;
  final int totalSize;
  final int hitCount;
  final int missCount;
  final double hitRate;
  final DateTime lastUpdated;
  final Map<String, int> itemsByType;
  final Duration averageAge;
  final Duration averageTimeToExpiry;

  /// Получить общий размер в читаемом формате
  String get formattedTotalSize {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = totalSize;
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size ~/= 1024;
      unitIndex++;
    }

    return '$size ${units[unitIndex]}';
  }

  /// Получить эффективность кэша
  String get efficiency {
    if (hitRate >= 0.8) return 'Отличная';
    if (hitRate >= 0.6) return 'Хорошая';
    if (hitRate >= 0.4) return 'Удовлетворительная';
    return 'Плохая';
  }

  /// Проверить, нужна ли очистка
  bool get needsCleanup =>
      expiredItems > totalItems * 0.3 ||
      totalSize >
          CacheType.values
              .firstWhere((type) => type.displayName == cacheType)
              .maxSize;

  @override
  String toString() =>
      'CacheStatistics(cacheType: $cacheType, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, totalItems: $totalItems)';
}

/// Модель конфигурации кэша
class CacheConfig {
  const CacheConfig({
    this.enabled = true,
    this.defaultTTL = const Duration(hours: 1),
    this.maxSize = 100 * 1024 * 1024, // 100MB
    this.maxItems = 1000,
    this.enableCompression = false,
    this.enableEncryption = false,
    this.excludedKeys = const [],
    this.customTTL = const {},
    this.evictionPolicy = CacheEvictionPolicy.lru,
    this.enableStatistics = true,
    this.enableLogging = false,
  });

  /// Создать из Map
  factory CacheConfig.fromMap(Map<String, dynamic> data) => CacheConfig(
        enabled: data['enabled'] as bool? ?? true,
        defaultTTL: Duration(seconds: data['defaultTTL'] as int? ?? 3600),
        maxSize: data['maxSize'] as int? ?? 100 * 1024 * 1024,
        maxItems: data['maxItems'] as int? ?? 1000,
        enableCompression: data['enableCompression'] as bool? ?? false,
        enableEncryption: data['enableEncryption'] as bool? ?? false,
        excludedKeys: List<String>.from(data['excludedKeys'] as List<dynamic>? ?? []),
        customTTL: Map<String, Duration>.from(
          (data['customTTL'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(key, Duration(seconds: value as int)),
              ) ??
              {},
        ),
        evictionPolicy: CacheEvictionPolicy.values.firstWhere(
          (e) => e.toString().split('.').last == data['evictionPolicy'],
          orElse: () => CacheEvictionPolicy.lru,
        ),
        enableStatistics: data['enableStatistics'] as bool? ?? true,
        enableLogging: data['enableLogging'] as bool? ?? false,
      );
  final bool enabled;
  final Duration defaultTTL;
  final int maxSize;
  final int maxItems;
  final bool enableCompression;
  final bool enableEncryption;
  final List<String> excludedKeys;
  final Map<String, Duration> customTTL;
  final CacheEvictionPolicy evictionPolicy;
  final bool enableStatistics;
  final bool enableLogging;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'defaultTTL': defaultTTL.inSeconds,
        'maxSize': maxSize,
        'maxItems': maxItems,
        'enableCompression': enableCompression,
        'enableEncryption': enableEncryption,
        'excludedKeys': excludedKeys,
        'customTTL':
            customTTL.map((key, value) => MapEntry(key, value.inSeconds)),
        'evictionPolicy': evictionPolicy.toString().split('.').last,
        'enableStatistics': enableStatistics,
        'enableLogging': enableLogging,
      };

  /// Создать копию с изменениями
  CacheConfig copyWith({
    bool? enabled,
    Duration? defaultTTL,
    int? maxSize,
    int? maxItems,
    bool? enableCompression,
    bool? enableEncryption,
    List<String>? excludedKeys,
    Map<String, Duration>? customTTL,
    CacheEvictionPolicy? evictionPolicy,
    bool? enableStatistics,
    bool? enableLogging,
  }) =>
      CacheConfig(
        enabled: enabled ?? this.enabled,
        defaultTTL: defaultTTL ?? this.defaultTTL,
        maxSize: maxSize ?? this.maxSize,
        maxItems: maxItems ?? this.maxItems,
        enableCompression: enableCompression ?? this.enableCompression,
        enableEncryption: enableEncryption ?? this.enableEncryption,
        excludedKeys: excludedKeys ?? this.excludedKeys,
        customTTL: customTTL ?? this.customTTL,
        evictionPolicy: evictionPolicy ?? this.evictionPolicy,
        enableStatistics: enableStatistics ?? this.enableStatistics,
        enableLogging: enableLogging ?? this.enableLogging,
      );

  /// Получить TTL для ключа
  Duration getTTL(String key) => customTTL[key] ?? defaultTTL;

  /// Проверить, исключен ли ключ
  bool isKeyExcluded(String key) =>
      excludedKeys.any((excludedKey) => key.contains(excludedKey));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheConfig &&
        other.enabled == enabled &&
        other.defaultTTL == defaultTTL &&
        other.maxSize == maxSize &&
        other.maxItems == maxItems &&
        other.enableCompression == enableCompression &&
        other.enableEncryption == enableEncryption &&
        other.excludedKeys == excludedKeys &&
        other.customTTL == customTTL &&
        other.evictionPolicy == evictionPolicy &&
        other.enableStatistics == enableStatistics &&
        other.enableLogging == enableLogging;
  }

  @override
  int get hashCode => Object.hash(
        enabled,
        defaultTTL,
        maxSize,
        maxItems,
        enableCompression,
        enableEncryption,
        excludedKeys,
        customTTL,
        evictionPolicy,
        enableStatistics,
        enableLogging,
      );

  @override
  String toString() =>
      'CacheConfig(enabled: $enabled, maxSize: ${(maxSize / 1024 / 1024).toStringAsFixed(1)}MB, evictionPolicy: $evictionPolicy)';
}

/// Политики вытеснения кэша
enum CacheEvictionPolicy {
  lru, // Least Recently Used
  lfu, // Least Frequently Used
  fifo, // First In, First Out
  ttl, // Time To Live
  random, // Random
}

/// Расширение для политик вытеснения
extension CacheEvictionPolicyExtension on CacheEvictionPolicy {
  String get displayName {
    switch (this) {
      case CacheEvictionPolicy.lru:
        return 'LRU (Least Recently Used)';
      case CacheEvictionPolicy.lfu:
        return 'LFU (Least Frequently Used)';
      case CacheEvictionPolicy.fifo:
        return 'FIFO (First In, First Out)';
      case CacheEvictionPolicy.ttl:
        return 'TTL (Time To Live)';
      case CacheEvictionPolicy.random:
        return 'Random';
    }
  }

  String get description {
    switch (this) {
      case CacheEvictionPolicy.lru:
        return 'Удаляет наименее недавно использованные элементы';
      case CacheEvictionPolicy.lfu:
        return 'Удаляет наименее часто используемые элементы';
      case CacheEvictionPolicy.fifo:
        return 'Удаляет элементы в порядке поступления';
      case CacheEvictionPolicy.ttl:
        return 'Удаляет элементы по истечении времени жизни';
      case CacheEvictionPolicy.random:
        return 'Удаляет случайные элементы';
    }
  }
}
