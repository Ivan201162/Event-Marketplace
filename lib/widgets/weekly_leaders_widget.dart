import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/social_models.dart';

/// Виджет топ специалистов недели
class WeeklyLeadersWidget extends StatelessWidget {
  final List<WeeklyLeader> leaders;
  final Function(WeeklyLeader)? onLeaderTap;

  const WeeklyLeadersWidget(
      {super.key, required this.leaders, this.onLeaderTap});

  @override
  Widget build(BuildContext context) {
    if (leaders.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text('Пока нет данных', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: leaders.length,
        itemBuilder: (context, index) {
          final leader = leaders[index];
          final isTopThree = index < 3;

          return Container(
            width: 100,
            margin: EdgeInsets.only(right: index < leaders.length - 1 ? 12 : 0),
            child: _buildLeaderCard(context, leader, index + 1, isTopThree),
          );
        },
      ),
    );
  }

  Widget _buildLeaderCard(
    BuildContext context,
    WeeklyLeader leader,
    int position,
    bool isTopThree,
  ) {
    final theme = Theme.of(context);

    Color positionColor;
    IconData positionIcon;

    switch (position) {
      case 1:
        positionColor = Colors.amber;
        positionIcon = Icons.emoji_events;
        break;
      case 2:
        positionColor = Colors.grey[400]!;
        positionIcon = Icons.emoji_events;
        break;
      case 3:
        positionColor = Colors.orange[300]!;
        positionIcon = Icons.emoji_events;
        break;
      default:
        positionColor = Colors.grey[300]!;
        positionIcon = Icons.circle;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onLeaderTap?.call(leader),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isTopThree
                ? positionColor.withValues(alpha: 0.1)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTopThree
                  ? positionColor.withValues(alpha: 0.3)
                  : Colors.grey[300]!,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Позиция
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      color: positionColor, shape: BoxShape.circle),
                  child: Center(
                    child: position <= 3
                        ? Icon(positionIcon, size: 14, color: Colors.white)
                        : Text(
                            '$position',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 8),

                // Аватар
                Hero(
                  tag: 'leader_avatar_${leader.userId}',
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: leader.avatarUrl != null
                        ? CachedNetworkImageProvider(leader.avatarUrl!)
                        : null,
                    child: leader.avatarUrl == null
                        ? Icon(Icons.person,
                            size: 20, color: theme.primaryColor)
                        : null,
                  ),
                ),

                const SizedBox(height: 4),

                // Имя
                Text(
                  leader.name,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 2),

                // Город
                if (leader.city != null)
                  Text(
                    leader.city!,
                    style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 2),

                // Счет
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: positionColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${leader.score7d}',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: positionColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
