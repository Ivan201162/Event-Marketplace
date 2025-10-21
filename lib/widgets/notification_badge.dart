import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key, required this.child, this.userId});
  final Widget child;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final currentUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return child;
    }

    return FutureBuilder<int>(
      future: NotificationService.getUnreadCount(currentUserId),
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        final int unreadCount = snapshot.data ?? 0;

        if (unreadCount == 0) {
          return child;
        }

        return Stack(
          children: [
            child,
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
