import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../models/booking.dart';
import '../core/feature_flags.dart';

/// Провайдер сервиса администрирования
final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

/// Провайдер для проверки доступности админ-панели
final adminPanelAvailableProvider = Provider<bool>((ref) {
  return FeatureFlags.adminPanelEnabled;
});

/// Провайдер для получения всех пользователей
final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  final adminService = ref.read(adminServiceProvider);
  return adminService.getAllUsers();
});

/// Провайдер для получения всех событий
final allEventsProvider = StreamProvider<List<Event>>((ref) {
  final adminService = ref.read(adminServiceProvider);
  return adminService.getAllEvents();
});

/// Провайдер для получения всех бронирований
final allBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final adminService = ref.read(adminServiceProvider);
  return adminService.getAllBookings();
});

/// Провайдер для получения пользователей с фильтрацией
final filteredUsersProvider = StreamProvider.family<
    List<AppUser>,
    ({
      bool? isBanned,
      bool? isVerified,
      String? searchQuery,
    })>((ref, params) {
  final adminService = ref.read(adminServiceProvider);
  return adminService.getUsersWithFilter(
    isBanned: params.isBanned,
    isVerified: params.isVerified,
    searchQuery: params.searchQuery,
  );
});

/// Провайдер для получения событий с фильтрацией
final filteredEventsProvider = StreamProvider.family<
    List<Event>,
    ({
      bool? isHidden,
      String? searchQuery,
    })>((ref, params) {
  final adminService = ref.read(adminServiceProvider);
  return adminService.getEventsWithFilter(
    isHidden: params.isHidden,
    searchQuery: params.searchQuery,
  );
});

/// Провайдер для получения статистики админ-панели
final adminStatsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final adminService = ref.read(adminServiceProvider);
  return adminService.getAdminStats();
});

/// Провайдер для получения логов админ-действий
final adminLogsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, int>((ref, limit) {
  final adminService = ref.read(adminServiceProvider);
  return adminService.getAdminLogs(limit: limit);
});

/// Провайдер для получения пользователя по ID
final userByIdProvider =
    FutureProvider.family<AppUser?, String>((ref, userId) async {
  final adminService = ref.read(adminServiceProvider);
  return await adminService.getUserById(userId);
});

/// Провайдер для получения события по ID
final eventByIdProvider =
    FutureProvider.family<Event?, String>((ref, eventId) async {
  final adminService = ref.read(adminServiceProvider);
  return await adminService.getEventById(eventId);
});

/// Провайдер для получения бронирования по ID
final bookingByIdProvider =
    FutureProvider.family<Booking?, String>((ref, bookingId) async {
  final adminService = ref.read(adminServiceProvider);
  return await adminService.getBookingById(bookingId);
});

/// Провайдер для проверки, является ли пользователь админом
final isUserAdminProvider =
    FutureProvider.family<bool, String>((ref, userId) async {
  final adminService = ref.read(adminServiceProvider);
  return await adminService.isUserAdmin(userId);
});

/// Провайдер для получения настроек админ-панели
final adminSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final adminService = ref.read(adminServiceProvider);
  return await adminService.getAdminSettings();
});

/// Провайдер для статуса админ-действий
final adminActionStatusProvider = StateProvider<String>((ref) {
  return 'ready';
});

/// Провайдер для отслеживания прогресса админ-действий
final adminActionProgressProvider = StateProvider<double>((ref) {
  return 0.0;
});

/// Провайдер для последней ошибки админ-действий
final adminActionErrorProvider = StateProvider<String?>((ref) {
  return null;
});

/// Провайдер для истории админ-действий
final adminActionHistoryProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) {
  return [];
});

/// Провайдер для активных админ-действий
final activeAdminActionsProvider = StateProvider<Set<String>>((ref) {
  return {};
});

/// Провайдер для очереди админ-действий
final adminActionQueueProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) {
  return [];
});

/// Провайдер для проверки, идет ли админ-действие
final isAdminActionInProgressProvider = Provider<bool>((ref) {
  final activeActions = ref.watch(activeAdminActionsProvider);
  return activeActions.isNotEmpty;
});

/// Провайдер для получения количества элементов в очереди
final adminActionQueueLengthProvider = Provider<int>((ref) {
  final queue = ref.watch(adminActionQueueProvider);
  return queue.length;
});

/// Провайдер для получения следующего элемента в очереди
final nextAdminActionProvider = Provider<Map<String, dynamic>?>((ref) {
  final queue = ref.watch(adminActionQueueProvider);
  return queue.isNotEmpty ? queue.first : null;
});

/// Провайдер для проверки, можно ли добавить в очередь
final canAddToAdminQueueProvider = Provider<bool>((ref) {
  final queueLength = ref.watch(adminActionQueueLengthProvider);
  return queueLength < 10;
});

