import 'package:flutter/material.dart';
import '../../models/user_profile_enhanced.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_overlay.dart';

/// Экран настроек уведомлений
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  final _userProfileService = UserProfileService();

  UserProfileEnhanced? _currentProfile;
  bool _isLoading = false;
  bool _isSaving = false;

  // Настройки уведомлений
  bool _likes = true;
  bool _comments = true;
  bool _follows = true;
  bool _messages = true;
  bool _requests = true;
  bool _recommendations = true;
  bool _system = true;
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _quietHoursEnabled = false;
  String? _quietHoursStart;
  String? _quietHoursEnd;
  bool _soundEnabled = true;

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
        setState(() {
          _currentProfile = profile;
          final settings = profile.notificationSettings;
          if (settings != null) {
            _likes = settings.likes;
            _comments = settings.comments;
            _follows = settings.follows;
            _messages = settings.messages;
            _requests = settings.requests;
            _recommendations = settings.recommendations;
            _system = settings.system;
            _pushEnabled = settings.pushEnabled;
            _emailEnabled = settings.emailEnabled;
            _quietHoursEnabled = settings.quietHoursEnabled;
            _quietHoursStart = settings.quietHoursStart;
            _quietHoursEnd = settings.quietHoursEnd;
            _soundEnabled = settings.soundEnabled;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки профиля: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Сохранить настройки
  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final userId = _currentProfile?.id;
      if (userId == null) {
        _showErrorSnackBar('Пользователь не авторизован');
        return;
      }

      final settings = NotificationSettings(
        likes: _likes,
        comments: _comments,
        follows: _follows,
        messages: _messages,
        requests: _requests,
        recommendations: _recommendations,
        system: _system,
        pushEnabled: _pushEnabled,
        emailEnabled: _emailEnabled,
        quietHoursEnabled: _quietHoursEnabled,
        quietHoursStart: _quietHoursStart,
        quietHoursEnd: _quietHoursEnd,
        soundEnabled: _soundEnabled,
      );

      await _userProfileService.updateNotificationSettings(userId, settings);
      
      _showSuccessSnackBar('Настройки уведомлений сохранены');
    } catch (e) {
      _showErrorSnackBar('Ошибка сохранения: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Настроить тихие часы
  Future<void> _configureQuietHours() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _QuietHoursDialog(
        currentStart: _quietHoursStart,
        currentEnd: _quietHoursEnd,
      ),
    );

    if (result != null) {
      setState(() {
        _quietHoursStart = result['start'];
        _quietHoursEnd = result['end'];
      });
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
      appBar: CustomAppBar(
        title: 'Уведомления',
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Сохранить'),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Общие настройки
            _buildGeneralSettingsSection(),
            const SizedBox(height: 16),

            // Типы уведомлений
            _buildNotificationTypesSection(),
            const SizedBox(height: 16),

            // Тихие часы
            _buildQuietHoursSection(),
            const SizedBox(height: 16),

            // Звуки
            _buildSoundSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Общие настройки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Push-уведомления'),
              subtitle: const Text('Получать уведомления на устройство'),
              value: _pushEnabled,
              onChanged: (value) {
                setState(() => _pushEnabled = value);
              },
            ),
            
            SwitchListTile(
              title: const Text('Email-уведомления'),
              subtitle: const Text('Получать уведомления по email'),
              value: _emailEnabled,
              onChanged: (value) {
                setState(() => _emailEnabled = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Типы уведомлений',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Лайки'),
              subtitle: const Text('Уведомления о лайках ваших постов'),
              value: _likes,
              onChanged: (value) {
                setState(() => _likes = value);
              },
            ),
            
            SwitchListTile(
              title: const Text('Комментарии'),
              subtitle: const Text('Уведомления о комментариях к вашим постам'),
              value: _comments,
              onChanged: (value) {
                setState(() => _comments = value);
              },
            ),
            
            SwitchListTile(
              title: const Text('Подписки'),
              subtitle: const Text('Уведомления о новых подписчиках'),
              value: _follows,
              onChanged: (value) {
                setState(() => _follows = value);
              },
            ),
            
            SwitchListTile(
              title: const Text('Сообщения'),
              subtitle: const Text('Уведомления о новых сообщениях'),
              value: _messages,
              onChanged: (value) {
                setState(() => _messages = value);
              },
            ),
            
            SwitchListTile(
              title: const Text('Заявки'),
              subtitle: const Text('Уведомления о новых заявках'),
              value: _requests,
              onChanged: (value) {
                setState(() => _requests = value);
              },
            ),
            
            SwitchListTile(
              title: const Text('Рекомендации'),
              subtitle: const Text('Уведомления о рекомендациях'),
              value: _recommendations,
              onChanged: (value) {
                setState(() => _recommendations = value);
              },
            ),
            
            SwitchListTile(
              title: const Text('Системные'),
              subtitle: const Text('Системные уведомления и обновления'),
              value: _system,
              onChanged: (value) {
                setState(() => _system = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursSection() {
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
                  'Тихие часы',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _quietHoursEnabled,
                  onChanged: (value) {
                    setState(() => _quietHoursEnabled = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Не получать уведомления в указанное время',
              style: TextStyle(color: Colors.grey),
            ),
            if (_quietHoursEnabled) ...[
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Настроить время'),
                subtitle: Text(
                  _quietHoursStart != null && _quietHoursEnd != null
                      ? 'С $_quietHoursStart до $_quietHoursEnd'
                      : 'Время не настроено',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _configureQuietHours,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Звуки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Звуки уведомлений'),
              subtitle: const Text('Воспроизводить звук при получении уведомлений'),
              value: _soundEnabled,
              onChanged: (value) {
                setState(() => _soundEnabled = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Диалог настройки тихих часов
class _QuietHoursDialog extends StatefulWidget {
  const _QuietHoursDialog({
    this.currentStart,
    this.currentEnd,
  });

  final String? currentStart;
  final String? currentEnd;

  @override
  State<_QuietHoursDialog> createState() => _QuietHoursDialogState();
}

class _QuietHoursDialogState extends State<_QuietHoursDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    
    // Парсим текущее время или устанавливаем значения по умолчанию
    _startTime = _parseTime(widget.currentStart) ?? const TimeOfDay(hour: 22, minute: 0);
    _endTime = _parseTime(widget.currentEnd) ?? const TimeOfDay(hour: 8, minute: 0);
  }

  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null) return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (time != null) {
      setState(() => _startTime = time);
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (time != null) {
      setState(() => _endTime = time);
    }
  }

  void _save() {
    Navigator.of(context).pop({
      'start': _formatTime(_startTime),
      'end': _formatTime(_endTime),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Тихие часы'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Начало'),
            subtitle: Text(_formatTime(_startTime)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _selectStartTime,
          ),
          ListTile(
            title: const Text('Конец'),
            subtitle: Text(_formatTime(_endTime)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _selectEndTime,
          ),
        ],
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
