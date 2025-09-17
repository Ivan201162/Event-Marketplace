import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/services/recommendation_engine.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';

part 'recommendation_providers.g.dart';

/// Провайдер движка рекомендаций
@riverpod
RecommendationEngine recommendationEngine(RecommendationEngineRef ref) {
  return RecommendationEngine();
}

/// Провайдер рекомендаций для текущего пользователя
@riverpod
Future<List<Specialist>> userRecommendations(UserRecommendationsRef ref) async {
  final authState = ref.watch(authStateProvider);
  final engine = ref.read(recommendationEngineProvider);

  if (authState.user == null) {
    return [];
  }

  return engine.getRecommendations(userId: authState.user!.uid);
}

/// Провайдер популярных специалистов
@riverpod
Future<List<Specialist>> popularSpecialists(PopularSpecialistsRef ref) async {
  final engine = ref.read(recommendationEngineProvider);
  return engine.getPopularSpecialists();
}

/// Провайдер ближайших специалистов
@riverpod
Future<List<Specialist>> nearbySpecialists(
  NearbySpecialistsRef ref, {
  required double latitude,
  required double longitude,
  double radiusKm = 50,
}) async {
  final engine = ref.read(recommendationEngineProvider);
  return engine.getNearbySpecialists(
    latitude: latitude,
    longitude: longitude,
    radiusKm: radiusKm,
  );
}
