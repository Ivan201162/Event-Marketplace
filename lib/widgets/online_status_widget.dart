import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/presence_service.dart';

/// Виджет для отображения онлайн-статуса пользователя
class OnlineStatusWidget extends ConsumerWidget {
  final String userId;
  final double size;
  final bool showText;

  const OnlineStatusWidget({
    super.key,
    required this.userId,
    this.size = 12.0,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenceService = PresenceService();
    
    return StreamBuilder<Map<String, dynamic>?>(
      stream: presenceService.getUserPresence(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildOfflineStatus();
        }

        final presence = snapshot.data;
        final isOnline = presenceService.isUserOnline(presence);
        final lastSeen = presenceService.getLastSeen(presence);

        if (isOnline) {
          return _buildOnlineStatus();
        } else {
          return _buildOfflineStatus(lastSeen: lastSeen);
        }
      },
    );
  }

  Widget _buildOnlineStatus() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 4),
          const Text(
            'Онлайн',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOfflineStatus({DateTime? lastSeen}) {
    final presenceService = PresenceService();
    final lastSeenText = presenceService.formatLastSeen(lastSeen);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(
            lastSeenText,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

/// Виджет для отображения статуса в списке пользователей
class UserStatusListWidget extends ConsumerWidget {
  final List<String> userIds;
  final Widget Function(String userId, bool isOnline, String lastSeen) itemBuilder;

  const UserStatusListWidget({
    super.key,
    required this.userIds,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenceService = PresenceService();
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: presenceService.getMultipleUsersPresence(userIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final presences = snapshot.data!;
        final presenceMap = <String, Map<String, dynamic>>{};
        
        for (final presence in presences) {
          final userId = presence['userId'] as String;
          presenceMap[userId] = presence;
        }

        return Column(
          children: userIds.map((userId) {
            final presence = presenceMap[userId];
            final isOnline = presenceService.isUserOnline(presence);
            final lastSeen = presenceService.formatLastSeen(
              presenceService.getLastSeen(presence),
            );
            
            return itemBuilder(userId, isOnline, lastSeen);
          }).toList(),
        );
      },
    );
  }
}

/// Виджет для отображения статуса в чате
class ChatUserStatusWidget extends ConsumerWidget {
  final String userId;
  final String userName;

  const ChatUserStatusWidget({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnlineStatusWidget(
      userId: userId,
      size: 8.0,
      showText: true,
    );
  }
}
