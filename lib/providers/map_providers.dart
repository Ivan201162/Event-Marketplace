import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/feature_flags.dart';
import '../maps/map_service.dart';
import '../maps/map_service_mock.dart';

/// Провайдер сервиса карт
final mapServiceProvider = Provider<MapService>((ref) {
  // Всегда используем mock-реализацию, так как карты отключены через FeatureFlags
  return MapServiceMock();
});

/// Провайдер для проверки доступности карт
final mapsAvailableProvider = Provider<bool>((ref) => FeatureFlags.mapsEnabled);

/// Провайдер для инициализации карт
final mapInitializationProvider = FutureProvider<void>((ref) async {
  final mapService = ref.read(mapServiceProvider);
  await mapService.initialize();
});

/// Провайдер текущего местоположения
final currentLocationProvider = FutureProvider<MapCoordinates?>((ref) async {
  final mapService = ref.read(mapServiceProvider);
  if (!mapService.isAvailable) return null;

  return mapService.getCurrentLocation();
});

/// Провайдер разрешения на местоположение
final locationPermissionProvider = FutureProvider<bool>((ref) async {
  final mapService = ref.read(mapServiceProvider);
  if (!mapService.isAvailable) return false;

  return mapService.hasLocationPermission();
});
