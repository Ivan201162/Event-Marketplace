import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../services/security_service.dart';

/// Экран настроек безопасности
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  final SecurityService _securityService = SecurityService();

  bool _biometricAuth = false;
  bool _pinAuth = false;
  bool _twoFactorAuth = false;
  bool _autoLock = true;
  int _autoLockTimeout = 5;
  bool _secureStorage = true;
  bool _dataEncryption = true;
  bool _auditLogging = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final currentUser = await ref.read(authServiceProvider).getCurrentUser();
      if (currentUser != null) {
        final settings =
            await _securityService.getSecuritySettings(currentUser.id);
        if (settings != null) {
          setState(() {
            _biometricAuth = settings.biometricAuth;
            _pinAuth = settings.pinAuth;
            _twoFactorAuth = settings.twoFactorAuth;
            _autoLock = settings.autoLock;
            _autoLockTimeout = settings.autoLockTimeout;
            _secureStorage = settings.secureStorage;
            _dataEncryption = settings.dataEncryption;
            _auditLogging = settings.auditLogging;
          });
        }
      }
    } catch (e) {
      print('Ошибка загрузки настроек безопасности: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Настройки безопасности'),
          actions: [
            IconButton(
              icon: const Icon(Icons.security),
              onPressed: _showSecurityInfo,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Аутентификация
              _buildAuthenticationSection(),

              const SizedBox(height: 24),

              // Автоблокировка
              _buildAutoLockSection(),

              const SizedBox(height: 24),

              // Шифрование данных
              _buildEncryptionSection(),

              const SizedBox(height: 24),

              // Аудит
              _buildAuditSection(),

              const SizedBox(height: 24),

              // Устройства
              _buildDevicesSection(),

              const SizedBox(height: 24),

              // Действия
              _buildActionsSection(),
            ],
          ),
        ),
      );

  Widget _buildAuthenticationSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Аутентификация',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Биометрическая аутентификация
              FutureBuilder<bool>(
                future: _securityService.isBiometricAvailable(),
                builder: (context, snapshot) {
                  final isAvailable = snapshot.data ?? false;
                  return SwitchListTile(
                    title: const Text('Биометрическая аутентификация'),
                    subtitle: Text(
                      isAvailable
                          ? 'Использовать отпечаток пальца или Face ID'
                          : 'Биометрическая аутентификация недоступна',
                    ),
                    value: _biometricAuth && isAvailable,
                    onChanged: isAvailable
                        ? (value) async {
                            if (value) {
                              final success = await _securityService
                                  .authenticateWithBiometrics(
                                reason:
                                    'Включить биометрическую аутентификацию',
                              );
                              if (success) {
                                setState(() {
                                  _biometricAuth = true;
                                });
                                _updateSecuritySettings();
                              }
                            } else {
                              setState(() {
                                _biometricAuth = false;
                              });
                              _updateSecuritySettings();
                            }
                          }
                        : null,
                  );
                },
              ),

              const Divider(),

              // PIN-код
              SwitchListTile(
                title: const Text('PIN-код'),
                subtitle: const Text('Использовать PIN-код для входа'),
                value: _pinAuth,
                onChanged: (value) async {
                  if (value) {
                    await _showPinSetupDialog();
                  } else {
                    await _showPinRemovalDialog();
                  }
                },
              ),

              const Divider(),

              // Двухфакторная аутентификация
              SwitchListTile(
                title: const Text('Двухфакторная аутентификация'),
                subtitle: const Text('Дополнительная защита аккаунта'),
                value: _twoFactorAuth,
                onChanged: (value) async {
                  if (value) {
                    await _showTwoFactorSetupDialog();
                  } else {
                    await _showTwoFactorDisableDialog();
                  }
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildAutoLockSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Автоблокировка',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Автоблокировка
              SwitchListTile(
                title: const Text('Автоблокировка'),
                subtitle: const Text('Автоматически блокировать приложение'),
                value: _autoLock,
                onChanged: (value) async {
                  setState(() {
                    _autoLock = value;
                  });
                  _updateSecuritySettings();
                },
              ),

              if (_autoLock) ...[
                const Divider(),

                // Таймаут автоблокировки
                ListTile(
                  title: const Text('Время автоблокировки'),
                  subtitle: Text('$_autoLockTimeout минут'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showTimeoutDialog,
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildEncryptionSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Шифрование данных',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Безопасное хранилище
              SwitchListTile(
                title: const Text('Безопасное хранилище'),
                subtitle: const Text('Хранить данные в зашифрованном виде'),
                value: _secureStorage,
                onChanged: (value) async {
                  setState(() {
                    _secureStorage = value;
                  });
                  _updateSecuritySettings();
                },
              ),

              const Divider(),

              // Шифрование данных
              SwitchListTile(
                title: const Text('Шифрование данных'),
                subtitle: const Text('Шифровать все пользовательские данные'),
                value: _dataEncryption,
                onChanged: (value) async {
                  setState(() {
                    _dataEncryption = value;
                  });
                  _updateSecuritySettings();
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildAuditSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Аудит безопасности',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Логирование аудита
              SwitchListTile(
                title: const Text('Логирование аудита'),
                subtitle: const Text('Записывать события безопасности'),
                value: _auditLogging,
                onChanged: (value) async {
                  setState(() {
                    _auditLogging = value;
                  });
                  _updateSecuritySettings();
                },
              ),

              const Divider(),

              // Просмотр логов
              ListTile(
                title: const Text('Просмотр логов безопасности'),
                subtitle: const Text('История событий безопасности'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showAuditLogs,
              ),
            ],
          ),
        ),
      );

  Widget _buildDevicesSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Устройства',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Управление устройствами
              ListTile(
                title: const Text('Управление устройствами'),
                subtitle: const Text(
                  'Просмотр и управление подключенными устройствами',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showDevicesManagement,
              ),

              const Divider(),

              // Текущее устройство
              ListTile(
                title: const Text('Текущее устройство'),
                subtitle: const Text('Информация о текущем устройстве'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showCurrentDeviceInfo,
              ),
            ],
          ),
        ),
      );

  Widget _buildActionsSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Действия',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Изменить пароль
              ListTile(
                title: const Text('Изменить пароль'),
                subtitle: const Text('Обновить пароль аккаунта'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changePassword,
              ),

              const Divider(),

              // Очистить данные
              ListTile(
                title: const Text('Очистить безопасные данные'),
                subtitle: const Text('Удалить все зашифрованные данные'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _clearSecureData,
              ),

              const Divider(),

              // Экспорт данных
              ListTile(
                title: const Text('Экспорт данных безопасности'),
                subtitle: const Text('Скачать настройки безопасности'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _exportSecurityData,
              ),
            ],
          ),
        ),
      );

  Future<void> _updateSecuritySettings() async {
    try {
      final currentUser = await ref.read(authServiceProvider).getCurrentUser();
      if (currentUser != null) {
        final settings = SecuritySettings(
          userId: currentUser.id,
          biometricAuth: _biometricAuth,
          pinAuth: _pinAuth,
          twoFactorAuth: _twoFactorAuth,
          autoLock: _autoLock,
          autoLockTimeout: _autoLockTimeout,
          secureStorage: _secureStorage,
          dataEncryption: _dataEncryption,
          auditLogging: _auditLogging,
          lastPasswordChange: DateTime.now(),
          lastSecurityUpdate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _securityService.updateSecuritySettings(settings);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Настройки безопасности обновлены'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления настроек: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPinSetupDialog() async {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Установка PIN-кода'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Введите 4-значный PIN-код:'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = pinController.text;
              if (pin.length == 4) {
                final success = await _securityService.setPinCode(pin);
                if (success) {
                  setState(() {
                    _pinAuth = true;
                  });
                  _updateSecuritySettings();
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PIN-код установлен'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ошибка установки PIN-кода'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Установить'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPinRemovalDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление PIN-кода'),
        content: const Text('Вы уверены, что хотите удалить PIN-код?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _securityService.removePinCode();
              if (success) {
                setState(() {
                  _pinAuth = false;
                });
                _updateSecuritySettings();
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN-код удален'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTwoFactorSetupDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Двухфакторная аутентификация'),
        content: const Text(
          'Функция двухфакторной аутентификации будет доступна в следующих обновлениях.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTwoFactorDisableDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отключение двухфакторной аутентификации'),
        content: const Text(
          'Функция двухфакторной аутентификации будет доступна в следующих обновлениях.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Время автоблокировки'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Выберите время автоблокировки:'),
            const SizedBox(height: 16),
            ...List.generate(5, (index) {
              final minutes = (index + 1) * 5;
              return RadioListTile<int>(
                title: Text('$minutes минут'),
                value: minutes,
                groupValue: _autoLockTimeout,
                onChanged: (value) {
                  setState(() {
                    _autoLockTimeout = value!;
                  });
                  _updateSecuritySettings();
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showSecurityInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('О безопасности'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Приложение использует современные методы защиты:'),
            SizedBox(height: 8),
            Text('• Шифрование AES-256'),
            Text('• Биометрическая аутентификация'),
            Text('• Безопасное хранилище'),
            Text('• Аудит безопасности'),
            Text('• Управление устройствами'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showAuditLogs() {
    // TODO: Реализовать просмотр логов аудита
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Просмотр логов аудита будет доступен в следующих обновлениях',
        ),
      ),
    );
  }

  void _showDevicesManagement() {
    // TODO: Реализовать управление устройствами
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Управление устройствами будет доступно в следующих обновлениях',
        ),
      ),
    );
  }

  void _showCurrentDeviceInfo() {
    // TODO: Реализовать отображение информации об устройстве
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Информация об устройстве будет доступна в следующих обновлениях',
        ),
      ),
    );
  }

  void _changePassword() {
    // TODO: Реализовать изменение пароля
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Изменение пароля будет доступно в следующих обновлениях'),
      ),
    );
  }

  void _clearSecureData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистка данных'),
        content: const Text(
          'Вы уверены, что хотите удалить все зашифрованные данные? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _securityService.clearAllSecureData();
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Безопасные данные очищены'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  void _exportSecurityData() {
    // TODO: Реализовать экспорт данных безопасности
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Экспорт данных безопасности будет доступен в следующих обновлениях',
        ),
      ),
    );
  }
}
