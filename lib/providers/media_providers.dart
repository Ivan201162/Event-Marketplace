import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/media_item.dart';
import '../services/media_service.dart';

/// Провайдер сервиса медиафайлов
final mediaServiceProvider = Provider<MediaService>((ref) => MediaService());

/// Провайдер медиафайлов пользователя
final userMediaProvider = FutureProvider.family<List<MediaItem>, String>((ref, userId) async {
  final mediaService = ref.read(mediaServiceProvider);
  return mediaService.getMediaForUser(userId);
});

/// Провайдер фото пользователя
final userPhotosProvider = FutureProvider.family<List<MediaItem>, String>((ref, userId) async {
  final mediaService = ref.read(mediaServiceProvider);
  return mediaService.getMediaByType(userId, MediaType.photo);
});

/// Провайдер видео пользователя
final userVideosProvider = FutureProvider.family<List<MediaItem>, String>((ref, userId) async {
  final mediaService = ref.read(mediaServiceProvider);
  return mediaService.getMediaByType(userId, MediaType.video);
});

/// Провайдер статистики медиафайлов пользователя
final userMediaStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, userId) async {
  final mediaService = ref.read(mediaServiceProvider);
  return mediaService.getMediaStats(userId);
});

/// Провайдер состояния загрузки медиафайлов
class MediaUploadState {
  const MediaUploadState({
    this.isUploading = false,
    this.progress = 0.0,
    this.error,
    this.uploadedItem,
  });
  final bool isUploading;
  final double progress;
  final String? error;
  final MediaItem? uploadedItem;

  MediaUploadState copyWith({
    bool? isUploading,
    double? progress,
    String? error,
    MediaItem? uploadedItem,
  }) => MediaUploadState(
    isUploading: isUploading ?? this.isUploading,
    progress: progress ?? this.progress,
    error: error,
    uploadedItem: uploadedItem ?? this.uploadedItem,
  );
}

/// Провайдер состояния загрузки медиафайлов (мигрирован с StateNotifierProvider)
final mediaUploadStateProvider = NotifierProvider<MediaUploadNotifier, MediaUploadState>(
  () => MediaUploadNotifier(),
);

/// Нотификатор для управления загрузкой медиафайлов (мигрирован с StateNotifier)
class MediaUploadNotifier extends Notifier<MediaUploadState> {
  @override
  MediaUploadState build() {
    return const MediaUploadState();
  }

  MediaService get _mediaService => ref.read(mediaServiceProvider);

  /// Загрузить фото из галереи
  Future<void> uploadPhotoFromGallery({
    required String userId,
    String? title,
    String? description,
  }) async {
    state = state.copyWith(isUploading: true);

    try {
      final mediaItem = await _mediaService.uploadMediaFromGallery(
        userId: userId,
        type: MediaType.photo,
        title: title,
        description: description,
      );

      if (mediaItem != null) {
        state = state.copyWith(isUploading: false, uploadedItem: mediaItem);
      } else {
        state = state.copyWith(isUploading: false, error: 'Файл не выбран');
      }
    } on Exception catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  /// Загрузить видео из галереи
  Future<void> uploadVideoFromGallery({
    required String userId,
    String? title,
    String? description,
  }) async {
    state = state.copyWith(isUploading: true);

    try {
      final mediaItem = await _mediaService.uploadMediaFromGallery(
        userId: userId,
        type: MediaType.video,
        title: title,
        description: description,
      );

      if (mediaItem != null) {
        state = state.copyWith(isUploading: false, uploadedItem: mediaItem);
      } else {
        state = state.copyWith(isUploading: false, error: 'Файл не выбран');
      }
    } on Exception catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  /// Загрузить фото из камеры
  Future<void> uploadPhotoFromCamera({
    required String userId,
    String? title,
    String? description,
  }) async {
    state = state.copyWith(isUploading: true);

    try {
      final mediaItem = await _mediaService.uploadMediaFromCamera(
        userId: userId,
        type: MediaType.photo,
        title: title,
        description: description,
      );

      if (mediaItem != null) {
        state = state.copyWith(isUploading: false, uploadedItem: mediaItem);
      } else {
        state = state.copyWith(isUploading: false, error: 'Файл не снят');
      }
    } on Exception catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  /// Загрузить видео из камеры
  Future<void> uploadVideoFromCamera({
    required String userId,
    String? title,
    String? description,
  }) async {
    state = state.copyWith(isUploading: true);

    try {
      final mediaItem = await _mediaService.uploadMediaFromCamera(
        userId: userId,
        type: MediaType.video,
        title: title,
        description: description,
      );

      if (mediaItem != null) {
        state = state.copyWith(isUploading: false, uploadedItem: mediaItem);
      } else {
        state = state.copyWith(isUploading: false, error: 'Файл не снят');
      }
    } on Exception catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  /// Удалить медиафайл
  Future<void> deleteMedia(String mediaId) async {
    try {
      await _mediaService.deleteMedia(mediaId);
      // Сбрасываем состояние после успешного удаления
      state = const MediaUploadState();
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Обновить информацию о медиафайле
  Future<void> updateMedia(String mediaId, {String? title, String? description}) async {
    try {
      await _mediaService.updateMedia(mediaId, title: title, description: description);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Сбросить состояние
  void reset() {
    state = const MediaUploadState();
  }
}

/// Провайдер для выбора источника медиафайлов
final mediaSourceProvider = StateProvider<ImageSource?>((ref) => null);

/// Провайдер для выбора типа медиафайла
final mediaTypeProvider = StateProvider<MediaType?>((ref) => null);
