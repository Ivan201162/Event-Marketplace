import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/services/upload_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Провайдер сервиса загрузки файлов
final uploadServiceProvider = Provider<UploadService>((ref) => UploadService());

/// Провайдер для проверки доступности загрузки файлов
final fileUploadAvailableProvider =
    Provider<bool>((ref) => FeatureFlags.fileUploadEnabled);

/// Провайдер для загрузки изображения
final imageUploadProvider =
    FutureProvider.family<UploadResult?, ImageSource>((ref, source) async {
  final uploadService = ref.read(uploadServiceProvider);
  if (!uploadService.isAvailable) return null;

  return uploadService.pickAndUploadImage(source: source);
});

/// Провайдер для загрузки видео
final videoUploadProvider =
    FutureProvider.family<UploadResult?, ImageSource>((ref, source) async {
  final uploadService = ref.read(uploadServiceProvider);
  if (!uploadService.isAvailable) return null;

  return uploadService.pickAndUploadVideo(source: source);
});

/// Провайдер для загрузки файла
final fileUploadProvider = FutureProvider.family<UploadResult?, List<String>?>((
  ref,
  allowedExtensions,
) async {
  final uploadService = ref.read(uploadServiceProvider);
  if (!uploadService.isAvailable) return null;

  return uploadService.pickAndUploadFile(allowedExtensions: allowedExtensions);
});

/// Провайдер для получения максимального размера файла
final maxFileSizeProvider = Provider.family<int, FileType>((ref, fileType) {
  final uploadService = ref.read(uploadServiceProvider);
  return uploadService.getMaxFileSize(fileType);
});

/// Провайдер для получения разрешенных расширений
final allowedExtensionsProvider =
    Provider.family<List<String>, FileType>((ref, fileType) {
  final uploadService = ref.read(uploadServiceProvider);
  return uploadService.getAllowedExtensions(fileType);
});
