import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'notification_badge.dart';
import 'propose_specialists_button.dart';

/// Пример интеграции кнопки предложения специалистов в чат
class ChatWithProposalButton extends StatelessWidget {
  const ChatWithProposalButton({
    super.key,
    required this.customerId,
    required this.eventId,
    this.message,
    required this.chatMessages,
  });
  final String customerId;
  final String eventId;
  final String? message;
  final Widget chatMessages;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Column(
      children: [
        // Кнопка предложения специалистов (только для организаторов)
        if (currentUser != null && _isOrganizer(currentUser.uid))
          ProposeSpecialistsButton(
            customerId: customerId,
            eventId: eventId,
            message: message,
          ),

        // Основной чат
        Expanded(
          child: chatMessages,
        ),
      ],
    );
  }

  /// Проверка, является ли пользователь организатором
  /// В реальном приложении это должно проверяться через сервис пользователей
  bool _isOrganizer(String userId) {
    // Здесь должна быть логика проверки роли пользователя
    // Например, через UserService или проверку в Firestore
    return true; // Временная заглушка
  }
}

/// Пример интеграции бейджа уведомлений в AppBar
class ChatAppBarWithNotifications extends StatelessWidget
    implements PreferredSizeWidget {
  const ChatAppBarWithNotifications({
    super.key,
    required this.title,
    this.userId,
  });
  final String title;
  final String? userId;

  @override
  Widget build(BuildContext context) => AppBar(
        title: Text(title),
        actions: [
          // Бейдж уведомлений
          NotificationBadge(
            userId: userId,
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
              icon: const Icon(Icons.notifications),
            ),
          ),

          // Кнопка предложений (только для организаторов)
          if (_isOrganizer(userId))
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/organizer-proposals');
              },
              icon: const Icon(Icons.people_alt),
              tooltip: 'Мои предложения',
            ),
        ],
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  bool _isOrganizer(String? userId) {
    // Здесь должна быть логика проверки роли пользователя
    return userId != null; // Временная заглушка
  }
}

/// Пример использования в экране чата
class ChatScreenExample extends StatelessWidget {
  const ChatScreenExample({
    super.key,
    required this.customerId,
    required this.eventId,
  });
  final String customerId;
  final String eventId;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: ChatAppBarWithNotifications(
          title: 'Чат с заказчиком',
          userId: FirebaseAuth.instance.currentUser?.uid,
        ),
        body: ChatWithProposalButton(
          customerId: customerId,
          eventId: eventId,
          chatMessages: _buildChatMessages(),
        ),
      );

  Widget _buildChatMessages() {
    // Здесь должен быть ваш существующий виджет чата
    return const Center(
      child: Text('Здесь будет ваш чат'),
    );
  }
}
