import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Обёртка для поддержки свайпов назад
class SwipeBackWrapper extends StatelessWidget {
  const SwipeBackWrapper({
    required this.child, super.key,
    this.enableSwipeBack = true,
    this.swipeThreshold = 100.0,
    this.onSwipeBack,
  });

  final Widget child;
  final bool enableSwipeBack;
  final double swipeThreshold;
  final VoidCallback? onSwipeBack;

  @override
  Widget build(BuildContext context) {
    if (!enableSwipeBack) {
      return child;
    }

    return GestureDetector(
      onPanUpdate: (details) {
        // Обрабатываем свайп вправо для возврата назад
        if (details.delta.dx > 0) {
          // Свайп вправо - возврат назад
          _handleSwipeBack(context);
        }
      },
      onPanEnd: (details) {
        // Проверяем, достаточно ли сильный был свайп
        if (details.velocity.pixelsPerSecond.dx > swipeThreshold) {
          _handleSwipeBack(context);
        }
      },
      child: child,
    );
  }

  void _handleSwipeBack(BuildContext context) {
    if (context.canPop()) {
      if (onSwipeBack != null) {
        onSwipeBack!();
      } else {
        // Плавный возврат с анимацией
        context.pop();
      }
    } else {
      // Если нельзя вернуться назад, переходим на главную
      context.go('/main');
    }
  }
}

/// Расширение для GoRouter с поддержкой свайпов
extension GoRouterSwipeExtension on GoRouter {
  /// Переход с поддержкой свайпов
  void goWithSwipe(String location, {Object? extra}) {
    go(location, extra: extra);
  }

  /// Push с поддержкой свайпов
  void pushWithSwipe(String location, {Object? extra}) {
    push(location, extra: extra);
  }
}

/// Миксин для экранов с поддержкой свайпов
mixin SwipeBackMixin<T extends StatefulWidget> on State<T> {
  bool _isSwipeBackEnabled = true;
  double _swipeThreshold = 100;

  /// Включить/выключить свайп назад
  void setSwipeBackEnabled(bool enabled) {
    setState(() {
      _isSwipeBackEnabled = enabled;
    });
  }

  /// Установить порог для свайпа
  void setSwipeThreshold(double threshold) {
    setState(() {
      _swipeThreshold = threshold;
    });
  }

  /// Обработать свайп назад
  void handleSwipeBack() {
    if (mounted && context.canPop()) {
      context.pop();
    }
  }

  /// Обернуть виджет в SwipeBackWrapper
  Widget wrapWithSwipeBack(Widget child) => SwipeBackWrapper(
        enableSwipeBack: _isSwipeBackEnabled,
        swipeThreshold: _swipeThreshold,
        onSwipeBack: handleSwipeBack,
        child: child,
      );
}

/// Виджет для быстрого возврата на главную
class QuickHomeButton extends StatelessWidget {
  const QuickHomeButton({
    super.key,
    this.icon = Icons.home,
    this.tooltip = 'На главную',
    this.position = FloatingActionButtonLocation.endFloat,
  });

  final IconData icon;
  final String tooltip;
  final FloatingActionButtonLocation position;

  @override
  Widget build(BuildContext context) => FloatingActionButton(
        onPressed: () {
          context.go('/main');
        },
        tooltip: tooltip,
        child: Icon(icon),
      );
}

/// Виджет для быстрого доступа к профилю
class QuickProfileButton extends StatelessWidget {
  const QuickProfileButton(
      {super.key, this.icon = Icons.person, this.tooltip = 'Профиль',});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () {
          context.push('/profile');
        },
        icon: Icon(icon),
        tooltip: tooltip,
      );
}

/// Виджет для навигационной панели с быстрыми действиями
class QuickNavigationBar extends StatelessWidget {
  const QuickNavigationBar({
    super.key,
    this.showHome = true,
    this.showProfile = true,
    this.showSearch = true,
    this.showNotifications = true,
  });

  final bool showHome;
  final bool showProfile;
  final bool showSearch;
  final bool showNotifications;

  @override
  Widget build(BuildContext context) => Container(
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (showHome)
              _buildQuickAction(
                context,
                icon: Icons.home,
                label: 'Главная',
                onTap: () => context.go('/main'),
              ),
            if (showSearch)
              _buildQuickAction(
                context,
                icon: Icons.search,
                label: 'Поиск',
                onTap: () => context.push('/home'),
              ),
            if (showNotifications)
              _buildQuickAction(
                context,
                icon: Icons.notifications,
                label: 'Уведомления',
                onTap: () {
                  // TODO: Переход к уведомлениям
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Уведомления')));
                },
              ),
            if (showProfile)
              _buildQuickAction(
                context,
                icon: Icons.person,
                label: 'Профиль',
                onTap: () => context.push('/profile'),
              ),
          ],
        ),
      );

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 24, color: Theme.of(context).colorScheme.onSurface,),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface,),),
          ],
        ),
      );
}
