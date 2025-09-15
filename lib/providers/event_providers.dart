import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/event_service.dart';
import '../models/event.dart';
import '../models/event_filter.dart';

/// Провайдер сервиса событий
final eventServiceProvider = Provider<EventService>((ref) {
  return EventService();
});

/// Провайдер всех событий
final allEventsProvider = StreamProvider<List<Event>>((ref) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getAllEvents();
});

/// Провайдер событий пользователя
final userEventsProvider = StreamProvider.family<List<Event>, String>((ref, userId) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getUserEvents(userId);
});

/// Провайдер события по ID
final eventByIdProvider = FutureProvider.family<Event?, String>((ref, eventId) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getEventById(eventId);
});

/// Провайдер популярных событий
final popularEventsProvider = StreamProvider<List<Event>>((ref) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getPopularEvents();
});

/// Провайдер ближайших событий
final upcomingEventsProvider = StreamProvider<List<Event>>((ref) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getUpcomingEvents();
});

/// Провайдер событий по категории
final eventsByCategoryProvider = StreamProvider.family<List<Event>, EventCategory>((ref, category) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getEventsByCategory(category);
});

/// Провайдер событий по дате
final eventsByDateProvider = StreamProvider.family<List<Event>, DateTime>((ref, date) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getEventsByDate(date);
});

/// Провайдер событий с фильтрацией
final filteredEventsProvider = StreamProvider.family<List<Event>, EventFilter>((ref, filter) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getFilteredEvents(filter);
});

/// Провайдер статистики событий пользователя
final userEventStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, userId) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getUserEventStats(userId);
});

/// Провайдер для управления состоянием создания события
final createEventProvider = StateNotifierProvider<CreateEventNotifier, CreateEventState>((ref) {
  return CreateEventNotifier(ref.read(eventServiceProvider));
});

/// Состояние создания события
class CreateEventState {
  final String title;
  final String description;
  final DateTime? date;
  final DateTime? endDate;
  final String location;
  final double price;
  final EventCategory category;
  final int maxParticipants;
  final List<String> tags;
  final String? contactInfo;
  final String? requirements;
  final bool isPublic;
  final bool isLoading;
  final String? errorMessage;

  const CreateEventState({
    this.title = '',
    this.description = '',
    this.date,
    this.endDate,
    this.location = '',
    this.price = 0.0,
    this.category = EventCategory.other,
    this.maxParticipants = 50,
    this.tags = const [],
    this.contactInfo,
    this.requirements,
    this.isPublic = true,
    this.isLoading = false,
    this.errorMessage,
  });

  CreateEventState copyWith({
    String? title,
    String? description,
    DateTime? date,
    DateTime? endDate,
    String? location,
    double? price,
    EventCategory? category,
    int? maxParticipants,
    List<String>? tags,
    String? contactInfo,
    String? requirements,
    bool? isPublic,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CreateEventState(
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      price: price ?? this.price,
      category: category ?? this.category,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      tags: tags ?? this.tags,
      contactInfo: contactInfo ?? this.contactInfo,
      requirements: requirements ?? this.requirements,
      isPublic: isPublic ?? this.isPublic,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Нотификатор для создания события
class CreateEventNotifier extends StateNotifier<CreateEventState> {
  final EventService _eventService;

  CreateEventNotifier(this._eventService) : super(const CreateEventState());

  /// Обновить заголовок
  void updateTitle(String title) {
    state = state.copyWith(title: title, errorMessage: null);
  }

  /// Обновить описание
  void updateDescription(String description) {
    state = state.copyWith(description: description, errorMessage: null);
  }

  /// Обновить дату
  void updateDate(DateTime date) {
    state = state.copyWith(date: date, errorMessage: null);
  }

  /// Обновить дату окончания
  void updateEndDate(DateTime? endDate) {
    state = state.copyWith(endDate: endDate, errorMessage: null);
  }

  /// Обновить местоположение
  void updateLocation(String location) {
    state = state.copyWith(location: location, errorMessage: null);
  }

  /// Обновить цену
  void updatePrice(double price) {
    state = state.copyWith(price: price, errorMessage: null);
  }

  /// Обновить категорию
  void updateCategory(EventCategory category) {
    state = state.copyWith(category: category, errorMessage: null);
  }

  /// Обновить максимальное количество участников
  void updateMaxParticipants(int maxParticipants) {
    state = state.copyWith(maxParticipants: maxParticipants, errorMessage: null);
  }

  /// Обновить теги
  void updateTags(List<String> tags) {
    state = state.copyWith(tags: tags, errorMessage: null);
  }

  /// Обновить контактную информацию
  void updateContactInfo(String? contactInfo) {
    state = state.copyWith(contactInfo: contactInfo, errorMessage: null);
  }

  /// Обновить требования
  void updateRequirements(String? requirements) {
    state = state.copyWith(requirements: requirements, errorMessage: null);
  }

  /// Обновить публичность
  void updateIsPublic(bool isPublic) {
    state = state.copyWith(isPublic: isPublic, errorMessage: null);
  }

  /// Создать событие
  Future<String?> createEvent(String organizerId, String organizerName, String? organizerPhoto) async {
    if (state.title.isEmpty || state.description.isEmpty || state.date == null || state.location.isEmpty) {
      state = state.copyWith(errorMessage: 'Заполните все обязательные поля');
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final event = Event(
        id: '', // Будет установлен при создании
        title: state.title,
        description: state.description,
        date: state.date!,
        endDate: state.endDate,
        location: state.location,
        price: state.price,
        organizerId: organizerId,
        organizerName: organizerName,
        organizerPhoto: organizerPhoto,
        category: state.category,
        status: EventStatus.active,
        maxParticipants: state.maxParticipants,
        currentParticipants: 0,
        tags: state.tags,
        contactInfo: state.contactInfo,
        requirements: state.requirements,
        isPublic: state.isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final eventId = await _eventService.createEvent(event);
      state = state.copyWith(isLoading: false);
      return eventId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Сбросить форму
  void reset() {
    state = const CreateEventState();
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
