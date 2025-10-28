import 'package:event_marketplace_app/models/event.dart';
import 'package:event_marketplace_app/services/event_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер сервиса событий
final eventServiceProvider = Provider<EventService>((ref) => EventService());

/// Провайдер для формы создания события
final createEventProvider =
    NotifierProvider<CreateEventNotifier, CreateEventState>(
  CreateEventNotifier.new,
);

/// Состояние формы создания события
class CreateEventState {
  const CreateEventState({this.isLoading = false, this.errorMessage});
  final bool isLoading;
  final String? errorMessage;

  CreateEventState copyWith({bool? isLoading, String? errorMessage}) =>
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
    state = state.copyWith();
  }
}

/// Провайдер всех событий
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final eventService = ref.read(eventServiceProvider);
  return eventService.getEvents();
});

/// Провайдер событий пользователя
final userEventsProvider =
    FutureProvider.family<List<Event>, String>((ref, userId) async {
  final eventService = ref.read(eventServiceProvider);
  return eventService.getUserEvents(userId).first;
});

/// Провайдер события по ID
final eventProvider =
    FutureProvider.family<Event?, String>((ref, eventId) async {
  final eventService = ref.read(eventServiceProvider);
  return eventService.getEvent(eventId);
});

/// Провайдер для статистики событий пользователя
final userEventStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  userId,
) async {
  final eventService = ref.read(eventServiceProvider);
  // Заглушка для статистики событий пользователя
  return {
    'totalEvents': 0,
    'upcomingEvents': 0,
    'pastEvents': 0,
    'cancelledEvents': 0,
  };
});
