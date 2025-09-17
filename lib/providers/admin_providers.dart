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

/// Нотификатор для статуса админ-действий
class AdminActionStatusNotifier extends Notifier<String> {
  @override
  String build() => 'ready';

  void setStatus(String status) {
    state = status;
  }
}

/// Провайдер для статуса админ-действий
final adminActionStatusProvider =
    NotifierProvider<AdminActionStatusNotifier, String>(() {
  return AdminActionStatusNotifier();
});

/// Нотификатор для отслеживания прогресса админ-действий
class AdminActionProgressNotifier extends Notifier<double> {
  @override
  double build() => 0.0;

  void setProgress(double progress) {
    state = progress;
  }
}

/// Провайдер для отслеживания прогресса админ-действий
final adminActionProgressProvider =
    NotifierProvider<AdminActionProgressNotifier, double>(() {
  return AdminActionProgressNotifier();
});

/// Нотификатор для последней ошибки админ-действий
class AdminActionErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setError(String? error) {
    state = error;
  }
}

/// Провайдер для последней ошибки админ-действий
final adminActionErrorProvider =
    NotifierProvider<AdminActionErrorNotifier, String?>(() {
  return AdminActionErrorNotifier();
});

/// Нотификатор для истории админ-действий
class AdminActionHistoryNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void addAction(Map<String, dynamic> action) {
    state = [...state, action];
  }

  void clearHistory() {
    state = [];
  }
}

/// Провайдер для истории админ-действий
final adminActionHistoryProvider =
    NotifierProvider<AdminActionHistoryNotifier, List<Map<String, dynamic>>>(
        () {
  return AdminActionHistoryNotifier();
});

/// Нотификатор для активных админ-действий
class ActiveAdminActionsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void addAction(String actionId) {
    state = {...state, actionId};
  }

  void removeAction(String actionId) {
    state = state.where((id) => id != actionId).toSet();
  }

  void clearActions() {
    state = {};
  }
}

/// Провайдер для активных админ-действий
final activeAdminActionsProvider =
    NotifierProvider<ActiveAdminActionsNotifier, Set<String>>(() {
  return ActiveAdminActionsNotifier();
});

/// Нотификатор для очереди админ-действий
class AdminActionQueueNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void addToQueue(Map<String, dynamic> action) {
    state = [...state, action];
  }

  void removeFromQueue(String actionId) {
    state = state.where((action) => action['id'] != actionId).toList();
  }

  void clearQueue() {
    state = [];
  }
}

/// Провайдер для очереди админ-действий
final adminActionQueueProvider =
    NotifierProvider<AdminActionQueueNotifier, List<Map<String, dynamic>>>(() {
  return AdminActionQueueNotifier();
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

/// Нотификатор для статистики админ-действий
class AdminActionStatsNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {
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

  void incrementStat(String key) {
    state = {...state, key: (state[key] ?? 0) + 1};
  }

  void resetStats() {
    state = {
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
  }
}

/// Провайдер для статистики админ-действий
final adminActionStatsProvider =
    NotifierProvider<AdminActionStatsNotifier, Map<String, int>>(() {
  return AdminActionStatsNotifier();
});

/// Нотификатор для последнего админ-действия
class LastAdminActionNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void setLastAction(Map<String, dynamic>? action) {
    state = action;
  }
}

/// Провайдер для последнего админ-действия
final lastAdminActionProvider =
    NotifierProvider<LastAdminActionNotifier, Map<String, dynamic>?>(() {
  return LastAdminActionNotifier();
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
