import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/request.dart';
import '../services/requests_service.dart';

/// Провайдер сервиса заявок
final requestsServiceProvider = Provider<RequestsService>((ref) {
  return RequestsService();
});

/// Провайдер списка заявок
final requestsProvider = FutureProvider<List<Request>>((ref) async {
  final requestsService = ref.read(requestsServiceProvider);
  return await requestsService.getRequests();
});

/// Провайдер для создания заявки
final createRequestProvider =
    FutureProvider.family<void, Request>((ref, request) async {
  final requestsService = ref.read(requestsServiceProvider);
  await requestsService.createRequest(request);
});

/// Провайдер для обновления заявки
final updateRequestProvider =
    FutureProvider.family<void, Request>((ref, request) async {
  final requestsService = ref.read(requestsServiceProvider);
  await requestsService.updateRequest(request);
});