/// Провайдер для статистики админ-действий
final adminActionStatsProvider = StateProvider<Map<String, int>>((ref) {
  return {
    'totalActions': 0,
    'successfulActions': 0,
    'failedActions': 0,
    'usersBanned': 0,
    'usersUnbanned': 0,
    'usersVerified': 0,
    'eventsHidden': 0,
    'eventsShown': 0,
    'eventsDeleted': 0,
  };
});

/// Провайдер для последнего админ-действия
final lastAdminActionProvider = StateProvider<Map<String, dynamic>?>((ref) {
  return null;
});

/// Провайдер для получения информации об админ-панели
final adminPanelInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final isAvailable = ref.watch(adminPanelAvailableProvider);
  final isActionInProgress = ref.watch(isAdminActionInProgressProvider);
  final queueLength = ref.watch(adminActionQueueLengthProvider);

  return {
    'isAvailable': isAvailable,
    'isActionInProgress': isActionInProgress,
    'queueLength': queueLength,
  };
});

/// Провайдер для проверки доступности конкретного админ-действия
final canPerformAdminActionProvider =
    Provider.family<bool, String>((ref, action) {
  final isAvailable = ref.watch(adminPanelAvailableProvider);
  final isActionInProgress = ref.watch(isAdminActionInProgressProvider);

  if (!isAvailable || isActionInProgress) {
    return false;
  }

  switch (action) {
    case 'ban_user':
    case 'unban_user':
    case 'verify_user':
    case 'delete_user':
    case 'hide_event':
    case 'show_event':
    case 'delete_event':
      return true;
    default:
      return false;
  }
});

/// Провайдер для получения рекомендуемого админ-действия
final recommendedAdminActionProvider = Provider<String>((ref) {
  final stats = ref.watch(adminStatsProvider);
  final statsData = stats.value;

  if (statsData != null) {
    final bannedUsers = statsData['bannedUsers'] ?? 0;
    final hiddenEvents = statsData['hiddenEvents'] ?? 0;

    if (bannedUsers > 0) {
      return 'review_banned_users';
    } else if (hiddenEvents > 0) {
      return 'review_hidden_events';
    } else {
      return 'review_new_content';
    }
  }

  return 'review_new_content';
});

/// Провайдер для получения иконки админ-действия
final adminActionIconProvider = Provider.family<String, String>((ref, action) {
  switch (action) {
    case 'ban_user':
      return 'block';
    case 'unban_user':
      return 'check_circle';
    case 'verify_user':
      return 'verified';
    case 'delete_user':
      return 'delete';
    case 'hide_event':
      return 'visibility_off';
    case 'show_event':
      return 'visibility';
    case 'delete_event':
      return 'delete';
    default:
      return 'admin_panel_settings';
  }
});

/// Провайдер для получения цвета админ-действия
final adminActionColorProvider = Provider.family<int, String>((ref, action) {
  switch (action) {
    case 'ban_user':
    case 'delete_user':
    case 'delete_event':
      return 0xFFE53E3E; // Red
    case 'unban_user':
    case 'verify_user':
    case 'show_event':
      return 0xFF38A169; // Green
    case 'hide_event':
      return 0xFFD69E2E; // Yellow
    default:
      return 0xFF3182CE; // Blue
  }
});

/// Провайдер для получения названия админ-действия
final adminActionNameProvider = Provider.family<String, String>((ref, action) {
  switch (action) {
    case 'ban_user':
      return 'Заблокировать пользователя';
    case 'unban_user':
      return 'Разблокировать пользователя';
    case 'verify_user':
      return 'Верифицировать пользователя';
    case 'delete_user':
      return 'Удалить пользователя';
    case 'hide_event':
      return 'Скрыть событие';
    case 'show_event':
      return 'Показать событие';
    case 'delete_event':
      return 'Удалить событие';
    default:
      return 'Неизвестное действие';
  }
});

/// Провайдер для получения описания админ-действия
final adminActionDescriptionProvider =
    Provider.family<String, String>((ref, action) {
  switch (action) {
    case 'ban_user':
      return 'Заблокировать пользователя за нарушение правил';
    case 'unban_user':
      return 'Разблокировать пользователя';
    case 'verify_user':
      return 'Верифицировать пользователя';
    case 'delete_user':
      return 'Удалить пользователя и все связанные данные';
    case 'hide_event':
      return 'Скрыть событие от других пользователей';
    case 'show_event':
      return 'Показать событие другим пользователям';
    case 'delete_event':
      return 'Удалить событие навсегда';
    default:
      return 'Неизвестное действие';
  }
});
