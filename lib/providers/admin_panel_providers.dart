import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_panel.dart';
import '../models/user.dart';
import '../services/admin_panel_service.dart';

/// Провайдер для сервиса админ-панели
final adminPanelServiceProvider = Provider<AdminPanelService>((ref) {
  return AdminPanelService();
});

/// Провайдер для проверки прав администратора
final isAdminProvider = FutureProvider.family<bool, String>((ref, userId) {
  final service = ref.read(adminPanelServiceProvider);
  return service.isAdmin(userId);
});

/// Провайдер для информации об администраторе
final adminInfoProvider =
    FutureProvider.family<AdminPanel?, String>((ref, userId) {
  final service = ref.read(adminPanelServiceProvider);
  return service.getAdminInfo(userId);
});

/// Провайдер для статистики админ-панели
final adminStatsProvider = FutureProvider<AdminStats>((ref) {
  final service = ref.read(adminPanelServiceProvider);
  return service.getStats();
});

/// Провайдер для всех пользователей
final allUsersProvider = StreamProvider((ref) {
  final service = ref.read(adminPanelServiceProvider);
  return service.getAllUsers();
});

/// Провайдер для всех специалистов
final allSpecialistsProvider = StreamProvider((ref) {
  final service = ref.read(adminPanelServiceProvider);
  return service.getAllSpecialists();
});

/// Провайдер для всех бронирований
final allBookingsProvider = StreamProvider((ref) {
  final service = ref.read(adminPanelServiceProvider);
  return service.getAllBookings();
});

/// Провайдер для всех платежей
final allPaymentsProvider = StreamProvider((ref) {
  final service = ref.read(adminPanelServiceProvider);
  return service.getAllPayments();
});

/// Провайдер для всех отзывов
final allReviewsProvider = StreamProvider((ref) {
  final service = ref.read(adminPanelServiceProvider);
  return service.getAllReviews();
});

/// Провайдер для действий администратора
final adminActionsProvider =
    StreamProvider.family<List<AdminAction>, int>((ref, limit) {
  final service = ref.read(adminPanelServiceProvider);
  return service.getAdminActions(limit: limit);
});

/// Провайдер для уведомлений администратора
final adminNotificationsProvider = StreamProvider((ref) {
  final service = ref.read(adminPanelServiceProvider);
  return service.getAdminNotifications();
});

/// Провайдер для настроек админ-панели
final adminSettingsProvider = FutureProvider((ref) {
  final service = ref.read(adminPanelServiceProvider);
  return service.getAdminSettings();
});

/// Провайдер для проверки разрешений администратора
final adminPermissionProvider =
    FutureProvider.family<bool, (String, AdminPermission)>((ref, params) {
  final (userId, permission) = params;
  final service = ref.read(adminPanelServiceProvider);
  return service.hasPermission(userId, permission);
});

/// Провайдер для фильтрации пользователей
final filteredUsersProvider =
    StreamProvider.family<List<AppUser>, UserFilter>((ref, filter) {
  return ref.watch(allUsersProvider).when(
        data: (users) {
          return Stream.value(users.where((user) {
            // Поиск по имени или email
            if (filter.searchQuery.isNotEmpty) {
              final query = filter.searchQuery.toLowerCase();
              if (!(user.displayName?.toLowerCase().contains(query) ?? false) &&
                  !user.email.toLowerCase().contains(query)) {
                return false;
              }
            }

            // Фильтр по роли
            if (filter.role != null && user.role != filter.role) {
              return false;
            }

            // Фильтр по статусу блокировки
            if (filter.showBannedOnly && user.isActive) {
              return false;
            }

            // Фильтр по дате создания
            if (filter.startDate != null &&
                user.createdAt.isBefore(filter.startDate!)) {
              return false;
            }

            if (filter.endDate != null &&
                user.createdAt.isAfter(filter.endDate!)) {
              return false;
            }

            return true;
          }).toList());
        },
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Фильтр для пользователей
class UserFilter {
  final String searchQuery;
  final UserRole? role;
  final bool showBannedOnly;
  final DateTime? startDate;
  final DateTime? endDate;

  UserFilter({
    this.searchQuery = '',
    this.role,
    this.showBannedOnly = false,
    this.startDate,
    this.endDate,
  });

  UserFilter copyWith({
    String? searchQuery,
    UserRole? role,
    bool? showBannedOnly,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return UserFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      role: role ?? this.role,
      showBannedOnly: showBannedOnly ?? this.showBannedOnly,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// Провайдер для фильтра пользователей
final userFilterProvider = StateProvider<UserFilter>((ref) {
  return const UserFilter();
});

/// Провайдер для статистики пользователей
final userStatsProvider = StreamProvider((ref) {
  return ref.watch(allUsersProvider).when(
        data: (users) {
          final totalUsers = users.length;
          final activeUsers = users.where((u) => u.isActive).length;
          final bannedUsers = users.where((u) => !u.isActive).length;
          final customers =
              users.where((u) => u.role == UserRole.customer).length;
          final specialists =
              users.where((u) => u.role == UserRole.specialist).length;

          return Stream.value(UserStats(
            totalUsers: totalUsers,
            activeUsers: activeUsers,
            bannedUsers: bannedUsers,
            customers: customers,
            specialists: specialists,
          ));
        },
        loading: () => Stream.value(UserStats.empty()),
        error: (_, __) => Stream.value(UserStats.empty()),
      );
});

/// Статистика пользователей
class UserStats {
  final int totalUsers;
  final int activeUsers;
  final int bannedUsers;
  final int customers;
  final int specialists;

  UserStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.bannedUsers,
    required this.customers,
    required this.specialists,
  });

  factory UserStats.empty() {
    return UserStats(
      totalUsers: 0,
      activeUsers: 0,
      bannedUsers: 0,
      customers: 0,
      specialists: 0,
    );
  }
}

/// Провайдер для поиска пользователей
final userSearchProvider =
    StreamProvider.family<List<AppUser>, String>((ref, query) {
  return ref.watch(allUsersProvider).when(
        data: (users) {
          if (query.isEmpty) return Stream.value(users);

          final filtered = users.where((user) {
            return (user.displayName
                        ?.toLowerCase()
                        .contains(query.toLowerCase()) ??
                    false) ||
                user.email.toLowerCase().contains(query.toLowerCase());
          }).toList();

          return Stream.value(filtered);
        },
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Провайдер для уведомлений о новых пользователях
final newUsersNotificationsProvider = StreamProvider((ref) {
  return ref.watch(allUsersProvider).when(
        data: (users) {
          final now = DateTime.now();
          final oneDayAgo = now.subtract(const Duration(days: 1));

          final newUsers =
              users.where((user) => user.createdAt.isAfter(oneDayAgo)).toList();

          return Stream.value(newUsers);
        },
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Провайдер для заблокированных пользователей
final bannedUsersProvider = StreamProvider((ref) {
  return ref.watch(allUsersProvider).when(
        data: (users) {
          return Stream.value(users.where((user) => !user.isActive).toList());
        },
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Провайдер для активных пользователей
final activeUsersProvider = StreamProvider((ref) {
  return ref.watch(allUsersProvider).when(
        data: (users) {
          final now = DateTime.now();
          final thirtyDaysAgo = now.subtract(const Duration(days: 30));

          final activeUsers = users.where((user) {
            if (!user.isActive) return false;
            if (user.lastLoginAt == null) return false;
            return user.lastLoginAt!.isAfter(thirtyDaysAgo);
          }).toList();

          return Stream.value(activeUsers);
        },
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});
