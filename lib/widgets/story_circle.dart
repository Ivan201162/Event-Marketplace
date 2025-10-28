import 'package:event_marketplace_app/models/story.dart';
import 'package:flutter/material.dart';

/// Кружок Story с аватаром и индикатором просмотра
class StoryCircle extends StatelessWidget {

  const StoryCircle({
    required this.story, super.key,
    this.onTap,
  });
  final Story story;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: story.isViewed
              ? LinearGradient(
                  colors: [Colors.grey[400]!, Colors.grey[600]!],
                )
              : LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(2),
          child: CircleAvatar(
            backgroundImage: story.authorAvatar != null
                ? NetworkImage(story.authorAvatar!)
                : null,
            child: story.authorAvatar == null
                ? Icon(
                    Icons.person,
                    color: Theme.of(context).primaryColor,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
