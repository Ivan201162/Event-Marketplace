import 'package:flutter/material.dart';
import '../../models/user_profile_enhanced.dart';

/// Виджет истории входов
class LoginHistoryWidget extends StatelessWidget {
  const LoginHistoryWidget({
    super.key,
    required this.loginHistory,
  });

  final List<LoginHistory> loginHistory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История входов'),
      ),
      body: loginHistory.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'История входов пуста',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Здесь будет отображаться история ваших входов',
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
              itemCount: loginHistory.length,
              itemBuilder: (context, index) {
                final login = loginHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: login.success ? Colors.green : Colors.red,
                      child: Icon(
                        login.success ? Icons.check : Icons.close,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(login.deviceName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${login.location} • ${login.ipAddress}'),
                        Text(
                          _formatDateTime(login.timestamp),
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (!login.success && login.failureReason != null)
                          Text(
                            'Ошибка: ${login.failureReason}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: login.success
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.error, color: Colors.red),
                  ),
                );
              },
            ),
    );
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
