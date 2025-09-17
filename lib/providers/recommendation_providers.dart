import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/services/recommendation_engine.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';

/// Провайдер движка рекомендаций
final recommendationEngineProvider = Provider<RecommendationEngine>((ref) {
  return RecommendationEngine();
});

/// Провайдер рекомендаций для текущего пользователя
final userRecommendationsProvider = FutureProvider<List<Specialist>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final engine = ref.read(recommendationEngineProvider);

  if (authState.user == null) {
    return [];
  }

  return engine.getRecommendations(userId: authState.user!.uid);
});

/// Провайдер популярных специалистов
final popularSpecialistsProvider = FutureProvider<List<Specialist>>((ref) async {
  final engine = ref.read(recommendationEngineProvider);
  return engine.getPopularSpecialists();
});

/// Провайдер ближайших специалистов
final nearbySpecialistsProvider = FutureProvider.family<List<Specialist>, NearbySpecialistsParams>((ref, params) async {
  final engine = ref.read(recommendationEngineProvider);
  return engine.getNearbySpecialists(
    latitude: params.latitude,
    longitude: params.longitude,
    radiusKm: params.radiusKm,
  );
});

/// Параметры для поиска ближайших специалистов
class NearbySpecialistsParams {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const NearbySpecialistsParams({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 50,
  });
}
