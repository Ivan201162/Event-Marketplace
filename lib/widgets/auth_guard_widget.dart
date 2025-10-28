import 'package:event_marketplace_app/models/user.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Виджет-защитник для проверки аутентификации
class AuthGuard extends ConsumerWidget {
  const AuthGuard({
    required this.child, super.key,
    this.loadingWidget,
    this.unauthenticatedWidget,
    this.allowedRoles,
    this.requireAuth = true,
  });
  final Widget child;
  final Widget? loadingWidget;
  final Widget? unauthenticatedWidget;
  final List<UserRole>? allowedRoles;
  final bool requireAuth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Если аутентификация не требуется, показываем дочерний виджет
    if (!requireAuth) {
      return child;
    }

    return currentUser.when(
      data: (user) {
        // Пользователь не авторизован
        if (user == null) {
          return unauthenticatedWidget ?? _buildUnauthenticatedWidget(context);
        }

        // Проверяем роли, если они указаны
        if (allowedRoles != null && !allowedRoles!.contains(user.role)) {
          return _buildUnauthorizedWidget(context, user.role);
        }

        // Пользователь авторизован и имеет нужную роль
        return child;
      },
      loading: () => loadingWidget ?? _buildLoadingWidget(context),
      error: (error, stackTrace) => _buildErrorWidget(context, error),
    );
  }

  /// Виджет загрузки
  Widget _buildLoadingWidget(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Проверка авторизации...'),
            ],
          ),
        ),
      );

  /// Виджет для неавторизованных пользователей
  Widget _buildUnauthenticatedWidget(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline,
                    size: 64, color: Theme.of(context).colorScheme.primary,),
                const SizedBox(height: 24),
                Text(
                  'Требуется авторизация',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Для доступа к этому разделу необходимо войти в систему',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO(developer): Навигация к экрану авторизации
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(
                        content: Text('Переход к экрану авторизации'),),);
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Войти'),
                ),
              ],
            ),
          ),
        ),
      );

  /// Виджет для пользователей без нужных прав
  Widget _buildUnauthorizedWidget(BuildContext context, UserRole userRole) =>
      Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block,
                    size: 64, color: Theme.of(context).colorScheme.error,),
                const SizedBox(height: 24),
                Text(
                  'Недостаточно прав',
                  style: Theme.of(
                    context,
                  )
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ваша роль: ${userRole.roleDisplayName}\n\nДля доступа к этому разделу требуется другая роль',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Назад'),
                ),
              ],
            ),
          ),
        ),
      );

  /// Виджет ошибки
  Widget _buildErrorWidget(BuildContext context, Object error) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Theme.of(context).colorScheme.error,),
                const SizedBox(height: 24),
                Text(
                  'Ошибка авторизации',
                  style: Theme.of(
                    context,
                  )
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Произошла ошибка при проверке авторизации: $error',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO(developer): Попытка повторной авторизации
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(
                        content: Text('Попытка повторной авторизации'),),);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Виджет для условного отображения контента в зависимости от роли
class RoleBasedWidget extends ConsumerWidget {
  const RoleBasedWidget({
    required this.customerWidget, required this.specialistWidget, super.key,
    this.guestWidget,
    this.adminWidget,
    this.fallbackWidget,
  });
  final Widget customerWidget;
  final Widget specialistWidget;
  final Widget? guestWidget;
  final Widget? adminWidget;
  final Widget? fallbackWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      data: (user) {
        if (user == null) {
          return fallbackWidget ?? const SizedBox.shrink();
        }

        switch (user.role) {
          case UserRole.customer:
            return customerWidget;
          case UserRole.specialist:
            return specialistWidget;
          case UserRole.organizer:
            return customerWidget; // Используем customer widget для organizer
          case UserRole.moderator:
            return adminWidget ?? fallbackWidget ?? const SizedBox.shrink();
          case UserRole.guest:
            return guestWidget ?? fallbackWidget ?? const SizedBox.shrink();
          case UserRole.admin:
            return adminWidget ?? fallbackWidget ?? const SizedBox.shrink();
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => fallbackWidget ?? const SizedBox.shrink(),
    );
  }
}

/// Виджет для отображения информации о пользователе с fallback
class UserInfoWidget extends ConsumerWidget {
  const UserInfoWidget({required this.builder, super.key, this.fallbackWidget});
  final Widget Function(AppUser user) builder;
  final Widget? fallbackWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      data: (user) {
        if (user == null) {
          return fallbackWidget ?? const SizedBox.shrink();
        }
        return builder(user);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => fallbackWidget ?? const SizedBox.shrink(),
    );
  }
}
