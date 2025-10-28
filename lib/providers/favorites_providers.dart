import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/services/favorites_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер сервиса избранного
final favoritesServiceProvider =
    Provider<FavoritesService>((ref) => FavoritesService());

/// Провайдер избранных специалистов
final favoriteSpecialistsProvider = StreamProvider<List<Specialist>>((ref) {
  final favoritesService = ref.watch(favoritesServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser.value == null) {
    return Stream.value([]);
  }

  return favoritesService.getFavoriteSpecialistsStream(currentUser.value!.uid);
});

/// Провайдер количества избранных специалистов
final favoritesCountProvider = FutureProvider<int>((ref) {
  final favoritesService = ref.watch(favoritesServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser.value == null) {
    return Future.value(0);
  }

  return favoritesService.getFavoritesCount(currentUser.value!.uid);
});

/// Провайдер для проверки, является ли специалист избранным
final isFavoriteProvider =
    FutureProvider.family<bool, String>((ref, specialistId) {
  final favoritesService = ref.watch(favoritesServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser.value == null) {
    return Future.value(false);
  }

  return favoritesService.isFavorite(
      userId: currentUser.value!.uid, specialistId: specialistId,);
});

/// Провайдер для переключения статуса избранного
final toggleFavoriteProvider =
    FutureProvider.family<bool, String>((ref, specialistId) {
  final favoritesService = ref.watch(favoritesServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser.value == null) {
    throw Exception('Пользователь не авторизован');
  }

  return favoritesService.toggleFavorite(
    userId: currentUser.value!.uid,
    specialistId: specialistId,
  );
});
