import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/fcm_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  final FCMService _fcmService = FCMService();
  
  bool _pushNotificationsEnabled = true;
  bool _bookingNotificationsEnabled = true;
  bool _paymentNotificationsEnabled = true;
  bool _chatNotificationsEnabled = true;
  bool _marketingNotificationsEnabled = false;
  bool _reminderNotificationsEnabled = true;
  int _reminderTime = 30; // минуты до события

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Загрузить настройки
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotificationsEnabled = prefs.getBool('push_notifications_enabled') ?? true;
      _bookingNotificationsEnabled = prefs.getBool('booking_notifications_enabled') ?? true;
      _paymentNotificationsEnabled = prefs.getBool('payment_notifications_enabled') ?? true;
      _chatNotificationsEnabled = prefs.getBool('chat_notifications_enabled') ?? true;
      _marketingNotificationsEnabled = prefs.getBool('marketing_notifications_enabled') ?? false;
      _reminderNotificationsEnabled = prefs.getBool('reminder_notifications_enabled') ?? true;
      _reminderTime = prefs.getInt('reminder_time') ?? 30;
    });
  }

  /// Сохранить настройки
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', _pushNotificationsEnabled);
    await prefs.setBool('booking_notifications_enabled', _bookingNotificationsEnabled);
    await prefs.setBool('payment_notifications_enabled', _paymentNotificationsEnabled);
    await prefs.setBool('chat_notifications_enabled', _chatNotificationsEnabled);
    await prefs.setBool('marketing_notifications_enabled', _marketingNotificationsEnabled);
    await prefs.setBool('reminder_notifications_enabled', _reminderNotificationsEnabled);
    await prefs.setInt('reminder_time', _reminderTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки уведомлений'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSystemSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Общие настройки
            _buildSection(
              title: 'Общие настройки',
              children: [
                _buildSwitchTile(
                  title: 'Push-уведомления',
                  subtitle: 'Включить все push-уведомления',
                  value: _pushNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _pushNotificationsEnabled = value;
                      if (!value) {
                        // Отключить все остальные уведомления
                        _bookingNotificationsEnabled = false;
                        _paymentNotificationsEnabled = false;
                        _chatNotificationsEnabled = false;
                        _marketingNotificationsEnabled = false;
                        _reminderNotificationsEnabled = false;
                      }
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Уведомления о заявках
            _buildSection(
              title: 'Заявки',
              children: [
                _buildSwitchTile(
                  title: 'Уведомления о заявках',
                  subtitle: 'Подтверждение, отклонение, отмена заявок',
                  value: _bookingNotificationsEnabled,
                  enabled: _pushNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _bookingNotificationsEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Уведомления о платежах
            _buildSection(
              title: 'Платежи',
              children: [
                _buildSwitchTile(
                  title: 'Уведомления о платежах',
                  subtitle: 'Завершение, неудача платежей',
                  value: _paymentNotificationsEnabled,
                  enabled: _pushNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _paymentNotificationsEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Уведомления о чатах
            _buildSection(
              title: 'Сообщения',
              children: [
                _buildSwitchTile(
                  title: 'Уведомления о сообщениях',
                  subtitle: 'Новые сообщения в чатах',
                  value: _chatNotificationsEnabled,
                  enabled: _pushNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _chatNotificationsEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Напоминания
            _buildSection(
              title: 'Напоминания',
              children: [
                _buildSwitchTile(
                  title: 'Напоминания о событиях',
                  subtitle: 'Уведомления перед началом мероприятия',
                  value: _reminderNotificationsEnabled,
                  enabled: _pushNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _reminderNotificationsEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
                
                if (_reminderNotificationsEnabled) ...[
                  const SizedBox(height: 16),
                  _buildSliderTile(
                    title: 'Время напоминания',
                    subtitle: 'За сколько минут до события',
                    value: _reminderTime.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    onChanged: (value) {
                      setState(() {
                        _reminderTime = value.round();
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Маркетинговые уведомления
            _buildSection(
              title: 'Маркетинг',
              children: [
                _buildSwitchTile(
                  title: 'Маркетинговые уведомления',
                  subtitle: 'Акции, скидки, новые услуги',
                  value: _marketingNotificationsEnabled,
                  enabled: _pushNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _marketingNotificationsEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Информация о FCM токене
            _buildSection(
              title: 'Техническая информация',
              children: [
                _buildInfoTile(
                  title: 'FCM токен',
                  subtitle: _fcmService.fcmToken ?? 'Не получен',
                  onTap: () => _copyFCMToken(),
                ),
                
                const SizedBox(height: 8),
                
                _buildInfoTile(
                  title: 'Статус уведомлений',
                  subtitle: 'Проверить разрешения системы',
                  onTap: _checkNotificationStatus,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Кнопки управления
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// Построить секцию
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  /// Построить переключатель
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.black : Colors.grey[600],
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: enabled ? Colors.grey[600] : Colors.grey[500],
          ),
        ),
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Построить слайдер
  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: onChanged,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${value.round()} мин',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Построить информационную плитку
  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  /// Построить кнопки действий
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _testNotification,
            icon: const Icon(Icons.notifications),
            label: const Text('Тестовое уведомление'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _clearAllNotifications,
            icon: const Icon(Icons.clear_all),
            label: const Text('Очистить все уведомления'),
          ),
        ),
      ],
    );
  }

  /// Открыть системные настройки
  void _openSystemSettings() {
    _fcmService.openNotificationSettings();
  }

  /// Скопировать FCM токен
  void _copyFCMToken() {
    final token = _fcmService.fcmToken;
    if (token != null) {
      // TODO: Реализовать копирование в буфер обмена
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FCM токен скопирован в буфер обмена'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FCM токен не получен'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Проверить статус уведомлений
  Future<void> _checkNotificationStatus() async {
    final isEnabled = await _fcmService.areNotificationsEnabled();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Статус уведомлений'),
          content: Text(
            isEnabled 
                ? 'Уведомления включены в системе'
                : 'Уведомления отключены в системе',
          ),
          actions: [
            if (!isEnabled)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openSystemSettings();
                },
                child: const Text('Настройки'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Показать тестовое уведомление
  void _testNotification() {
    _fcmService.showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Тестовое уведомление',
      body: 'Это тестовое уведомление для проверки настроек',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Тестовое уведомление отправлено'),
      ),
    );
  }

  /// Очистить все уведомления
  void _clearAllNotifications() {
    _fcmService.cancelAllScheduledNotifications();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Все уведомления очищены'),
      ),
    );
  }
}
