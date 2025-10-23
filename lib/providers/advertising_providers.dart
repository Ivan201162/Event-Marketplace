import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/advertisement.dart';
import '../services/advertising_service.dart';

/// Провайдер сервиса рекламы
final advertisingServiceProvider =
    Provider<AdvertisingService>((ref) => AdvertisingService());

/// Провайдер рекламных объявлений
final advertisementsProvider =
    FutureProvider.family<List<Advertisement>, AdvertisementFilters>((
  ref,
  filters,
) async {
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
    FutureProvider.family<List<Advertisement>, DisplayAdParams>((
  ref,
  params,
) async {
  final service = ref.read(advertisingServiceProvider);
  return service.getAdvertisementsForDisplay(
    userId: params.userId,
    context: params.context,
    limit: params.limit,
  );
});

/// Провайдер статистики рекламы
final advertisementStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  adId,
) async {
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
  const AdvertisementFilters(
      {this.status, this.type, this.advertiserId, this.limit = 20});

  final AdvertisementStatus? status;
  final AdvertisementType? type;
  final String? advertiserId;
  final int limit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdvertisementFilters &&
        other.status == status &&
        other.type == type &&
        other.advertiserId == advertiserId &&
        other.limit == limit;
  }

  @override
  int get hashCode =>
      status.hashCode ^ type.hashCode ^ advertiserId.hashCode ^ limit.hashCode;
}

/// Параметры для показа рекламы
class DisplayAdParams {
  const DisplayAdParams(
      {required this.userId, required this.context, this.limit = 5});

  final String userId;
  final String context;
  final int limit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisplayAdParams &&
        other.userId == userId &&
        other.context == context &&
        other.limit == limit;
  }

  @override
  int get hashCode => userId.hashCode ^ context.hashCode ^ limit.hashCode;
}

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

/// Notifier для состояния рекламы (мигрирован с StateNotifier)
class AdvertisingNotifier extends Notifier<AdvertisingState> {
  late final AdvertisingService _service;

  @override
  AdvertisingState build() {
    _service = ref.read(advertisingServiceProvider);
    return const AdvertisingState();
  }

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
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Обновить рекламу
  Future<void> updateAdvertisement({
    required String adId,
    String? title,
    String? description,
    String? imageUrl,
    String? targetUrl,
    double? budget,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? targetAudience,
    String? videoUrl,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.updateAdvertisement(
        adId: adId,
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

      // Обновляем локальное состояние
      final updatedAdvertisements = state.advertisements.map((ad) {
        if (ad.id == adId) {
          return ad.copyWith(
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
        }
        return ad;
      }).toList();

      state = state.copyWith(
          advertisements: updatedAdvertisements, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Записать клик по рекламе
  Future<void> recordClick(String adId) async {
    try {
      await _service.recordClick(adId);

      // Обновляем статистику кликов
      final updatedAdvertisements = state.advertisements.map((ad) {
        if (ad.id == adId) {
          return ad.copyWith(clicks: (ad.clicks ?? 0) + 1);
        }
        return ad;
      }).toList();

      state = state.copyWith(advertisements: updatedAdvertisements);
    } catch (e) {
      // Логируем ошибку, но не прерываем работу
      debugPrint('Error recording click for ad $adId: $e');
    }
  }

  /// Загрузить статистику
  Future<void> loadStats() async {
    try {
      final stats = await _service.getOverallStats();
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

/// Провайдер состояния рекламы (мигрирован с StateNotifierProvider)
final advertisingStateProvider =
    NotifierProvider<AdvertisingNotifier, AdvertisingState>(
  AdvertisingNotifier.new,
);
