import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/advertisement.dart';
import '../services/advertising_service.dart';

/// Провайдер сервиса рекламы
final advertisingServiceProvider =
    Provider<AdvertisingService>((ref) => AdvertisingService());

/// Провайдер рекламных объявлений
final advertisementsProvider =
    FutureProvider.family<List<Advertisement>, AdvertisementFilters>(
        (ref, filters) async {
  final service = ref.read(advertisingServiceProvider);
  return service.getAdvertisements(
    status: filters.status,
    type: filters.type,
    advertiserId: filters.advertiserId,
    limit: filters.limit,
  );
});

/// Провайдер рекламы для показа
final displayAdvertisementsProvider =
    FutureProvider.family<List<Advertisement>, DisplayAdParams>(
        (ref, params) async {
  final service = ref.read(advertisingServiceProvider);
  return service.getAdvertisementsForDisplay(
    userId: params.userId,
    context: params.context,
    limit: params.limit,
  );
});

/// Провайдер статистики рекламы
final advertisementStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, adId) async {
  final service = ref.read(advertisingServiceProvider);
  return service.getAdvertisementStats(adId);
});

/// Провайдер общей статистики рекламы
final overallAdStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(advertisingServiceProvider);
  return service.getOverallStats();
});

/// Параметры для фильтрации рекламы
class AdvertisementFilters {
  const AdvertisementFilters({
    this.status,
    this.type,
    this.advertiserId,
    this.limit = 20,
  });
  final AdvertisementStatus? status;
  final AdvertisementType? type;
  final String? advertiserId;
  final int limit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdvertisementFilters &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          type == other.type &&
          advertiserId == other.advertiserId &&
          limit == other.limit;

  @override
  int get hashCode =>
      status.hashCode ^ type.hashCode ^ advertiserId.hashCode ^ limit.hashCode;
}

/// Параметры для получения рекламы для показа
class DisplayAdParams {
  const DisplayAdParams({
    required this.userId,
    required this.context,
    this.limit = 3,
  });
  final String userId;
  final String context;
  final int limit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisplayAdParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          context == other.context &&
          limit == other.limit;

  @override
  int get hashCode => userId.hashCode ^ context.hashCode ^ limit.hashCode;
}

/// Провайдер для управления состоянием рекламы
final advertisingStateProvider =
    StateNotifierProvider<AdvertisingStateNotifier, AdvertisingState>((ref) =>
        AdvertisingStateNotifier(ref.read(advertisingServiceProvider)));

/// Состояние рекламы
class AdvertisingState {
  const AdvertisingState({
    this.advertisements = const [],
    this.isLoading = false,
    this.error,
    this.stats,
  });
  final List<Advertisement> advertisements;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? stats;

  AdvertisingState copyWith({
    List<Advertisement>? advertisements,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? stats,
  }) =>
      AdvertisingState(
        advertisements: advertisements ?? this.advertisements,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        stats: stats ?? this.stats,
      );
}

/// Нотификатор состояния рекламы
class AdvertisingStateNotifier extends StateNotifier<AdvertisingState> {
  AdvertisingStateNotifier(this._service) : super(const AdvertisingState());
  final AdvertisingService _service;

  /// Создать рекламу
  Future<void> createAdvertisement({
    required String advertiserId,
    required AdvertisementType type,
    required String title,
    required String description,
    required String imageUrl,
    required String targetUrl,
    required double budget,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> targetAudience,
    String? videoUrl,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final advertisement = await _service.createAdvertisement(
        advertiserId: advertiserId,
        type: type,
        title: title,
        description: description,
        imageUrl: imageUrl,
        targetUrl: targetUrl,
        budget: budget,
        startDate: startDate,
        endDate: endDate,
        targetAudience: targetAudience,
        videoUrl: videoUrl,
        metadata: metadata,
      );

      state = state.copyWith(
        advertisements: [advertisement, ...state.advertisements],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Обновить рекламу
  Future<void> updateAdvertisement({
    required String adId,
    String? title,
    String? description,
    String? imageUrl,
    String? videoUrl,
    String? targetUrl,
    double? budget,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? targetAudience,
    AdvertisementStatus? status,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.updateAdvertisement(
        adId: adId,
        title: title,
        description: description,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        targetUrl: targetUrl,
        budget: budget,
        startDate: startDate,
        endDate: endDate,
        targetAudience: targetAudience,
        status: status,
        metadata: metadata,
      );

      // Обновить локальное состояние
      final updatedAdvertisements = state.advertisements.map((ad) {
        if (ad.id == adId) {
          return ad.copyWith(
            title: title ?? ad.title,
            description: description ?? ad.description,
            imageUrl: imageUrl ?? ad.imageUrl,
            videoUrl: videoUrl ?? ad.videoUrl,
            targetUrl: targetUrl ?? ad.targetUrl,
            budget: budget ?? ad.budget,
            startDate: startDate ?? ad.startDate,
            endDate: endDate ?? ad.endDate,
            targetAudience: targetAudience ?? ad.targetAudience,
            status: status ?? ad.status,
            metadata: metadata ?? ad.metadata,
          );
        }
        return ad;
      }).toList();

      state = state.copyWith(
        advertisements: updatedAdvertisements,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Удалить рекламу
  Future<void> deleteAdvertisement(String adId) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.deleteAdvertisement(adId);

      state = state.copyWith(
        advertisements:
            state.advertisements.where((ad) => ad.id != adId).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Зафиксировать показ
  Future<void> recordImpression({
    required String adId,
    required String userId,
    required String context,
  }) async {
    try {
      await _service.recordImpression(
        adId: adId,
        userId: userId,
        context: context,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Зафиксировать клик
  Future<void> recordClick({
    required String adId,
    required String userId,
    required String context,
  }) async {
    try {
      await _service.recordClick(
        adId: adId,
        userId: userId,
        context: context,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Зафиксировать конверсию
  Future<void> recordConversion({
    required String adId,
    required String userId,
    required String context,
    required double value,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _service.recordConversion(
        adId: adId,
        userId: userId,
        context: context,
        value: value,
        metadata: metadata,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Загрузить статистику
  Future<void> loadStats(String adId) async {
    try {
      final stats = await _service.getAdvertisementStats(adId);
      state = state.copyWith(stats: stats);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith();
  }
}
