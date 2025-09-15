import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

/// Провайдер сервиса бронирований
final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

/// Провайдер бронирований пользователя
final userBookingsProvider = StreamProvider.family<List<Booking>, String>((ref, userId) {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getUserBookings(userId);
});

/// Провайдер бронирований для события
final eventBookingsProvider = StreamProvider.family<List<Booking>, String>((ref, eventId) {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getEventBookings(eventId);
});

/// Провайдер бронирования по ID
final bookingByIdProvider = FutureProvider.family<Booking?, String>((ref, bookingId) {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getBookingById(bookingId);
});

/// Провайдер проверки, забронировал ли пользователь событие
final hasUserBookedEventProvider = FutureProvider.family<bool, ({String userId, String eventId})>((ref, params) {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.hasUserBookedEvent(params.userId, params.eventId);
});

/// Провайдер статистики бронирований пользователя
final userBookingStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, userId) {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getUserBookingStats(userId);
});

/// Провайдер статистики бронирований для события
final eventBookingStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, eventId) {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getEventBookingStats(eventId);
});

/// Провайдер для управления состоянием создания бронирования
final createBookingProvider = StateNotifierProvider<CreateBookingNotifier, CreateBookingState>((ref) {
  return CreateBookingNotifier(ref.read(bookingServiceProvider));
});

/// Состояние создания бронирования
class CreateBookingState {
  final int participantsCount;
  final String? notes;
  final String? userEmail;
  final String? userPhone;
  final bool isLoading;
  final String? errorMessage;

  const CreateBookingState({
    this.participantsCount = 1,
    this.notes,
    this.userEmail,
    this.userPhone,
    this.isLoading = false,
    this.errorMessage,
  });

  CreateBookingState copyWith({
    int? participantsCount,
    String? notes,
    String? userEmail,
    String? userPhone,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CreateBookingState(
      participantsCount: participantsCount ?? this.participantsCount,
      notes: notes ?? this.notes,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Нотификатор для создания бронирования
class CreateBookingNotifier extends StateNotifier<CreateBookingState> {
  final BookingService _bookingService;

  CreateBookingNotifier(this._bookingService) : super(const CreateBookingState());

  /// Обновить количество участников
  void updateParticipantsCount(int count) {
    state = state.copyWith(participantsCount: count, errorMessage: null);
  }

  /// Обновить заметки
  void updateNotes(String? notes) {
    state = state.copyWith(notes: notes, errorMessage: null);
  }

  /// Обновить email пользователя
  void updateUserEmail(String? email) {
    state = state.copyWith(userEmail: email, errorMessage: null);
  }

  /// Обновить телефон пользователя
  void updateUserPhone(String? phone) {
    state = state.copyWith(userPhone: phone, errorMessage: null);
  }

  /// Создать бронирование
  Future<String?> createBooking({
    required String eventId,
    required String eventTitle,
    required String userId,
    required String userName,
    required DateTime eventDate,
    required double eventPrice,
    required String organizerId,
    required String organizerName,
  }) async {
    if (state.participantsCount <= 0) {
      state = state.copyWith(errorMessage: 'Количество участников должно быть больше 0');
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final booking = Booking(
        id: '', // Будет установлен при создании
        eventId: eventId,
        eventTitle: eventTitle,
        userId: userId,
        userName: userName,
        userEmail: state.userEmail,
        userPhone: state.userPhone,
        status: BookingStatus.pending,
        bookingDate: DateTime.now(),
        eventDate: eventDate,
        participantsCount: state.participantsCount,
        totalPrice: eventPrice * state.participantsCount,
        notes: state.notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        organizerId: organizerId,
        organizerName: organizerName,
      );

      final bookingId = await _bookingService.createBooking(booking);
      state = state.copyWith(isLoading: false);
      return bookingId;
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
    state = const CreateBookingState();
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
