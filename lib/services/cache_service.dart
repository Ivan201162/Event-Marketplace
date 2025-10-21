import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Сервис для кэширования данных и изображений
class CacheService {
  factory CacheService() => _instance;
  CacheService._internal();
  static final CacheService _instance = CacheService._internal();

  static const String _specialistsBox = 'specialists';
  static const String _postsBox = 'posts';
  static const String _ideasBox = 'ideas';
  static const String _storiesBox = 'stories';
  static const String _userDataBox = 'user_data';

  late Box _specialistsCache;
  late Box _postsCache;
  late Box _ideasCache;
  late Box _storiesCache;
  late Box _userDataCache;

  // Cache manager для изображений
  static final CacheManager _imageCacheManager = DefaultCacheManager();

  /// Инициализация кэша
  Future<void> initialize() async {
    await Hive.initFlutter();

    _specialistsCache = await Hive.openBox(_specialistsBox);
    _postsCache = await Hive.openBox(_postsBox);
    _ideasCache = await Hive.openBox(_ideasBox);
    _storiesCache = await Hive.openBox(_storiesBox);
    _userDataCache = await Hive.openBox(_userDataBox);
  }

  /// Кэширование списка специалистов
  Future<void> cacheSpecialists(List<Map<String, dynamic>> specialists) async {
    try {
      await _specialistsCache.put('specialists_list', specialists);
      await _specialistsCache.put(
        'last_updated',
        DateTime.now().millisecondsSinceEpoch,
      );
    } on Exception catch (e) {
      debugPrint('Ошибка кэширования специалистов: $e');
    }
  }

  /// Получение кэшированных специалистов
  List<Map<String, dynamic>>? getCachedSpecialists() {
    try {
      final data = _specialistsCache.get('specialists_list');
      if (data != null) {
        return List<Map<String, dynamic>>.from(data);
      }
    } on Exception catch (e) {
      debugPrint('Ошибка получения кэшированных специалистов: $e');
    }
    return null;
  }

  /// Проверка актуальности кэша специалистов
  bool isSpecialistsCacheValid({Duration maxAge = const Duration(hours: 1)}) {
    try {
      final lastUpdated = _specialistsCache.get('last_updated');
      if (lastUpdated != null) {
        final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdated);
        return DateTime.now().difference(lastUpdateTime) < maxAge;
      }
    } on Exception catch (e) {
      debugPrint('Ошибка проверки актуальности кэша: $e');
    }
    return false;
  }

  /// Кэширование постов
  Future<void> cachePosts(List<Map<String, dynamic>> posts) async {
    try {
      await _postsCache.put('posts_list', posts);
      await _postsCache.put(
        'last_updated',
        DateTime.now().millisecondsSinceEpoch,
      );
    } on Exception catch (e) {
      debugPrint('Ошибка кэширования постов: $e');
    }
  }

  /// Получение кэшированных постов
  List<Map<String, dynamic>>? getCachedPosts() {
    try {
      final data = _postsCache.get('posts_list');
      if (data != null) {
        return List<Map<String, dynamic>>.from(data);
      }
    } on Exception catch (e) {
      debugPrint('Ошибка получения кэшированных постов: $e');
    }
    return null;
  }

  /// Кэширование идей
  Future<void> cacheIdeas(List<Map<String, dynamic>> ideas) async {
    try {
      await _ideasCache.put('ideas_list', ideas);
      await _ideasCache.put(
        'last_updated',
        DateTime.now().millisecondsSinceEpoch,
      );
    } on Exception catch (e) {
      debugPrint('Ошибка кэширования идей: $e');
    }
  }

  /// Получение кэшированных идей
  List<Map<String, dynamic>>? getCachedIdeas() {
    try {
      final data = _ideasCache.get('ideas_list');
      if (data != null) {
        return List<Map<String, dynamic>>.from(data);
      }
    } on Exception catch (e) {
      debugPrint('Ошибка получения кэшированных идей: $e');
    }
    return null;
  }

  /// Кэширование историй
  Future<void> cacheStories(List<Map<String, dynamic>> stories) async {
    try {
      await _storiesCache.put('stories_list', stories);
      await _storiesCache.put(
        'last_updated',
        DateTime.now().millisecondsSinceEpoch,
      );
    } on Exception catch (e) {
      debugPrint('Ошибка кэширования историй: $e');
    }
  }

  /// Получение кэшированных историй
  List<Map<String, dynamic>>? getCachedStories() {
    try {
      final data = _storiesCache.get('stories_list');
      if (data != null) {
        return List<Map<String, dynamic>>.from(data);
      }
    } on Exception catch (e) {
      debugPrint('Ошибка получения кэшированных историй: $e');
    }
    return null;
  }

  /// Кэширование пользовательских данных
  Future<void> cacheUserData(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      await _userDataCache.put(userId, userData);
    } on Exception catch (e) {
      debugPrint('Ошибка кэширования пользовательских данных: $e');
    }
  }

  /// Получение кэшированных пользовательских данных
  Map<String, dynamic>? getCachedUserData(String userId) {
    try {
      final data = _userDataCache.get(userId);
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
    } on Exception catch (e) {
      debugPrint('Ошибка получения кэшированных пользовательских данных: $e');
    }
    return null;
  }

  /// Предзагрузка изображения
  Future<void> preloadImage(String imageUrl) async {
    try {
      await _imageCacheManager.getSingleFile(imageUrl);
    } on Exception catch (e) {
      debugPrint('Ошибка предзагрузки изображения: $e');
    }
  }

  /// Предзагрузка списка изображений
  Future<void> preloadImages(List<String> imageUrls) async {
    try {
      await Future.wait(
        imageUrls.map(_imageCacheManager.getSingleFile),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка предзагрузки изображений: $e');
    }
  }

  /// Очистка кэша изображений
  Future<void> clearImageCache() async {
    try {
      await _imageCacheManager.emptyCache();
    } on Exception catch (e) {
      debugPrint('Ошибка очистки кэша изображений: $e');
    }
  }

  /// Очистка всех кэшей
  Future<void> clearAllCaches() async {
    try {
      await _specialistsCache.clear();
      await _postsCache.clear();
      await _ideasCache.clear();
      await _storiesCache.clear();
      await _userDataCache.clear();
      await _imageCacheManager.emptyCache();
    } on Exception catch (e) {
      debugPrint('Ошибка очистки кэшей: $e');
    }
  }

  /// Получение размера кэша
  Future<int> getCacheSize() async {
    try {
      var totalSize = 0;
      totalSize += _specialistsCache.length;
      totalSize += _postsCache.length;
      totalSize += _ideasCache.length;
      totalSize += _storiesCache.length;
      totalSize += _userDataCache.length;
      return totalSize;
    } on Exception catch (e) {
      debugPrint('Ошибка получения размера кэша: $e');
      return 0;
    }
  }

  /// Закрытие всех кэшей
  Future<void> dispose() async {
    try {
      await _specialistsCache.close();
      await _postsCache.close();
      await _ideasCache.close();
      await _storiesCache.close();
      await _userDataCache.close();
    } on Exception catch (e) {
      debugPrint('Ошибка закрытия кэшей: $e');
    }
  }
}

/// Провайдер для CacheService
final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());
