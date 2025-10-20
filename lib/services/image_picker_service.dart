import 'package:flutter/foundation.dart';

/// Заглушка для ImagePicker
class ImagePicker {
  static ImagePicker get instance => ImagePicker();

  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    if (kDebugMode) {
      debugPrint('ImagePicker.pickImage not implemented - using mock');
    }
    // Возвращаем null для заглушки
    return null;
  }

  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    if (kDebugMode) {
      debugPrint('ImagePicker.pickMultiImage not implemented - using mock');
    }
    return [];
  }
}

/// Заглушка для XFile
class XFile {
  const XFile(
    this.path, {
    this.name = '',
    this.length,
    this.mimeType,
  });
  final String path;
  final String name;
  final int? length;
  final String? mimeType;

  Future<String> readAsString() async => '';

  Future<List<int>> readAsBytes() async => [];
}

/// Источник изображения
enum ImageSource {
  camera,
  gallery,
}
