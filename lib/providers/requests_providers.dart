import 'package:event_marketplace_app/models/request.dart';
import 'package:event_marketplace_app/services/requests_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер сервиса заявок
final requestsServiceProvider = Provider<RequestsService>((ref) {
  return RequestsService();
});

/// Провайдер списка заявок
final requestsProvider = FutureProvider<List<Request>>((ref) async {
  final requestsService = ref.read(requestsServiceProvider);
  return requestsService.getRequests();
});

/// Провайдер для создания заявки
final createRequestProvider =
    FutureProvider.family<void, Request>((ref, request) async {
  final requestsService = ref.read(requestsServiceProvider);
  await requestsService.createRequest(request);
});

/// Провайдер для обновления статуса заявки
final updateRequestProvider =
    FutureProvider.family<void, ({String requestId, String status})>((ref, params) async {
  final requestsService = ref.read(requestsServiceProvider);
  await requestsService.updateRequestStatus(params.requestId, params.status);
});
