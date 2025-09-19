import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../services/favorites_service.dart';

/// Провайдер сервиса избранного
final favoritesServiceProvider =
    Provider<FavoritesService>((ref) => FavoritesService());

/// Провайдер избранных событий пользователя
final userFavoritesProvider =
    StreamProvider.family<List<Event>, String>((ref, userId) {
  final favoritesService = ref.watch(favoritesServiceProvider);
  return favoritesService.getUserFavorites(userId);
});

/// Провайдер количества избранных событий пользователя
final favoritesCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  final favoritesService = ref.watch(favoritesServiceProvider);
  return favoritesService
      .getUserFavorites(userId)
      .map((favorites) => favorites.length);
});

/// Провайдер проверки, добавлено ли событие в избранное
final isFavoriteProvider =
    FutureProvider.family<bool, ({String userId, String eventId})>(
        (ref, params) {
  final favoritesService = ref.watch(favoritesServiceProvider);
  return favoritesService.isFavorite(params.userId, params.eventId);
});

/// Провайдер количества избранных событий
final favoritesCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  final favoritesService = ref.watch(favoritesServiceProvider);
  return favoritesService.getFavoritesCount(userId);
});
