import 'package:flutter/material.dart';

/// Виджет для отображения состояния ошибки
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    required this.error, super.key,
    this.onRetry,
    this.title = 'Произошла ошибка',
    this.icon = Icons.error_outline,
    this.iconSize = 64,
    this.iconColor,
    this.titleStyle,
    this.messageStyle,
    this.buttonText = 'Повторить',
    this.padding = const EdgeInsets.all(24),
  });

  final String error;
  final VoidCallback? onRetry;
  final String title;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final String buttonText;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultIconColor = iconColor ?? theme.colorScheme.error;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: defaultIconColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: titleStyle ??
                  theme.textTheme.headlineSmall?.copyWith(
                    color: defaultIconColor,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: messageStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: defaultIconColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Виджет для отображения состояния "нет данных"
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    this.title = 'Нет данных',
    this.message = 'Здесь пока ничего нет',
    this.icon = Icons.inbox_outlined,
    this.iconSize = 64,
    this.iconColor,
    this.titleStyle,
    this.messageStyle,
    this.action,
    this.padding = const EdgeInsets.all(24),
  });

  final String title;
  final String message;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final Widget? action;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultIconColor = iconColor ?? Colors.grey[400];

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: defaultIconColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: titleStyle ??
                  theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: messageStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Виджет для отображения состояния сети
class NetworkErrorWidget extends StatelessWidget {
  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.message = 'Проверьте подключение к интернету',
  });

  final VoidCallback? onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      error: message,
      onRetry: onRetry,
      title: 'Нет подключения',
      icon: Icons.wifi_off,
    );
  }
}

/// Виджет для отображения состояния сервера
class ServerErrorWidget extends StatelessWidget {
  const ServerErrorWidget({
    super.key,
    this.onRetry,
    this.message = 'Сервер временно недоступен',
  });

  final VoidCallback? onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      error: message,
      onRetry: onRetry,
      title: 'Ошибка сервера',
      icon: Icons.cloud_off,
    );
  }
}

/// Виджет для отображения состояния авторизации
class AuthErrorWidget extends StatelessWidget {
  const AuthErrorWidget({
    super.key,
    this.onLogin,
    this.message = 'Необходимо войти в аккаунт',
  });

  final VoidCallback? onLogin;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      error: message,
      onRetry: onLogin,
      title: 'Требуется авторизация',
      icon: Icons.lock_outline,
      buttonText: 'Войти',
    );
  }
}

/// Виджет для отображения состояния разрешений
class PermissionErrorWidget extends StatelessWidget {
  const PermissionErrorWidget({
    super.key,
    this.onRequestPermission,
    this.message = 'Необходимо предоставить разрешения',
  });

  final VoidCallback? onRequestPermission;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      error: message,
      onRetry: onRequestPermission,
      title: 'Нет разрешений',
      icon: Icons.security,
      buttonText: 'Предоставить',
    );
  }
}

/// Виджет для отображения состояния с таймаутом
class TimeoutErrorWidget extends StatelessWidget {
  const TimeoutErrorWidget({
    super.key,
    this.onRetry,
    this.message = 'Превышено время ожидания',
  });

  final VoidCallback? onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      error: message,
      onRetry: onRetry,
      title: 'Таймаут',
      icon: Icons.timer_off,
    );
  }
}
