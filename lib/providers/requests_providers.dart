import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/request.dart';
import '../services/requests_service.dart';

/// Провайдер сервиса заявок
final requestsServiceProvider = Provider<RequestsService>((ref) {
  return RequestsService();
});

/// Провайдер состояния заявок
final requestsProvider = StateNotifierProvider<RequestsNotifier, AsyncValue<List<Request>>>((ref) {
  return RequestsNotifier(ref.read(requestsServiceProvider));
});

/// Notifier для управления состоянием заявок
class RequestsNotifier extends StateNotifier<AsyncValue<List<Request>>> {
  final RequestsService _requestsService;

  RequestsNotifier(this._requestsService) : super(const AsyncValue.loading()) {
    _loadInitialRequests();
  }

  Future<void> _loadInitialRequests() async {
    try {
      state = const AsyncValue.loading();
      final requests = await _requestsService.getRequests();
      state = AsyncValue.data(requests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshRequests() async {
    await _loadInitialRequests();
  }

  Future<void> loadMoreRequests() async {
    if (state.hasValue) {
      try {
        final currentRequests = state.value!;
        final newRequests = await _requestsService.getMoreRequests(currentRequests.length);
        state = AsyncValue.data([...currentRequests, ...newRequests]);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> searchRequests(String query) async {
    try {
      state = const AsyncValue.loading();
      final requests = await _requestsService.searchRequests(query);
      state = AsyncValue.data(requests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> filterRequests(String filter) async {
    try {
      state = const AsyncValue.loading();
      final requests = await _requestsService.filterRequests(filter);
      state = AsyncValue.data(requests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createRequest(Request request) async {
    try {
      await _requestsService.createRequest(request);
      await refreshRequests();
    } catch (error) {
      // Обработка ошибки создания заявки
      rethrow;
    }
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      await _requestsService.updateRequestStatus(requestId, status);
      await refreshRequests();
    } catch (error) {
      // Обработка ошибки обновления статуса
      rethrow;
    }
  }

  Future<void> deleteRequest(String requestId) async {
    try {
      await _requestsService.deleteRequest(requestId);
      await refreshRequests();
    } catch (error) {
      // Обработка ошибки удаления заявки
      rethrow;
    }
  }
}