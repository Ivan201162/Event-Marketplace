import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/event_service.dart';
import '../models/event.dart';

/// Провайдер сервиса событий
final eventServiceProvider = Provider<EventService>((ref) {
  return EventService();
});

/// Провайдер всех событий
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final eventService = ref.read(eventServiceProvider);
  return await eventService.getEvents();
});

/// Провайдер событий пользователя
final userEventsProvider =
    FutureProvider.family<List<Event>, String>((ref, userId) async {
  final eventService = ref.read(eventServiceProvider);
  return await eventService.getUserEvents(userId);
});

/// Провайдер события по ID
final eventProvider =
    FutureProvider.family<Event?, String>((ref, eventId) async {
  final eventService = ref.read(eventServiceProvider);
  return await eventService.getEvent(eventId);
});

/// Состояние создания события
class CreateEventState {
  final bool isCreating;
  final String? error;
  final Event? createdEvent;

  const CreateEventState({
    this.isCreating = false,
    this.error,
    this.createdEvent,
  });

  CreateEventState copyWith({
    bool? isCreating,
    String? error,
    Event? createdEvent,
  }) {
    return CreateEventState(
      isCreating: isCreating ?? this.isCreating,
      error: error ?? this.error,
      createdEvent: createdEvent ?? this.createdEvent,
    );
  }
}

/// Провайдер состояния создания события
final createEventProvider =
    NotifierProvider<CreateEventNotifier, CreateEventState>(() {
  return CreateEventNotifier();
});

/// Notifier для создания события
class CreateEventNotifier extends Notifier<CreateEventState> {
  @override
  CreateEventState build() => const CreateEventState();

  Future<void> createEvent(Event event) async {
    state = state.copyWith(isCreating: true, error: null);

    try {
      final eventService = ref.read(eventServiceProvider);
      final createdEvent = await eventService.createEvent(event);
      state = state.copyWith(
        isCreating: false,
        createdEvent: createdEvent,
      );
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const CreateEventState();
  }
}

/// Статистика событий пользователя
class UserEventStats {
  final int totalEvents;
  final int activeEvents;
  final int completedEvents;
  final int cancelledEvents;
  final double totalRevenue;
  final double averageRating;

  const UserEventStats({
    required this.totalEvents,
    required this.activeEvents,
    required this.completedEvents,
    required this.cancelledEvents,
    required this.totalRevenue,
    required this.averageRating,
  });
}

/// Провайдер статистики событий пользователя
final userEventStatsProvider =
    FutureProvider.family<UserEventStats, String>((ref, userId) async {
  final eventService = ref.read(eventServiceProvider);
  final events = await eventService.getUserEvents(userId);

  final totalEvents = events.length;
  final activeEvents =
      events.where((e) => e.date.isAfter(DateTime.now())).length;
  final completedEvents =
      events.where((e) => e.date.isBefore(DateTime.now())).length;
  final cancelledEvents = 0; // Нужно добавить поле cancelled в модель Event

  final totalRevenue = events.fold(0.0, (sum, event) => sum + event.price);
  final averageRating = 4.5; // Нужно вычислить из отзывов

  return UserEventStats(
    totalEvents: totalEvents,
    activeEvents: activeEvents,
    completedEvents: completedEvents,
    cancelledEvents: cancelledEvents,
    totalRevenue: totalRevenue,
    averageRating: averageRating,
  );
});
