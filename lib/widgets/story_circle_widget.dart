import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/story.dart';

/// Виджет для отображения круга сторис
class StoryCircleWidget extends StatelessWidget {
  const StoryCircleWidget({super.key, required this.story, required this.onTap});

  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Colors.purple, Colors.orange, Colors.red]),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: story.thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: story.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) =>
                          Container(color: Colors.grey[300], child: const Icon(Icons.person)),
                    )
                  : Container(color: Colors.grey[300], child: const Icon(Icons.person)),
            ),
          ),
        ),
      );
}
