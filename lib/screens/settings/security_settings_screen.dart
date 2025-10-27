import 'package:flutter/material.dart';
import '../../models/user_profile_enhanced.dart';
import '../../services/user_profile_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/security/two_factor_setup_widget.dart';
import '../../widgets/security/sessions_list_widget.dart';
import '../../widgets/security/login_history_widget.dart';

/// Экран настроек безопасности
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _userProfileService = UserProfileService();
  final _authService = AuthService();

  UserProfileEnhanced? _currentProfile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Загрузить профиль пользователя
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _userProfileService.getCurrentUserProfile();
      if (profile != null) {
        setState(() => _currentProfile = profile);
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки профиля: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Сменить пароль
  Future<void> _changePassword() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ChangePasswordDialog(),
    );

    if (result != null) {
      try {
        setState(() => _isLoading = true);

        // TODO: Реализовать смену пароля через Firebase Auth
        await Future.delayed(const Duration(seconds: 1)); // Заглушка

        _showSuccessSnackBar('Пароль успешно изменен');
      } catch (e) {
        _showErrorSnackBar('Ошибка смены пароля: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Настроить 2FA
  Future<void> _setupTwoFactor() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TwoFactorSetupWidget(
          currentSettings: _currentProfile?.securitySettings,
        ),
      ),
    );

    if (result == true) {
      _loadUserProfile();
    }
  }

  /// Управление сессиями
  Future<void> _manageSessions() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionsListWidget(
          sessions: _currentProfile?.securitySettings?.sessions ?? [],
        ),
      ),
    );
  }

  /// История входов
  Future<void> _viewLoginHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoginHistoryWidget(
          loginHistory: _currentProfile?.securitySettings?.loginHistory ?? [],
        ),
      ),
    );
  }

  /// Сменить email
  Future<void> _changeEmail() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _ChangeEmailDialog(
        currentEmail: _currentProfile?.email ?? '',
      ),
    );

    if (result != null) {
      try {
        setState(() => _isLoading = true);

        // TODO: Реализовать смену email через Firebase Auth
        await Future.delayed(const Duration(seconds: 1)); // Заглушка

        _showSuccessSnackBar('Email успешно изменен');
      } catch (e) {
        _showErrorSnackBar('Ошибка смены email: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Сменить номер телефона
  Future<void> _changePhone() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _ChangePhoneDialog(
        currentPhone: _currentProfile?.phone ?? '',
      ),
    );

    if (result != null) {
      try {
        setState(() => _isLoading = true);

        // TODO: Реализовать смену номера телефона
        await Future.delayed(const Duration(seconds: 1)); // Заглушка

        _showSuccessSnackBar('Номер телефона успешно изменен');
      } catch (e) {
        _showErrorSnackBar('Ошибка смены номера: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Привязать Google аккаунт
  Future<void> _linkGoogleAccount() async {
    try {
      setState(() => _isLoading = true);

      // TODO: Реализовать привязку Google аккаунта
      await Future.delayed(const Duration(seconds: 1)); // Заглушка

      _showSuccessSnackBar('Google аккаунт успешно привязан');
    } catch (e) {
      _showErrorSnackBar('Ошибка привязки Google: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Отвязать Google аккаунт
  Future<void> _unlinkGoogleAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отвязать Google аккаунт'),
        content: const Text(
          'Вы уверены, что хотите отвязать Google аккаунт? '
          'Вы не сможете входить через Google.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Отвязать'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        // TODO: Реализовать отвязку Google аккаунта
        await Future.delayed(const Duration(seconds: 1)); // Заглушка

        _showSuccessSnackBar('Google аккаунт отвязан');
      } catch (e) {
        _showErrorSnackBar('Ошибка отвязки Google: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Удалить аккаунт
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аккаунт'),
        content: const Text(
          'Вы уверены, что хотите удалить аккаунт? '
          'Это действие необратимо и все ваши данные будут удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        // TODO: Реализовать удаление аккаунта
        await Future.delayed(const Duration(seconds: 1)); // Заглушка

        _showSuccessSnackBar('Аккаунт удален');
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } catch (e) {
        _showErrorSnackBar('Ошибка удаления аккаунта: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Безопасность'),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Аутентификация
            _buildAuthenticationSection(),
            const SizedBox(height: 16),

            // Двухфакторная аутентификация
            _buildTwoFactorSection(),
            const SizedBox(height: 16),

            // Сессии
            _buildSessionsSection(),
            const SizedBox(height: 16),

            // Контактная информация
            _buildContactInfoSection(),
            const SizedBox(height: 16),

            // Социальные аккаунты
            _buildSocialAccountsSection(),
            const SizedBox(height: 16),

            // Опасная зона
            _buildDangerZoneSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Аутентификация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Сменить пароль'),
              subtitle: const Text('Обновите пароль для безопасности'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _changePassword,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoFactorSection() {
    final isTwoFactorEnabled =
        _currentProfile?.securitySettings?.twoFactorEnabled ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Двухфакторная аутентификация',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: isTwoFactorEnabled,
                  onChanged: (value) => _setupTwoFactor(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isTwoFactorEnabled
                  ? '2FA включена'
                  : 'Дополнительная защита аккаунта',
              style: const TextStyle(color: Colors.grey),
            ),
            if (isTwoFactorEnabled) ...[
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Настроить 2FA'),
                subtitle: const Text('Изменить метод аутентификации'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _setupTwoFactor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Активные сессии',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Управление сессиями'),
              subtitle: const Text('Просмотр и завершение сессий'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _manageSessions,
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('История входов'),
              subtitle: const Text('Просмотр истории авторизации'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _viewLoginHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Контактная информация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Сменить email'),
              subtitle: Text(_currentProfile?.email ?? 'Не указан'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _changeEmail,
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Сменить номер телефона'),
              subtitle: Text(_currentProfile?.phone ?? 'Не указан'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _changePhone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialAccountsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Социальные аккаунты',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.account_circle, color: Colors.blue),
              title: const Text('Google аккаунт'),
              subtitle: const Text('Привязать или отвязать Google'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Проверить статус привязки Google
                _linkGoogleAccount();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneSection() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Опасная зона',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Удалить аккаунт'),
              subtitle: const Text('Безвозвратно удалить аккаунт и все данные'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _deleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}

/// Диалог смены пароля
class _ChangePasswordDialog extends StatefulWidget {
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'currentPassword': _currentPasswordController.text,
        'newPassword': _newPasswordController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сменить пароль'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Текущий пароль',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              obscureText: _obscureCurrent,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите текущий пароль';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'Новый пароль',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureNew ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              obscureText: _obscureNew,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите новый пароль';
                }
                if (value.length < 6) {
                  return 'Пароль должен содержать минимум 6 символов';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Подтвердите пароль',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              obscureText: _obscureConfirm,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Подтвердите пароль';
                }
                if (value != _newPasswordController.text) {
                  return 'Пароли не совпадают';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

/// Диалог смены email
class _ChangeEmailDialog extends StatefulWidget {
  const _ChangeEmailDialog({required this.currentEmail});

  final String currentEmail;

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();

  @override
  void dispose() {
    _newEmailController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_newEmailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сменить email'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Текущий email: ${widget.currentEmail}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newEmailController,
              decoration: const InputDecoration(
                labelText: 'Новый email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите новый email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Введите корректный email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

/// Диалог смены номера телефона
class _ChangePhoneDialog extends StatefulWidget {
  const _ChangePhoneDialog({required this.currentPhone});

  final String currentPhone;

  @override
  State<_ChangePhoneDialog> createState() => _ChangePhoneDialogState();
}

class _ChangePhoneDialogState extends State<_ChangePhoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newPhoneController = TextEditingController();

  @override
  void dispose() {
    _newPhoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_newPhoneController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сменить номер телефона'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Текущий номер: ${widget.currentPhone.isEmpty ? 'Не указан' : widget.currentPhone}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPhoneController,
              decoration: const InputDecoration(
                labelText: 'Новый номер телефона',
                border: OutlineInputBorder(),
                hintText: '+7 (999) 123-45-67',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите новый номер';
                }
                if (!RegExp(r'^\+?[1-9]\d{1,14}$')
                    .hasMatch(value.replaceAll(RegExp(r'[^\d+]'), ''))) {
                  return 'Введите корректный номер телефона';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
