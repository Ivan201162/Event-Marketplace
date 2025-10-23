import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/request.dart';
import '../services/request_service.dart';

/// Request service provider
final requestServiceProvider = Provider<RequestService>((ref) {
  return RequestService();
});

/// Sent requests provider
final sentRequestsProvider =
    FutureProvider.family<List<Request>, String>((ref, userId) async {
  final service = ref.read(requestServiceProvider);
  return await service.getSentRequests(userId);
});

/// Received requests provider
final receivedRequestsProvider =
    FutureProvider.family<List<Request>, String>((ref, userId) async {
  final service = ref.read(requestServiceProvider);
  return await service.getReceivedRequests(userId);
});

/// Requests by status provider
final requestsByStatusProvider = FutureProvider.family<List<Request>,
    ({String userId, RequestStatus status})>((
  ref,
  params,
) async {
  final service = ref.read(requestServiceProvider);
  return await service.getRequestsByStatus(params.userId, params.status);
});

/// Requests by category provider
final requestsByCategoryProvider =
    FutureProvider.family<List<Request>, String>((
  ref,
  category,
) async {
  final service = ref.read(requestServiceProvider);
  return await service.getRequestsByCategory(category);
});

/// Requests by city provider
final requestsByCityProvider =
    FutureProvider.family<List<Request>, String>((ref, city) async {
  final service = ref.read(requestServiceProvider);
  return await service.getRequestsByCity(city);
});

/// Request by ID provider
final requestByIdProvider =
    FutureProvider.family<Request?, String>((ref, requestId) async {
  final service = ref.read(requestServiceProvider);
  return await service.getRequestById(requestId);
});

/// Stream of sent requests provider
final sentRequestsStreamProvider =
    StreamProvider.family<List<Request>, String>((ref, userId) {
  final service = ref.read(requestServiceProvider);
  return service.getSentRequestsStream(userId);
});

/// Stream of received requests provider
final receivedRequestsStreamProvider =
    StreamProvider.family<List<Request>, String>((ref, userId) {
  final service = ref.read(requestServiceProvider);
  return service.getReceivedRequestsStream(userId);
});

/// Search requests provider
final searchRequestsProvider =
    FutureProvider.family<List<Request>, String>((ref, query) async {
  final service = ref.read(requestServiceProvider);
  return await service.searchRequests(query);
});

/// Request statistics provider
final requestStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, userId) async {
  final service = ref.read(requestServiceProvider);
  return await service.getRequestStats(userId);
});

/// Available categories provider
final requestCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(requestServiceProvider);
  return await service.getCategories();
});

/// Available cities provider
final requestCitiesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(requestServiceProvider);
  return await service.getCities();
});

/// Pending requests count provider
final pendingRequestsCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.read(requestServiceProvider);
  return await service.getPendingRequestsCount(userId);
});

/// Stream of pending requests count provider
final pendingRequestsCountStreamProvider =
    StreamProvider.family<int, String>((ref, userId) {
  final service = ref.read(requestServiceProvider);
  return service.getPendingRequestsCountStream(userId);
});
