import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/integration.dart';
import '../services/integration_service.dart';

/// Провайдер сервиса интеграций
final integrationServiceProvider = Provider<IntegrationService>((ref) {
  return IntegrationService();
});

/// Провайдер доступных интеграций
final availableIntegrationsProvider = StreamProvider<List<Integration>>((ref) {
  return ref.watch(integrationServiceProvider).getAvailableIntegrations();
});

/// Провайдер интеграций пользователя
final userIntegrationsProvider = StreamProvider.family<List<IntegrationSettings>, String>((ref, userId) {
  return ref.watch(integrationServiceProvider).getUserIntegrations(userId);
});

/// Провайдер событий интеграции пользователя
final userIntegrationEventsProvider = StreamProvider.family<List<IntegrationEvent>, String>((ref, userId) {
  return ref.watch(integrationServiceProvider).getUserIntegrationEvents(userId);
});

/// Провайдер статистики интеграций
final integrationStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) {
  return ref.watch(integrationServiceProvider).getIntegrationStats(userId);
});

/// Провайдер текущей геолокации
final currentLocationProvider = FutureProvider<LocationData?>((ref) {
  return ref.watch(integrationServiceProvider).getCurrentLocation();
});

/// Провайдер статуса подключения к интернету
final connectivityStatusProvider = FutureProvider<bool>((ref) {
  return ref.watch(integrationServiceProvider).isConnectedToInternet();
});

/// Провайдер типа подключения
final connectionTypeProvider = FutureProvider<ConnectivityResult>((ref) {
  return ref.watch(integrationServiceProvider).getConnectionType();
});
