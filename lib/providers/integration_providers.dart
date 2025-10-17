import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/integration.dart';
import '../services/integration_service.dart';

/// Провайдер сервиса интеграций
final integrationServiceProvider = Provider<IntegrationService>((ref) => IntegrationService());

/// Провайдер доступных интеграций
final availableIntegrationsProvider = StreamProvider<List<Integration>>(
  (ref) => ref.watch(integrationServiceProvider).getAvailableIntegrations(),
);

/// Провайдер интеграций пользователя
final userIntegrationsProvider = StreamProvider.family<List<IntegrationSettings>, String>(
  (ref, userId) => ref.watch(integrationServiceProvider).getUserIntegrations(userId),
);

/// Провайдер событий интеграции пользователя
final userIntegrationEventsProvider = StreamProvider.family<List<IntegrationEvent>, String>(
  (ref, userId) =>
      ref.watch(integrationServiceProvider).getUserIntegrationEvents(userId, 'default'),
);

/// Провайдер статистики интеграций
final integrationStatsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, userId) => ref.watch(integrationServiceProvider).getIntegrationStats(),
);

/// Провайдер текущей геолокации
final currentLocationProvider = FutureProvider<LocationData?>(
  (ref) => ref.watch(integrationServiceProvider).getCurrentLocation(),
);

/// Провайдер статуса подключения к интернету
final connectivityStatusProvider = FutureProvider<bool>(
  (ref) => ref.watch(integrationServiceProvider).isConnectedToInternet(),
);

/// Провайдер типа подключения
final connectionTypeProvider = FutureProvider<ConnectivityResult>(
  (ref) => ref.watch(integrationServiceProvider).getConnectionType(),
);
