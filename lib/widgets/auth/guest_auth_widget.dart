import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';

/// Виджет авторизации как гость
class GuestAuthWidget extends ConsumerStatefulWidget {
  const GuestAuthWidget({super.key});

  @override
  ConsumerState<GuestAuthWidget> createState() => _GuestAuthWidgetState();
}

class _GuestAuthWidgetState extends ConsumerState<GuestAuthWidget> {
  Future<void> _signInAsGuest() async {
    final authService = ref.read(authServiceProvider);
    final authLoading = ref.read(authLoadingProvider.notifier);
    final authError = ref.read(authErrorProvider.notifier);

    try {
      authLoading.setLoading(true);
      authError.clearError();

      await authService.signInAsGuest();

      // Переход на главный экран
      if (mounted) {
        context.go('/main');
      }
    } on Exception catch (e) {
      authError.setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      authLoading.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Иконка гостя
          Container(
            width: 70,
            height: 70,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.person_outline,
              size: 35,
              color: theme.primaryColor,
            ),
          ),

          // Заголовок
          Text(
            'Вход как гость',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          Text(
            'Просматривайте контент без регистрации',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Кнопка входа как гость
          ElevatedButton(
            onPressed: _signInAsGuest,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Войти как гость',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Информация о возможностях гостя
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Возможности гостя:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  theme,
                  Icons.visibility,
                  'Просмотр публичного контента',
                ),
                _buildFeatureItem(
                  theme,
                  Icons.search,
                  'Поиск специалистов',
                ),
                _buildFeatureItem(
                  theme,
                  Icons.lightbulb_outline,
                  'Просмотр идей и портфолио',
                ),
                _buildFeatureItem(
                  theme,
                  Icons.info_outline,
                  'Ограниченный функционал',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Предупреждение
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_outlined,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Для полного доступа к функциям приложения рекомендуется зарегистрироваться',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Дополнительный отступ снизу для безопасности
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(ThemeData theme, IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
}
