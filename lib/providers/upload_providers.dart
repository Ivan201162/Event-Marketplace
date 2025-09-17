import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/upload_service.dart';
import '../core/feature_flags.dart';

/// Провайдер сервиса загрузки файлов
final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService();
});

/// Провайдер для проверки доступности загрузки файлов
final fileUploadAvailableProvider = Provider<bool>((ref) {
  return FeatureFlags.fileUploadEnabled;
});

/// Провайдер для загрузки изображения
final imageUploadProvider =
    FutureProvider.family<UploadResult?, ImageSource>((ref, source) async {
  final uploadService = ref.read(uploadServiceProvider);
  if (!uploadService.isAvailable) return null;

  return await uploadService.pickAndUploadImage(source: source);
});

/// Провайдер для загрузки видео
final videoUploadProvider =
    FutureProvider.family<UploadResult?, ImageSource>((ref, source) async {
  final uploadService = ref.read(uploadServiceProvider);
  if (!uploadService.isAvailable) return null;

  return await uploadService.pickAndUploadVideo(source: source);
});

/// Провайдер для загрузки файла
final fileUploadProvider = FutureProvider.family<UploadResult?, List<String>?>(
    (ref, allowedExtensions) async {
  final uploadService = ref.read(uploadServiceProvider);
  if (!uploadService.isAvailable) return null;

  return await uploadService.pickAndUploadFile(
      allowedExtensions: allowedExtensions);
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
