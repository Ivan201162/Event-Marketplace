import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/idea.dart';

/// Widget for displaying an idea card
class IdeaCard extends StatelessWidget {
  final Idea idea;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final bool showActions;

  const IdeaCard({
    super.key,
    required this.idea,
    this.onTap,
    this.onLike,
    this.onShare,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and difficulty
              _buildHeader(),
              const SizedBox(height: 12),

              // Title
              Text(
                idea.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                idea.shortDesc,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Media content
              if (idea.hasMedia) ...[_buildMediaContent(context), const SizedBox(height: 12)],

              // Tags
              if (idea.tags.isNotEmpty) ...[_buildTags(), const SizedBox(height: 12)],

              // Meta info
              _buildMetaInfo(),
              const SizedBox(height: 12),

              // Actions
              if (showActions) ...[_buildActions(context), const SizedBox(height: 8)],

              // Stats
              _buildStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Category icon
        if (idea.category != null) ...[
          Text(idea.categoryIcon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              idea.category!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ),
        ],
        const Spacer(),
        // Difficulty badge
        if (idea.difficulty != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getDifficultyColor(idea.difficulty!).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getDifficultyColor(idea.difficulty!).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              idea.difficultyText,
              style: TextStyle(
                color: _getDifficultyColor(idea.difficulty!),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: idea.mediaUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 150,
        placeholder: (context, url) => Container(
          height: 150,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 150,
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.error, color: Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: idea.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(color: Colors.orange[700], fontSize: 12, fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetaInfo() {
    return Row(
      children: [
        // Duration
        if (idea.estimatedDuration != null) ...[
          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(idea.formattedDuration, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(width: 16),
        ],
        // Author
        if (idea.authorName != null) ...[
          Icon(Icons.person, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(idea.authorName!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(width: 16),
        ],
        // Time ago
        Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(idea.timeAgo, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        _buildActionButton(
          icon: idea.likesCount > 0 ? Icons.favorite : Icons.favorite_border,
          color: idea.likesCount > 0 ? Colors.red : Colors.grey[600],
          label: idea.likesCount > 0 ? '${idea.likesCount}' : 'Лайк',
          onTap: onLike,
        ),
        const SizedBox(width: 24),
        _buildActionButton(
          icon: Icons.visibility,
          color: Colors.grey[600],
          label: idea.viewsCount > 0 ? '${idea.viewsCount}' : 'Просмотр',
        ),
        const SizedBox(width: 24),
        _buildActionButton(
          icon: Icons.share_outlined,
          color: Colors.grey[600],
          label: 'Поделиться',
          onTap: onShare,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color? color,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        if (idea.likesCount > 0) ...[
          Text(
            '${idea.likesCount} ${_getLikesText(idea.likesCount)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(width: 16),
        ],
        if (idea.viewsCount > 0) ...[
          Text(
            '${idea.viewsCount} ${_getViewsText(idea.viewsCount)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLikesText(int count) {
    if (count == 1) return 'лайк';
    if (count >= 2 && count <= 4) return 'лайка';
    return 'лайков';
  }

  String _getViewsText(int count) {
    if (count == 1) return 'просмотр';
    if (count >= 2 && count <= 4) return 'просмотра';
    return 'просмотров';
  }
}
