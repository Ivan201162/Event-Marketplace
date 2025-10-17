import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_archive.dart';
import '../services/archive_service.dart';

/// Провайдер сервиса архивов
final archiveServiceProvider = Provider<ArchiveService>((ref) => ArchiveService());

/// Провайдер архивов бронирования
final bookingArchivesProvider = StreamProvider.family<List<EventArchive>, String>((ref, bookingId) {
  final archiveService = ref.read(archiveServiceProvider);
  return archiveService.getArchivesByBookingStream(bookingId);
});

/// Провайдер статистики архивов
final archiveStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, bookingId) {
  final archiveService = ref.read(archiveServiceProvider);
  return archiveService.getArchiveStats(bookingId);
});

/// Состояние загрузки архива
class ArchiveUploadState {
  const ArchiveUploadState({
    this.isUploading = false,
    this.error,
    this.progress,
    this.uploadedArchive,
  });

  final bool isUploading;
  final String? error;
  final double? progress;
  final EventArchive? uploadedArchive;

  ArchiveUploadState copyWith({
    bool? isUploading,
    String? error,
    double? progress,
    EventArchive? uploadedArchive,
  }) =>
      ArchiveUploadState(
        isUploading: isUploading ?? this.isUploading,
        error: error,
        progress: progress,
        uploadedArchive: uploadedArchive ?? this.uploadedArchive,
      );
}

/// Провайдер состояния загрузки архива
final archiveUploadStateProvider = StateNotifierProvider<ArchiveUploadNotifier, ArchiveUploadState>(
  (ref) => ArchiveUploadNotifier(ref.read(archiveServiceProvider)),
);

/// Нотификатор для управления загрузкой архивов
class ArchiveUploadNotifier extends StateNotifier<ArchiveUploadState> {
  ArchiveUploadNotifier(this._archiveService) : super(const ArchiveUploadState());
  final ArchiveService _archiveService;

  /// Загрузить архив из галереи
  Future<void> uploadArchiveFromGallery({
    required String bookingId,
    required String uploadedBy,
    String? description,
  }) async {
    state = state.copyWith(isUploading: true);

    try {
      final archive = await _archiveService.uploadArchiveFromGallery(
        bookingId: bookingId,
        uploadedBy: uploadedBy,
        description: description,
      );

      if (archive != null) {
        state = state.copyWith(
          isUploading: false,
          uploadedArchive: archive,
        );
      } else {
        state = state.copyWith(
          isUploading: false,
          error: 'Файл не выбран',
        );
      }
    } on Exception catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
    }
  }

  /// Загрузить архив из камеры
  Future<void> uploadArchiveFromCamera({
    required String bookingId,
    required String uploadedBy,
    String? description,
  }) async {
    state = state.copyWith(isUploading: true);

    try {
      final archive = await _archiveService.uploadArchiveFromCamera(
        bookingId: bookingId,
        uploadedBy: uploadedBy,
        description: description,
      );

      if (archive != null) {
        state = state.copyWith(
          isUploading: false,
          uploadedArchive: archive,
        );
      } else {
        state = state.copyWith(
          isUploading: false,
          error: 'Файл не выбран',
        );
      }
    } on Exception catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
    }
  }

  /// Удалить архив
  Future<void> deleteArchive(String archiveId) async {
    state = state.copyWith(isUploading: true);
    try {
      await _archiveService.deleteArchive(archiveId);
      state = state.copyWith(isUploading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
    }
  }

  /// Обновить описание архива
  Future<void> updateArchiveDescription(
    String archiveId,
    String description,
  ) async {
    state = state.copyWith(isUploading: true);
    try {
      await _archiveService.updateArchiveDescription(archiveId, description);
      state = state.copyWith(isUploading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
    }
  }

  /// Сбросить состояние
  void reset() {
    state = const ArchiveUploadState();
  }
}
