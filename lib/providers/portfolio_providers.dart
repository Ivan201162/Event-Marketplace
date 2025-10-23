import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist_profile.dart';
import '../services/portfolio_service.dart';

/// Провайдер сервиса портфолио
final portfolioServiceProvider =
    Provider<PortfolioService>((ref) => PortfolioService());

/// Состояние загрузки портфолио
class PortfolioUploadState {
  const PortfolioUploadState({
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.errorMessage,
    this.uploadedItems = const [],
  });

  final bool isUploading;
  final double uploadProgress;
  final String? errorMessage;
  final List<PortfolioItem> uploadedItems;

  PortfolioUploadState copyWith({
    bool? isUploading,
    double? uploadProgress,
    String? errorMessage,
    List<PortfolioItem>? uploadedItems,
  }) =>
      PortfolioUploadState(
        isUploading: isUploading ?? this.isUploading,
        uploadProgress: uploadProgress ?? this.uploadProgress,
        errorMessage: errorMessage,
        uploadedItems: uploadedItems ?? this.uploadedItems,
      );
}

/// Провайдер состояния загрузки портфолио (мигрирован с StateNotifierProvider)
final portfolioUploadStateProvider =
    NotifierProvider<PortfolioUploadNotifier, PortfolioUploadState>(
  () => PortfolioUploadNotifier(),
);

/// Нотификатор для загрузки портфолио (мигрирован с StateNotifier)
class PortfolioUploadNotifier extends Notifier<PortfolioUploadState> {
  @override
  PortfolioUploadState build() {
    return const PortfolioUploadState();
  }

  PortfolioService get _portfolioService => ref.read(portfolioServiceProvider);

  /// Загрузить изображение
  Future<void> uploadImage({
    required String userId,
    required File imageFile,
    String? title,
    String? description,
  }) async {
    state = state.copyWith(isUploading: true);

    try {
      // Проверяем размер файла
      if (!_portfolioService.isFileSizeValid(imageFile)) {
        throw Exception('Размер файла превышает 50 МБ');
      }

      // Проверяем тип файла
      if (!_portfolioService.isSupportedFileType(imageFile.path)) {
        throw Exception('Неподдерживаемый тип файла');
      }

      final portfolioItem = await _portfolioService.uploadImage(
        userId: userId,
        imageFile: imageFile,
        title: title,
        description: description,
      );

      if (portfolioItem != null) {
        final newItems = List<PortfolioItem>.from(state.uploadedItems)
          ..add(portfolioItem);
        state = state.copyWith(isUploading: false, uploadedItems: newItems);
      } else {
        throw Exception('Не удалось загрузить изображение');
      }
    } on Exception catch (e) {
      state = state.copyWith(isUploading: false, errorMessage: e.toString());
    }
  }

  /// Загрузить видео
  Future<void> uploadVideo({
    required String userId,
    required File videoFile,
    String? title,
    String? description,
  }) async {
    state = state.copyWith(isUploading: true);

    try {
      // Проверяем размер файла
      if (!_portfolioService.isFileSizeValid(videoFile)) {
        throw Exception('Размер файла превышает 50 МБ');
      }

      // Проверяем тип файла
      if (!_portfolioService.isSupportedFileType(videoFile.path)) {
        throw Exception('Неподдерживаемый тип файла');
      }

      final portfolioItem = await _portfolioService.uploadVideo(
        userId: userId,
        videoFile: videoFile,
        title: title,
        description: description,
      );

      if (portfolioItem != null) {
        final newItems = List<PortfolioItem>.from(state.uploadedItems)
          ..add(portfolioItem);
        state = state.copyWith(isUploading: false, uploadedItems: newItems);
      } else {
        throw Exception('Не удалось загрузить видео');
      }
    } on Exception catch (e) {
      state = state.copyWith(isUploading: false, errorMessage: e.toString());
    }
  }

  /// Загрузить документ
  Future<void> uploadDocument({
    required String userId,
    required File documentFile,
    String? title,
    String? description,
  }) async {
    state = state.copyWith(isUploading: true);

    try {
      // Проверяем размер файла
      if (!_portfolioService.isFileSizeValid(documentFile)) {
        throw Exception('Размер файла превышает 50 МБ');
      }

      // Проверяем тип файла
      if (!_portfolioService.isSupportedFileType(documentFile.path)) {
        throw Exception('Неподдерживаемый тип файла');
      }

      final portfolioItem = await _portfolioService.uploadDocument(
        userId: userId,
        documentFile: documentFile,
        title: title,
        description: description,
      );

      if (portfolioItem != null) {
        final newItems = List<PortfolioItem>.from(state.uploadedItems)
          ..add(portfolioItem);
        state = state.copyWith(isUploading: false, uploadedItems: newItems);
      } else {
        throw Exception('Не удалось загрузить документ');
      }
    } on Exception catch (e) {
      state = state.copyWith(isUploading: false, errorMessage: e.toString());
    }
  }

  /// Удалить элемент портфолио
  Future<void> removePortfolioItem(String userId, String itemId) async {
    try {
      await _portfolioService.removePortfolioItem(userId, itemId);

      // Удаляем из локального списка
      final newItems =
          state.uploadedItems.where((item) => item.id != itemId).toList();
      state = state.copyWith(uploadedItems: newItems);
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Обновить элемент портфолио
  Future<void> updatePortfolioItem(
      String userId, PortfolioItem updatedItem) async {
    try {
      await _portfolioService.updatePortfolioItem(userId, updatedItem);

      // Обновляем в локальном списке
      final newItems = state.uploadedItems
          .map((item) => item.id == updatedItem.id ? updatedItem : item)
          .toList();
      state = state.copyWith(uploadedItems: newItems);
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith();
  }

  /// Очистить загруженные элементы
  void clearUploadedItems() {
    state = state.copyWith(uploadedItems: []);
  }
}

/// Провайдер для получения портфолио специалиста
final specialistPortfolioProvider =
    FutureProvider.family<List<PortfolioItem>, String>((
  ref,
  userId,
) async {
  final portfolioService = ref.read(portfolioServiceProvider);
  return portfolioService.getPortfolio(userId);
});

/// Провайдер для выбора изображения из галереи
final pickImageFromGalleryProvider = FutureProvider<File?>((ref) async {
  final portfolioService = ref.read(portfolioServiceProvider);
  return portfolioService.pickImageFromGallery();
});

/// Провайдер для съемки фото с камеры
final takePhotoWithCameraProvider = FutureProvider<File?>((ref) async {
  final portfolioService = ref.read(portfolioServiceProvider);
  return portfolioService.takePhotoWithCamera();
});

/// Провайдер для выбора видео из галереи
final pickVideoFromGalleryProvider = FutureProvider<File?>((ref) async {
  final portfolioService = ref.read(portfolioServiceProvider);
  return portfolioService.pickVideoFromGallery();
});

/// Провайдер для выбора файла
final pickFileProvider = FutureProvider<File?>((ref) async {
  final portfolioService = ref.read(portfolioServiceProvider);
  return portfolioService.pickFile();
});
