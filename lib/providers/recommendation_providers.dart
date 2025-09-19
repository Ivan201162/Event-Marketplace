import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist.dart';
import '../models/specialist_recommendation.dart';
import '../services/recommendation_engine.dart';
import 'auth_providers.dart';

/// Провайдер движка рекомендаций
final recommendationEngineProvider =
    Provider<RecommendationEngine>((ref) => RecommendationEngine());

/// Провайдер рекомендаций для текущего пользователя
final userRecommendationsProvider =
    FutureProvider.family<List<SpecialistRecommendation>, String>(
        (ref, userId) async {
  final engine = ref.read(recommendationEngineProvider);
  return engine.getRecommendations(userId: userId);
});

/// Провайдер популярных специалистов
final popularSpecialistsProvider =
    FutureProvider<List<Specialist>>((ref) async {
  final engine = ref.read(recommendationEngineProvider);
  return engine.getPopularSpecialists();
});

/// Провайдер ближайших специалистов
final nearbySpecialistsProvider =
    FutureProvider.family<List<Specialist>, NearbySpecialistsParams>(
        (ref, params) async {
  final engine = ref.read(recommendationEngineProvider);
  return engine.getNearbySpecialists(
    latitude: params.latitude,
    longitude: params.longitude,
    radiusKm: params.radiusKm,
  );
});

/// Параметры для поиска ближайших специалистов
class NearbySpecialistsParams {
  const NearbySpecialistsParams({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 50,
  });
  final double latitude;
  final double longitude;
  final double radiusKm;
}
