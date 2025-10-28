import 'package:event_marketplace_app/models/user_profile_enhanced.dart';
import 'package:flutter/material.dart';

/// Виджет списка активных сессий
class SessionsListWidget extends StatefulWidget {
  const SessionsListWidget({
    required this.sessions, super.key,
  });

  final List<UserSession> sessions;

  @override
  State<SessionsListWidget> createState() => _SessionsListWidgetState();
}

class _SessionsListWidgetState extends State<SessionsListWidget> {
  late List<UserSession> _sessions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sessions = List.from(widget.sessions);
  }

  /// Завершить сессию
  Future<void> _terminateSession(UserSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить сессию'),
        content: Text(
          'Вы уверены, что хотите завершить сессию на устройстве "${session.deviceName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() => _isLoading = true);

      try {
        // TODO: Реализовать завершение сессии
        await Future.delayed(const Duration(seconds: 1)); // Заглушка

        setState(() {
          _sessions.remove(session);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сессия завершена'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Завершить все сессии
  Future<void> _terminateAllSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить все сессии'),
        content: const Text(
          'Вы уверены, что хотите завершить все сессии? '
          'Вам потребуется войти заново на всех устройствах.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Завершить все'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() => _isLoading = true);

      try {
        // TODO: Реализовать завершение всех сессий
        await Future.delayed(const Duration(seconds: 1)); // Заглушка

        setState(() {
          _sessions.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Все сессии завершены'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Активные сессии'),
        actions: [
          if (_sessions.isNotEmpty)
            TextButton(
              onPressed: _isLoading ? null : _terminateAllSessions,
              child: const Text('Завершить все'),
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _sessions.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.devices_other,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Активных сессий нет',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Все устройства вышли из аккаунта',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            session.isActive ? Colors.green : Colors.grey,
                        child: Icon(
                          _getDeviceIcon(session.deviceType),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(session.deviceName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${session.deviceType} • ${session.location}'),
                          Text(
                            'Последняя активность: ${_formatDateTime(session.lastActive)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (session.isActive)
                            const Text(
                              'Текущая сессия',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: session.isActive
                          ? const Text(
                              'Активна',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : IconButton(
                              onPressed: () => _terminateSession(session),
                              icon: const Icon(Icons.logout, color: Colors.red),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
        return Icons.phone_android;
      case 'tablet':
        return Icons.tablet;
      case 'desktop':
        return Icons.desktop_windows;
      case 'web':
        return Icons.web;
      default:
        return Icons.device_unknown;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }
}
