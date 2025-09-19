import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import '../services/event_service.dart';

/// Провайдер сервиса событий
final eventServiceProvider = Provider<EventService>((ref) => EventService());

/// Провайдер для формы создания события
final createEventProvider =
    NotifierProvider<CreateEventNotifier, CreateEventState>(
        CreateEventNotifier.new);

/// Состояние формы создания события
class CreateEventState {
  const CreateEventState({
    this.isLoading = false,
    this.errorMessage,
  });
  final bool isLoading;
  final String? errorMessage;

  CreateEventState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) =>
      CreateEventState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

/// Нотификатор для формы создания события
class CreateEventNotifier extends Notifier<CreateEventState> {
  @override
  CreateEventState build() => const CreateEventState();

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? errorMessage) {
    state = state.copyWith(errorMessage: errorMessage);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Провайдер всех событий
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final eventService = ref.read(eventServiceProvider);
  return await eventService.getEvents();
});

/// Провайдер событий пользователя
final userEventsProvider =
    FutureProvider.family<List<Event>, String>((ref, userId) async {
  final eventService = ref.read(eventServiceProvider);
  return eventService.getUserEvents(userId);
});

/// Провайдер события по ID
final eventProvider =
    FutureProvider.family<Event?, String>((ref, eventId) async {
  final eventService = ref.read(eventServiceProvider);
  return await eventService.getEvent(eventId);
});
