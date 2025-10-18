import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ СѓРїСЂР°РІР»РµРЅРёСЏ РєСЌС€РµРј РёР·РѕР±СЂР°Р¶РµРЅРёР№
final imageCacheProvider = Provider<ImageCacheManager>((ref) => ImageCacheManager());

/// РњРµРЅРµРґР¶РµСЂ РєСЌС€Р° РёР·РѕР±СЂР°Р¶РµРЅРёР№
class ImageCacheManager {
  static const int _maxCacheSize = 100; // РњР°РєСЃРёРјР°Р»СЊРЅРѕРµ РєРѕР»РёС‡РµСЃС‚РІРѕ РёР·РѕР±СЂР°Р¶РµРЅРёР№ РІ РєСЌС€Рµ
  static const int _maxCacheBytes = 50 * 1024 * 1024; // 50MB

  /// РРЅРёС†РёР°Р»РёР·Р°С†РёСЏ РєСЌС€Р° РёР·РѕР±СЂР°Р¶РµРЅРёР№
  void initializeCache() {
    // РќР°СЃС‚СЂРѕР№РєР° РєСЌС€Р° РёР·РѕР±СЂР°Р¶РµРЅРёР№
    PaintingBinding.instance.imageCache.maximumSize = _maxCacheSize;
    PaintingBinding.instance.imageCache.maximumSizeBytes = _maxCacheBytes;

    // РџСЂРµРґРІР°СЂРёС‚РµР»СЊРЅР°СЏ Р·Р°РіСЂСѓР·РєР° С‡Р°СЃС‚Рѕ РёСЃРїРѕР»СЊР·СѓРµРјС‹С… РёР·РѕР±СЂР°Р¶РµРЅРёР№
    _preloadCommonImages();
  }

  /// РџСЂРµРґРІР°СЂРёС‚РµР»СЊРЅР°СЏ Р·Р°РіСЂСѓР·РєР° РѕР±С‰РёС… РёР·РѕР±СЂР°Р¶РµРЅРёР№
  void _preloadCommonImages() {
    // Р—РґРµСЃСЊ РјРѕР¶РЅРѕ РґРѕР±Р°РІРёС‚СЊ РїСЂРµРґРІР°СЂРёС‚РµР»СЊРЅСѓСЋ Р·Р°РіСЂСѓР·РєСѓ
    // С‡Р°СЃС‚Рѕ РёСЃРїРѕР»СЊР·СѓРµРјС‹С… РёР·РѕР±СЂР°Р¶РµРЅРёР№ (Р»РѕРіРѕС‚РёРїС‹, РёРєРѕРЅРєРё Рё С‚.Рґ.)
  }

  /// РћС‡РёСЃС‚РєР° РєСЌС€Р° РёР·РѕР±СЂР°Р¶РµРЅРёР№
  void clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// РћС‡РёСЃС‚РєР° РєСЌС€Р° РїСЂРё РЅРµС…РІР°С‚РєРµ РїР°РјСЏС‚Рё
  void clearCacheIfNeeded() {
    final imageCache = PaintingBinding.instance.imageCache;
    if (imageCache.currentSizeBytes > _maxCacheBytes * 0.8) {
      clearCache();
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РёРЅС„РѕСЂРјР°С†РёРё Рѕ РєСЌС€Рµ
  Map<String, dynamic> getCacheInfo() {
    final imageCache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': imageCache.currentSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'maximumSize': imageCache.maximumSize,
      'maximumSizeBytes': imageCache.maximumSizeBytes,
    };
  }
}

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ РїСЂРµРґРІР°СЂРёС‚РµР»СЊРЅРѕР№ Р·Р°РіСЂСѓР·РєРё РёР·РѕР±СЂР°Р¶РµРЅРёР№
final imagePreloadProvider = FutureProvider.family<void, String>((ref, imageUrl) async {
  try {
    // РРЅРёС†РёР°Р»РёР·РёСЂСѓРµРј РєСЌС€
    ref.read(imageCacheProvider).initializeCache();

    // РџСЂРµРґРІР°СЂРёС‚РµР»СЊРЅР°СЏ Р·Р°РіСЂСѓР·РєР° РёР·РѕР±СЂР°Р¶РµРЅРёСЏ
    // РџСЂРёРјРµС‡Р°РЅРёРµ: precacheImage С‚СЂРµР±СѓРµС‚ BuildContext, РєРѕС‚РѕСЂС‹Р№ РЅРµРґРѕСЃС‚СѓРїРµРЅ РІ РїСЂРѕРІР°Р№РґРµСЂРµ
    // Р’РјРµСЃС‚Рѕ СЌС‚РѕРіРѕ РјС‹ РїСЂРѕСЃС‚Рѕ РёРЅРёС†РёР°Р»РёР·РёСЂСѓРµРј РєСЌС€
    debugPrint('Image cache initialized for: $imageUrl');
  } on Exception catch (e) {
    // РРіРЅРѕСЂРёСЂСѓРµРј РѕС€РёР±РєРё РїСЂРµРґРІР°СЂРёС‚РµР»СЊРЅРѕР№ Р·Р°РіСЂСѓР·РєРё
    debugPrint('Failed to initialize cache for image: $imageUrl, error: $e');
  }
});

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ СѓРїСЂР°РІР»РµРЅРёСЏ РїР°РјСЏС‚СЊСЋ
final memoryManagerProvider = Provider<MemoryManager>((ref) => MemoryManager());

/// РњРµРЅРµРґР¶РµСЂ РїР°РјСЏС‚Рё
class MemoryManager {
  /// РџСЂРѕРІРµСЂРєР° РёСЃРїРѕР»СЊР·РѕРІР°РЅРёСЏ РїР°РјСЏС‚Рё Рё РѕС‡РёСЃС‚РєР° РїСЂРё РЅРµРѕР±С…РѕРґРёРјРѕСЃС‚Рё
  void checkMemoryUsage() {
    final imageCache = PaintingBinding.instance.imageCache;

    // Р•СЃР»Рё РєСЌС€ РёР·РѕР±СЂР°Р¶РµРЅРёР№ Р·Р°РЅРёРјР°РµС‚ Р±РѕР»СЊС€Рµ 80% РѕС‚ РјР°РєСЃРёРјР°Р»СЊРЅРѕРіРѕ СЂР°Р·РјРµСЂР°
    if (imageCache.currentSizeBytes > imageCache.maximumSizeBytes * 0.8) {
      // РћС‡РёС‰Р°РµРј СЃС‚Р°СЂС‹Рµ РёР·РѕР±СЂР°Р¶РµРЅРёСЏ
      imageCache.clearLiveImages();
    }
  }

  /// РџСЂРёРЅСѓРґРёС‚РµР»СЊРЅР°СЏ РѕС‡РёСЃС‚РєР° РїР°РјСЏС‚Рё
  void forceCleanup() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}

