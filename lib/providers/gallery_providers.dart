import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gallery_item.dart';
import '../services/gallery_service.dart';

/// Провайдер сервиса галереи
final galleryServiceProvider =
    Provider<GalleryService>((ref) => GalleryService());

/// Провайдер галереи специалиста
final specialistGalleryProvider =
    FutureProvider.family<List<GalleryItem>, String>((ref, specialistId) async {
  final galleryService = ref.read(galleryServiceProvider);
  return galleryService.getSpecialistGallery(specialistId);
});

/// Провайдер избранной галереи специалиста
final specialistFeaturedGalleryProvider =
    FutureProvider.family<List<GalleryItem>, String>((ref, specialistId) async {
  final galleryService = ref.read(galleryServiceProvider);
  return galleryService.getFeaturedGallery(specialistId);
});

/// Провайдер для загрузки медиа
final uploadMediaProvider =
    FutureProvider.family<String, UploadMediaParams>((ref, params) async {
  final galleryService = ref.read(galleryServiceProvider);

  if (params.type == GalleryItemType.image) {
    return galleryService.uploadImage(
      specialistId: params.specialistId,
      imageFile: params.imageFile as dynamic,
      title: params.title,
      description: params.description,
      tags: params.tags,
      isFeatured: params.isFeatured,
    );
  } else {
    return galleryService.uploadVideo(
      specialistId: params.specialistId,
      videoFile: params.videoFile as dynamic,
      title: params.title,
      description: params.description,
      tags: params.tags,
      isFeatured: params.isFeatured,
    );
  }
});

/// Параметры для загрузки медиа
class UploadMediaParams {
  const UploadMediaParams({
    required this.specialistId,
    required this.type,
    required this.title,
    this.description,
    this.tags = const [],
    this.isFeatured = false,
    this.imageFile,
    this.videoFile,
  });

  final String specialistId;
  final GalleryItemType type;
  final String title;
  final String? description;
  final List<String> tags;
  final bool isFeatured;
  final dynamic imageFile; // XFile
  final dynamic videoFile; // XFile
}
