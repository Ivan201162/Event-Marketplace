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
final userEventsProvider = FutureProvider.family<List<Event>, String>((ref, userId) async {
  final eventService = ref.read(eventServiceProvider);
  return await eventService.getUserEvents(userId);
});

/// Провайдер события по ID
final eventProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  final eventService = ref.read(eventServiceProvider);
  return await eventService.getEvent(eventId);
});