import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../models/user.dart';
import 'reset_password_screen.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(loginFormProvider);
    final isLoading = ref.watch(isLoadingAuthProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // Логотип и заголовок
              _buildHeader(context),

              const SizedBox(height: 48),

              // Форма входа/регистрации
              _buildAuthForm(context, ref, formState),

              const SizedBox(height: 24),

              // Кнопка входа через Google
              _buildGoogleSignInButton(context, ref),
              const SizedBox(height: 16),

              // Кнопка входа как гость
              if (!formState.isSignUpMode) ...[
                _buildGuestButton(context, ref),
                const SizedBox(height: 16),
              ],

              // Дополнительные действия
              _buildAdditionalActions(context, ref, formState),
            ],
          ),
        ),
      ),
    );
  }

  /// Построение заголовка
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.event,
            size: 40,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Event Marketplace',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Найдите идеального специалиста для вашего мероприятия',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Построение формы аутентификации
  Widget _buildAuthForm(
      BuildContext context, WidgetRef ref, LoginFormState formState) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок формы
            Text(
              formState.isSignUpMode ? 'Регистрация' : 'Вход',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Поля формы
            if (formState.isSignUpMode) ...[
              _buildDisplayNameField(context, ref),
              const SizedBox(height: 16),
              _buildRoleSelector(context, ref),
              const SizedBox(height: 16),
            ],

            _buildEmailField(context, ref, formState),
            const SizedBox(height: 16),
            _buildPasswordField(context, ref, formState),

            const SizedBox(height: 24),

            // Кнопка отправки
            _buildSubmitButton(context, ref, formState),

            // Ошибка
            if (formState.errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(context, formState.errorMessage!),
            ],

            // Разделитель
            const SizedBox(height: 24),
            _buildDivider(context),
            const SizedBox(height: 24),

            // Кнопки социальных сетей
            _buildSocialButtons(context, ref, formState),
          ],
        ),
      ),
    );
  }

  /// Поле для имени пользователя
  Widget _buildDisplayNameField(BuildContext context, WidgetRef ref) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Имя',
        hintText: 'Введите ваше имя',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        // Сохраняем имя в локальном состоянии
        ref.read(loginFormProvider.notifier).updateDisplayName(value);
      },
    );
  }

  /// Селектор роли
  Widget _buildRoleSelector(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final selectedRole = ref.watch(selectedRoleProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Роль',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<UserRole>(
                    title: const Text('Заказчик'),
                    subtitle: const Text('Ищу специалистов'),
                    value: UserRole.customer,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(selectedRoleProvider.notifier).state = value;
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<UserRole>(
                    title: const Text('Специалист'),
                    subtitle: const Text('Предоставляю услуги'),
                    value: UserRole.specialist,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(selectedRoleProvider.notifier).state = value;
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Поле для email
  Widget _buildEmailField(
      BuildContext context, WidgetRef ref, LoginFormState formState) {
    return TextFormField(
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'Введите ваш email',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) =>
          ref.read(loginFormProvider.notifier).updateEmail(value),
    );
  }

  /// Поле для пароля
  Widget _buildPasswordField(
      BuildContext context, WidgetRef ref, LoginFormState formState) {
    return TextFormField(
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Пароль',
        hintText: 'Введите пароль',
        prefixIcon: Icon(Icons.lock),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) =>
          ref.read(loginFormProvider.notifier).updatePassword(value),
    );
  }

  /// Кнопка отправки
  Widget _buildSubmitButton(
      BuildContext context, WidgetRef ref, LoginFormState formState) {
    return ElevatedButton(
      onPressed: formState.isLoading
          ? null
          : () {
              if (formState.isSignUpMode) {
                _handleSignUp(context, ref);
              } else {
                ref.read(loginFormProvider.notifier).signIn();
              }
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: formState.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              formState.isSignUpMode ? 'Зарегистрироваться' : 'Войти',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  /// Кнопка входа как гость
  Widget _buildGuestButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => ref.read(loginFormProvider.notifier).signInAsGuest(),
      icon: const Icon(Icons.person_outline),
      label: const Text('Войти как гость'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Дополнительные действия
  Widget _buildAdditionalActions(
      BuildContext context, WidgetRef ref, LoginFormState formState) {
    return Column(
      children: [
        // Переключение режима
        TextButton(
          onPressed: () =>
              ref.read(loginFormProvider.notifier).toggleSignUpMode(),
          child: Text(
            formState.isSignUpMode
                ? 'Уже есть аккаунт? Войти'
                : 'Нет аккаунта? Зарегистрироваться',
          ),
        ),

        // Сброс пароля
        if (!formState.isSignUpMode) ...[
          TextButton(
            onPressed: () => _showResetPasswordDialog(context, ref),
            child: const Text('Забыли пароль?'),
          ),
        ],
      ],
    );
  }

  /// Сообщение об ошибке
  Widget _buildErrorMessage(BuildContext context, String message) {
    final isSuccess = message.contains('отправлено');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isSuccess ? Colors.green : Colors.red,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Обработка регистрации
  void _handleSignUp(BuildContext context, WidgetRef ref) {
    final displayName = ref.read(displayNameProvider);
    final role = ref.read(selectedRoleProvider);

    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя')),
      );
      return;
    }

    ref.read(loginFormProvider.notifier).signUp(
          displayName: displayName,
          role: role,
        );
  }

  /// Показать диалог сброса пароля
  void _showResetPasswordDialog(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ResetPasswordScreen(),
      ),
    );
  }

  /// Разделитель
  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'или',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }

  /// Кнопки социальных сетей
  Widget _buildSocialButtons(
      BuildContext context, WidgetRef ref, LoginFormState formState) {
    return Column(
      children: [
        // Кнопка Google
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: formState.isLoading
                ? null
                : () => _handleGoogleSignIn(context, ref),
            icon: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                      'https://developers.google.com/identity/images/g-logo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            label: const Text('Войти через Google'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Кнопка ВКонтакте
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: formState.isLoading
                ? null
                : () => _handleVKSignIn(context, ref),
            icon: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF0077FF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'VK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            label: const Text('Войти через ВКонтакте'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Обработка входа через Google
  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    try {
      final role = ref.read(selectedRoleProvider);
      final authService = ref.read(authServiceProvider);

      final user = await authService.signInWithGoogle(role: role);
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Добро пожаловать, ${user.displayNameOrEmail}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка входа через Google: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Кнопка входа через Google
  Widget _buildGoogleSignInButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleGoogleSignIn(context, ref),
        icon: const Icon(Icons.login),
        label: const Text('Войти через Google'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  /// Обработка входа через ВКонтакте
  Future<void> _handleVKSignIn(BuildContext context, WidgetRef ref) async {
    try {
      final role = ref.read(selectedRoleProvider);
      final authService = ref.read(authServiceProvider);

      final user = await authService.signInWithVK(role: role);
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Добро пожаловать, ${user.displayNameOrEmail}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка входа через ВКонтакте: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Провайдеры для локального состояния формы
final displayNameProvider = StateProvider<String>((ref) => '');
final selectedRoleProvider =
    StateProvider<UserRole>((ref) => UserRole.customer);

/// Расширение для LoginFormNotifier
extension LoginFormNotifierExtension on LoginFormNotifier {
  void updateDisplayName(String displayName) {
    // Это будет использоваться в _handleSignUp
  }
}
